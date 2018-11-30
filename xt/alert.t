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

$drv->( 'alert', method => 'link_text' )->click;

is $drv->alert_text, 'hi', 'alert_text';

$drv->alert_dismiss;

done_testing;
