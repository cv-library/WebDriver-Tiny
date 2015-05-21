package WebDriver::Tiny;

use 5.010;
use strict;
use warnings;

# Allow "cute" $drv->('selector') syntax.
use overload
    fallback => 1, '&{}' => sub { my $self = $_[0]; sub { $self->find(@_) } };

use HTTP::Tiny;
use JSON::PP ();
use WebDriver::Tiny::Elements;

our @CARP_NOT = 'WebDriver::Tiny::Elements';
our $VERSION  = 0.001;

sub import {
    # Perl 5.14 or higher needed to create custom charnames.
    return if $] < 5.014;

    # From https://w3c.github.io/webdriver/webdriver-spec.html#sendkeys
    state $chars = {
        WD_NULL            => 57344, WD_CANCEL     => 57345,
        WD_HELP            => 57346, WD_BACK_SPACE => 57347,
        WD_TAB             => 57348, WD_CLEAR      => 57349,
        WD_RETURN          => 57350, WD_ENTER      => 57351,
        WD_SHIFT           => 57352, WD_CONTROL    => 57353,
        WD_ALT             => 57354, WD_PAUSE      => 57355,
        WD_ESCAPE          => 57356, WD_SPACE      => 57357,
        WD_PAGE_UP         => 57358, WD_PAGE_DOWN  => 57359,
        WD_END             => 57360, WD_HOME       => 57361,
        WD_ARROW_LEFT      => 57362, WD_ARROW_UP   => 57363,
        WD_ARROW_RIGHT     => 57364, WD_ARROW_DOWN => 57365,
        WD_INSERT          => 57366, WD_DELETE     => 57367,
        WD_SEMICOLON       => 57368, WD_EQUALS     => 57369,
        WD_NUMPAD0         => 57370, WD_NUMPAD1    => 57371,
        WD_NUMPAD2         => 57372, WD_NUMPAD3    => 57373,
        WD_NUMPAD4         => 57374, WD_NUMPAD5    => 57375,
        WD_NUMPAD6         => 57376, WD_NUMPAD7    => 57377,
        WD_NUMPAD8         => 57378, WD_NUMPAD9    => 57379,
        WD_MULTIPLY        => 57380, WD_ADD        => 57381,
        WD_SEPARATOR       => 57382, WD_SUBTRACT   => 57383,
        WD_DECIMAL         => 57384, WD_DIVIDE     => 57385,
        WD_F1              => 57393, WD_F2         => 57394,
        WD_F3              => 57395, WD_F4         => 57396,
        WD_F5              => 57397, WD_F6         => 57398,
        WD_F7              => 57399, WD_F8         => 57400,
        WD_F9              => 57401, WD_F10        => 57402,
        WD_F11             => 57403, WD_F12        => 57404,
        WD_META            => 57405, WD_COMMAND    => 57405,
        WD_ZENKAKU_HANKAKU => 57408,
    };

    require charnames;

    charnames->import( ':alias' => $chars );
}

sub new {
    my ( $class, %args ) = @_;

    $args{host} //= 'localhost';
    $args{port} //= 4444;

    my $self = bless [
        # FIXME Keep alive can make PhantomJS return a 400 bad request :-S.
        HTTP::Tiny->new( keep_alive => 0 ),
        "http://$args{host}:$args{port}/wd/hub/session",
        $args{base_url} // '',
    ], $class;

    my $reply = $self->_req(
        POST => '', { desiredCapabilities => { browserName => 'firefox' } } );

    $self->[1] .= '/' . $reply->{sessionId};

    # Store the capabilities.
    $self->[3] = $reply->{value};

    # Numify bool objects, saves memory.
    $_ += 0 for grep ref eq 'JSON::PP::Boolean', values %{ $self->[3] };

    $self;
}

sub capabilities { $_[0][3] }

sub page_ids { $_[0]->_req( GET  => '/window_handles' )->{value} }
sub source   { $_[0]->_req( GET  => '/source'         )->{value} }
sub title    { $_[0]->_req( GET  => '/title'          )->{value} }
sub url      { $_[0]->_req( GET  => '/url'            )->{value} }

sub back       { $_[0]->_req( POST   => '/back'    ); $_[0] }
sub close_page { $_[0]->_req( DELETE => '/window'  ); $_[0] }
sub forward    { $_[0]->_req( POST   => '/forward' ); $_[0] }
sub refresh    { $_[0]->_req( POST   => '/refresh' ); $_[0] }

sub accept_alert {
    $_[0]->_req( POST => '/accept_alert' ) if $_[0][3]{handlesAlerts};

    $_[0];
}

sub dismiss_alert {
    $_[0]->_req( POST => '/dismiss_alert' ) if $_[0][3]{handlesAlerts};

    $_[0];
}

sub base_url {
    my ( $self, $url ) = @_;

    $self->[2] = $url // '' if @_ == 2;

    $self->[2];
}

sub cookies {
    +{
        map { $_->{name} => $_ }
        @{ $_[0]->_req( GET => '/cookie' )->{value} // [] }
    };
}

# NOTE This method can be called from a driver or a collection of elements.
sub find {
    my ( $self, $selector, %args ) = @_;

    state $methods = {
        css               => 'css selector',
        ecmascript        => 'ecmascript',
        link_text         => 'link text',
        partial_link_text => 'partial link text',
        xpath             => 'xpath',
    };

    my $method = $methods->{ $args{method} // '' } // 'css selector';

    my $must_be_visible
        = $method eq 'css selector' && $selector =~ s/:visible$//;

    my @ids;

    for ( 0 .. ( $args{tries} // 5 ) ) {
        my $reply = $self->_req(
            POST => '/elements',
            { using => $method, value => $selector },
        );

        @ids = map $_->{ELEMENT}, @{ $reply->{value} };

        # FIXME This'll break when called on elems->find(), this always need
        # to be $drv NOT $self.
        @ids = grep {
            $self->_req( GET => "/element/$_/displayed" )->{value}
        } @ids if $must_be_visible;

        last if @ids;

        select undef, undef, undef, $args{sleep} // .1;
    }

    if ( !@ids && !exists $args{dies} && !$args{dies} ) {
        require Carp;

        Carp::croak ref $self, qq/->find failed for $method = "$_[1]"/;
    }

    # FIXME
    $self = $self->[0] if ref $self eq 'WebDriver::Tiny::Elements';

    wantarray ? map { bless [ $self, $_ ], 'WebDriver::Tiny::Elements' } @ids
              : bless [ $self, @ids ], 'WebDriver::Tiny::Elements';
}

sub delete_cookie {
    my $self = shift;

    $self->_req( DELETE => '/cookie' . ( @_ ? '/' . shift // '' : '' ) );

    $self;
}

sub execute {
    my ( $self, $script, @args ) = @_;

    # Currently only takes the first ID in the collection, this should change.
    $_ = { ELEMENT => $_->[1] }
        for grep ref eq 'WebDriver::Tiny::Elements', @args;

    $self->_req( POST => '/execute', { script => $script, args => \@args } )
        ->{value};
}

sub execute_phantom {
    my ( $self, $script, @args ) = @_;

    $self->_req( POST => '/phantom/execute', { script => $script, args => \@args } )
        ->{value};
}

sub get {
    my ( $self, $url ) = @_;

    $self->_req(
        POST => '/url',
        { url => $url =~ m(^https?://) ? $url : $self->[2] . $url },
    );

    $self;
}

# TODO make this handle elements too? Or make a new method?
sub screenshot {
    my ( $self, $file ) = @_;

    require MIME::Base64;

    my $data = MIME::Base64::decode_base64(
        $self->_req( GET => '/screenshot' )->{value}
    );

    if ( @_ == 2 ) {
        open my $fh, '>', $file or die $!;
        print $fh $data;
        close $fh or die $!;

        return $self;
    }

    $data;
}

sub switch_page {
    my ( $self, $id ) = @_;

    $self->_req( POST => '/window', { name => $id } );

    $self;
}

sub user_agent { $_[0]->execute('return window.navigator.userAgent') }

sub window_maximize {
    $_[0]->_req( POST => '/window/' . ( $_[1] // 'current' ) . '/maximize' );
}

sub window_size {
    my ( $self, $w, $h ) = @_;

    if ( @_ == 3 ) {
        $self->_req(
            POST => '/window/current/size', { width => $w, height => $h } );

        return $self;
    }

    @{ $self->_req( GET => '/window/current/size' )->{value} }{qw/width height/};
}

sub _req {
    my ( $self, $method, $path, $args ) = @_;

    # For speed, go straight to HTTP::Tiny's private _request method.
    my $reply = $self->[0]->_request(
        $method,
        $self->[1] . $path,
        $args ? { content => JSON::PP::encode_json $args } : {},
    );

    unless ( $reply->{success} ) {
        # Try to extract an error message from the reply. Yep nested JSON :-(
        my $error = eval {
            # FIXME We probably just want to tell JSON::PP not to decode.
            utf8::encode my $msg
                = JSON::PP::decode_json($reply->{content})->{value}{message};

            JSON::PP::decode_json($msg)->{errorMessage}
        };

        require Carp;

        Carp::croak ref $self, ' - ', $error // $reply->{content};
    }

    JSON::PP::decode_json $reply->{content};
}

sub DESTROY { $_[0]->_req( DELETE => '' ) }

1;
