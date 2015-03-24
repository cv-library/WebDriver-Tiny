use strict;
use utf8;
use warnings;

use Cwd;
use Test::More;
use WebDriver::Tiny;

exec qw/
    phantomjs
    --webdriver=1337
    --webdriver-loglevel=ERROR
    / unless my $pid = fork;

END { kill 15, $pid if $pid }

sleep 1;    # Give phantomjs a chance to start.

my $drv = WebDriver::Tiny->new( port => 1337 );

$drv->get( my $url = 'file://' . getcwd . '/xt/test.html' );

is $drv->title, 'Frosty the ☃', 'title';

is $drv->url, $url, 'url';

done_testing;
