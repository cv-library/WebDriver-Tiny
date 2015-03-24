use strict;
use utf8;
use warnings;

use Cwd;
use Test::Deep;
use Time::HiRes 'sleep';
use Test::More;
use WebDriver::Tiny;

exec qw/
    phantomjs
    --webdriver=1337
    --webdriver-loglevel=ERROR
    / unless my $pid = fork;

END { kill 15, $pid if $pid }

sleep .5;    # Give phantomjs a chance to start.

my $drv = WebDriver::Tiny->new( port => 1337 );

$drv->get( my $url = 'file://' . getcwd . '/xt/test.html' );

cmp_deeply $drv->page_ids,
    [ re qr/^[\da-f]{8}-(?:[\da-f]{4}-){3}[\da-f]{12}$/ ], 'page_ids';

is $drv->title, 'Frosty the ☃', 'title';

is $drv->url, $url, 'url';

chomp( my $ver = `phantomjs -v` );

like $drv->user_agent, qr( PhantomJS/\Q$ver\E ), 'user_agent';

done_testing;
