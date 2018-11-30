use strict;
use warnings;

use JSON::PP ();
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => JSON::PP::decode_json($ENV{WEBDRIVER_CAPABILITIES} || '{}'),
    host         => $ENV{WEBDRIVER_HOST},
    port         => 4444,
);

$drv->get('http://httpd:8080');

is $drv->js('return "foo"'), 'foo', q/js('return "foo"')/;

is $drv->js_async('arguments[0]("bar")'), 'bar',
    q/js_async('arguments[0]("bar")')/;

done_testing;
