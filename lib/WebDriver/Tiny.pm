package WebDriver::Tiny 0.001;

use strict;
use warnings;

# Allow "cute" $drv->('selector') syntax.
use overload
    fallback => 1, '&{}' => sub { my $self = $_[0]; sub { $self->find(@_) } };

use HTTP::Tiny;
use JSON::PP ();
use Time::HiRes;
use WebDriver::Tiny::Elements;

# From https://w3c.github.io/webdriver/webdriver-spec.html#sendkeys
my %chars;
@chars{ qw/
    WD_NULL         WD_CANCEL      WD_HELP     WD_BACK_SPACE  WD_TAB
    WD_CLEAR        WD_RETURN      WD_ENTER    WD_SHIFT       WD_CONTROL
    WD_ALT          WD_PAUSE       WD_ESCAPE   WD_SPACE       WD_PAGE_UP
    WD_PAGE_DOWN    WD_END         WD_HOME     WD_ARROW_LEFT  WD_ARROW_UP
    WD_ARROW_RIGHT  WD_ARROW_DOWN  WD_INSERT   WD_DELETE      WD_SEMICOLON
    WD_EQUALS       WD_NUMPAD0     WD_NUMPAD1  WD_NUMPAD2     WD_NUMPAD3
    WD_NUMPAD4      WD_NUMPAD5     WD_NUMPAD6  WD_NUMPAD7     WD_NUMPAD8
    WD_NUMPAD9      WD_MULTIPLY    WD_ADD      WD_SEPARATOR   WD_SUBTRACT
    WD_DECIMAL      WD_DIVIDE      WD_F1       WD_F2          WD_F3
    WD_F4           WD_F5          WD_F6       WD_F7          WD_F8
    WD_F9           WD_F10         WD_F11      WD_F12         WD_META
    WD_COMMAND      WD_ZENKAKU_HANKAKU
/ } = ( 0xE000 .. 0xE029, 0xE031 .. 0xE03D, 0xE03D, 0xE040 );

require charnames;

sub import { charnames->import( ':alias' => \%chars ) }

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

    $self->[1] .= '/' . $self->_req(
        POST => '',
        { desiredCapabilities => { browserName => 'firefox' } },
    )->{sessionId};

    $self;
}

sub title { $_[0]->_req( GET => '/title' )->{value} }
sub url   { $_[0]->_req( GET => '/url'   )->{value} }

sub base_url {
    my ( $self, $url ) = @_;

    $self->[2] = $url // '' if @_ == 2;

    $self->[2];
}

my %methods = (
    css               => 'css selector',
    ecmascript        => 'ecmascript',
    link_text         => 'link text',
    partial_link_text => 'partial link text',
    xpath             => 'xpath',
);

# NOTE This method can be called from a driver or a collection of elements.
sub find {
    my ( $self, $selector, %args ) = @_;

    my $method = $methods{ $args{method} // '' } // 'css selector';

    my $must_be_visible
        = $method eq 'css selector' && $selector =~ s/:visible$//;

    my @ids;

    for ( 0 .. ( $args{tries} // 5 ) ) {
        my $reply = $self->_req(
            POST => '/elements',
            { using => $method, value => $selector },
        );

        @ids = map $_->{ELEMENT}, @{ $reply->{value} };

        @ids = grep {
            $self->_req( GET => "/element/$_/displayed" )->{value}
        } @ids if $must_be_visible;

        last if @ids;

        Time::HiRes::sleep( $args{sleep} // 0.1 );
    }

    if ( !@ids && !exists $args{dies} && !$args{dies} ) {
        require Carp;

        Carp::croak ref $self, ' - Elements not found'
    }

    # FIXME
    $self = $self->[0] if ref $self eq 'WebDriver::Tiny::Elements';

    wantarray ? map { bless [ $self, $_ ], 'WebDriver::Tiny::Elements' } @ids
              : bless [ $self, @ids ], 'WebDriver::Tiny::Elements';
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

sub window_size {
    my ( $self, $width, $height ) = @_;

    if ( @_ == 3 ) {
        $self->_req(
            POST => '/window/current/size',
            { width => $width, height => $height },
        );

        return $self;
    }

    $self->_req( GET => '/window/current/size' )->{value};
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
        require Carp;

        Carp::croak ref $self, " - $reply->{content}";
    }

    JSON::PP::decode_json $reply->{content};
}

sub DESTROY { $_[0]->_req( DELETE => '' ) }

1;
