use strict;
use warnings;

use JSON::PP ();
use Test::Deep;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => JSON::PP::decode_json($ENV{WEBDRIVER_CAPABILITIES} || '{}'),
    host         => $ENV{WEBDRIVER_HOST},
    port         => 4444,
);

cmp_deeply $drv->status,
    { message => 'Session already started', ready => bool(0) }, 'status';

done_testing;
