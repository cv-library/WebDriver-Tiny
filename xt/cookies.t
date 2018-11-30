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

is_deeply $drv->cookies, {}, 'No cookies';

my $expiry = time + 9;

$drv->cookie( foo => 'bar', expiry => $expiry );
$drv->cookie( baz => 'qux', expiry => $expiry, path => '/' );

my $cookie = {
    domain   => 'httpd',
    expiry   => $expiry,
    httpOnly => $JSON::PP::false,
    name     => 'foo',
    path     => '/',
    secure   => $JSON::PP::false,
    value    => 'bar',
};

is_deeply $drv->cookie('foo'), $cookie, 'Cookie "foo" exists';

is_deeply $drv->cookies, {
    foo => $cookie,
    baz => {
        domain   => 'httpd',
        expiry   => $expiry,
        httpOnly => $JSON::PP::false,
        name     => 'baz',
        path     => '/',
        secure   => $JSON::PP::false,
        value    => 'qux',
    },
}, 'Cookies exists';

$drv->cookie_delete('foo');

is_deeply [ keys %{ $drv->cookies } ], ['baz'], 'Only "baz" left';

$drv->cookie_delete;

is keys %{ $drv->cookies }, 0, 'No cookies left';

done_testing;
