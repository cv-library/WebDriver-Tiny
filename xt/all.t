# Fork & spawn phantomjs as soon as possible, the reason for this is twofold:
#   - Gives phantomjs longer to start before we need it.
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
use Test::More tests => 4;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new( port => 1337 );

$drv->get( my $url = 'file://' . Cwd::fastcwd . '/xt/test.html' );

cmp_deeply $drv->page_ids,
    [ re qr/^[\da-f]{8}-(?:[\da-f]{4}-){3}[\da-f]{12}$/ ], 'page_ids';

is $drv->title, 'Frosty the ☃', 'title';

is $drv->url, $url, 'url';

chomp( my $ver = `phantomjs -v` );

like $drv->user_agent, qr( PhantomJS/\Q$ver\E ), 'user_agent';
