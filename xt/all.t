# Fork & spawn PhantomJS as soon as possible, the reason for this is twofold:
#   - Gives PhantomJS longer to start before we need it.
#   - Fork early when the memory consumption is at its lowest.
BEGIN {
    my $pid;

    unless ( $pid = fork ) {
        close STDOUT;

        exec qw/
            phantomjs
            --webdriver=1337
            --webdriver-loglevel=ERROR
            /;
    }

    END { kill 15, $pid }
}

use strict;
use utf8;
use warnings;

use Cwd ();
use File::Temp;
use Test::Deep;
use Test::Fatal;
use Test::More tests => 35;
use URI;
use URI::QueryParam;
use WebDriver::Tiny;

my ( $drv, $i );

# PhantomJS might not be up yet, try it a few times.
{
    local $SIG{__WARN__} = sub {};

    until ( $drv = eval { WebDriver::Tiny->new( port => 1337 ) } ) {
        die $@ if ++$i == 10;

        select undef, undef, undef, .1; # Sleep for a tenth of a second.
    }
}

$drv->get( my $url = 'file://' . Cwd::fastcwd . '/xt/test.html' );

note 'Basic';
#############

cmp_deeply $drv->capabilities, {
    acceptSslCerts           => 0,
    applicationCacheEnabled  => 0,
    browserConnectionEnabled => 0,
    browserName              => 'phantomjs',
    cssSelectorsEnabled      => 1,
    databaseEnabled          => 0,
    driverName               => 'ghostdriver',
    driverVersion            => re(qr/^[\d.]+$/),
    handlesAlerts            => 0,
    javascriptEnabled        => 1,
    locationContextEnabled   => 0,
    nativeEvents             => 1,
    platform                 => re('linux'),
    proxy                    => { proxyType => 'direct' },
    rotatable                => 0,
    takesScreenshot          => 1,
    version                  => re(qr/^[\d.]+$/),
    webStorageEnabled        => 0,
}, 'capabilities';

cmp_deeply $drv->page_ids,
    [ re qr/^[\da-f]{8}-(?:[\da-f]{4}-){3}[\da-f]{12}$/ ], 'page_ids';

{
    open my $fh, '<:encoding(UTF-8)', 'xt/test.html';

    local $/;

    is $drv->source =~ s/\s//gr, <$fh> =~ s/\s//gr, 'source';
}

is $drv->('h1')->text, 'ᴛ̲ʜ̲ᴇ̲ʀ̲ᴇ̲ ̲ɪ̲s̲ ̲ɴ̲ᴏ̲ ̲U̲ɴ̲ɪ̲ᴄ̲ᴏ̲ᴅ̲ᴇ̲ ̲ᴍ̲ᴀ̲ɢ̲ɪ̲ᴄ̲ ̲ʙ̲ᴜ̲ʟ̲ʟ̲ᴇ̲ᴛ̲', 'text';

is $drv->title, 'Frosty the ☃', 'title';

is $drv->url, $url, 'url';

chomp( my $ver = `phantomjs -v` );

like $drv->user_agent, qr( PhantomJS/\Q$ver\E ), 'user_agent';

note 'Cookies';
###############

is_deeply $drv->cookies, {}, 'No cookies';

$drv->cookie( foo => 'bar' );
$drv->cookie( baz => 'qux', httponly => 1, path => Cwd::fastcwd );

my $cookie = {
    domain   => '',
    httponly => bool(0),
    name     => 'foo',
    path     => Cwd::fastcwd . '/xt/',
    secure   => bool(0),
    value    => 'bar',
};

cmp_deeply $drv->cookie('foo'), $cookie, 'Cookie "foo" exists';

cmp_deeply $drv->cookies, {
    foo => $cookie,
    baz => {
        domain   => '',
        httponly => bool(1),
        name     => 'baz',
        path     => Cwd::fastcwd,
        secure   => bool(0),
        value    => 'qux',
    },
}, 'Cookies exists';

$drv->cookie_delete('foo');

is_deeply [ keys %{ $drv->cookies } ], ['baz'], 'Only "baz" left';

$drv->cookie_delete;

is keys %{ $drv->cookies }, 0, 'No cookies left';

note 'Ghost';
#############

my $ghost = $drv->('body')->find('#ghost');

is $ghost->attr('id'), 'ghost', '$ghost->attr("id")';
is $ghost->css('display'), 'none', '$ghost->css("display")';
is $ghost->tag, 'h2', '$ghost->tag';
is $ghost->text, '', '$ghost->text';
ok !$ghost->visible, '$ghost->visible';

$drv->execute( 'arguments[0].style.display = "block"', $ghost );

ok $ghost->visible, '$ghost is now visible';
is $ghost->text, '👻', '$ghost now has text';

note 'Form';
############

is_deeply [ map $_->attr('name'), $drv->('input,select') ], [
    'text', "text '", 'text "', 'text \\', 'text ☃',
    ('radio') x 3, 'select', 'multi select',
], 'names of all form fields are correct';

# Perl 6 envy :-(
sub pick { map { splice @_, rand @_, 1 } 1 .. shift }
sub roll { map { $_[ rand @_ ]         } 1 .. shift }

$drv->('form')->submit( my %values = (
    'text'         => join( '', roll 3, 'a'..'z' ),
    "text '"       => join( '', roll 3, 'a'..'z' ),
    'text "'       => join( '', roll 3, 'a'..'z' ),
    'text \\'      => join( '', roll 3, 'a'..'z' ),
    'text ☃'      => join( '', roll 3, 'a'..'z' ),
    'radio'        => roll( 1, 'a'..'c' ),
    'select'       => roll( 1, 'a'..'c' ),
    'multi select' => [ pick( 2, 'a'..'c' ) ],
) );

my %expected;

while ( my ( $k, $v ) = each %values ) {
    utf8::encode $k;

    $expected{$k} = ref $v ? bag @$v : $v;
}

cmp_deeply +URI->new( $drv->url )->query_form_hash, \%expected,
    'submit works on all form fields correctly';

my $elem = $drv->('input[type=text]');

$elem->send_keys('Perl 🐪');

is $elem->attr('value'), 'Perl 🐪', 'elem->send_keys';

$elem->clear;

is $elem->attr('value'), '', 'elem->clear';

note 'JS';
##########

is $drv->execute('return "foo"'), 'foo', q/execute('return "foo"')/;

note 'Screenshot';
##################

my $png = $drv->screenshot;

is substr( $png, 0, 8 ), "\211PNG\r\n\032\n", 'screenshot looks like a PNG';

{
    my $path = ( my $file = File::Temp->new )->filename;

    $drv->screenshot($path);

    local ( @ARGV, $/ ) = $path;

    is <>, $png, 'screenshot("file") matches screenshot';
}

note 'Window Management';
#########################

my $ret = $drv->window_size( 640, 480 );

is_deeply $ret, $drv, 'window_size returns $self';

is_deeply $drv->execute('return [ window.innerWidth, window.innerHeight ]'),
    [ 640, 480 ], 'window_size( 640, 480 )';

is_deeply [ $drv->window_size ], [ 640, 480 ], 'window_size';

$drv->window_size( 800, 600 );

is_deeply $drv->execute('return [ window.innerWidth, window.innerHeight ]'),
    [ 800, 600 ], 'window_size( 800, 600 )';

is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

$drv->window_maximize;

is_deeply [ $drv->window_size ], [ 1366, 768 ], 'window_maximize';

$drv->window_size( current => 800, 600 );

is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

$drv->window_maximize('current');

is_deeply [ $drv->window_size ], [ 1366, 768 ], 'window_maximize("current")';

like exception { $drv->window_maximize('foo') },
    qr(\QWindow handle/name 'foo' is invalid (closed?)), 'window_maximize("foo")';
