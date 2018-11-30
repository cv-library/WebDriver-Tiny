use strict;
use utf8;
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

my $ghost = $drv->('body')->find('#ghost');

is $ghost->attr('id'), 'ghost', '$ghost->attr("id")';
is $ghost->css('display'), 'none', '$ghost->css("display")';
is $ghost->tag, 'h2', '$ghost->tag';
is $ghost->text, '', '$ghost->text';
ok !$ghost->visible, '$ghost->visible';

$drv->js( 'arguments[0].style.display = "block"', $ghost );

ok $ghost->visible, '$ghost is now visible';
is $ghost->text, '👻', '$ghost now has text';

done_testing;
