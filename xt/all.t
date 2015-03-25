# Fork & spawn PhantomJS as soon as possible, the reason for this is twofold:
#   - Gives PhantomJS longer to start before we need it.
#   - Fork early when the memory consumption is at it's lowest.
BEGIN {
    exec qw/
        phantomjs
        --webdriver=1337
        --webdriver-loglevel=ERROR
        / unless my $pid = fork;

    END { kill 15, $pid }
}

use strict;
use utf8;
use warnings;

use Cwd ();
use Test::Deep;
use Test::More tests => 5;
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

is $drv->title, 'Frosty the ☃', 'title';

is $drv->url, $url, 'url';

chomp( my $ver = `phantomjs -v` );

like $drv->user_agent, qr( PhantomJS/\Q$ver\E ), 'user_agent';
