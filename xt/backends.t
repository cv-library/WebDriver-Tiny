use strict;
use warnings;

use Test::More;
use WebDriver::Tiny;

my @pids;

END { kill 15, $_ for @pids }

exec '~/Downloads/chromedriver' unless $_ = fork;
push @pids, $_;

exec qw/phantomjs -w/ unless $_ = fork;
push @pids, $_;

exec 'java -jar ~/Downloads/selenium-server-standalone-*.jar' unless $_ = fork;
push @pids, $_;

sleep 1;

like +WebDriver::Tiny->new(
     capabilities => {
         chromeOptions => { binary => '/usr/bin/google-chrome-unstable' },
     },
     port => 9515,
 )->user_agent, qr/Chrome/;


like +WebDriver::Tiny->new( port => 8910 )->user_agent, qr/PhantomJS/;

#like +WebDriver::Tiny->new(
#    capabilities => { browserName => 'firefox' },
#    path         => '/wd/hub',
#    port         => 4444,
#)->user_agent, qw/Firefox/;

done_testing;
