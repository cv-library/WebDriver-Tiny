use strict;
use warnings;

for my $backend (@::backends) {
    note $backend->{name};

    my $drv = WebDriver::Tiny->new( %{ $backend->{args} } );

    $drv->get($::url);

    is_deeply $drv->cookies, {}, 'No cookies';

    $drv->cookie( foo => 'bar' );
    $drv->cookie( baz => 'qux', httponly => 1, path => Cwd::fastcwd );

    my $cookie = {
        domain   => '',
        httponly => bool(0),
        name     => 'foo',
        path     => Cwd::fastcwd . '/xt/',
        secure   => bool(0),
        value    => 'bar',
    };

    # FIXME Cookies & ChromeDriver doesn't work :-(
    next if $backend->{name} eq 'ChromeDriver';

    cmp_deeply $drv->cookie('foo'), $cookie, 'Cookie "foo" exists';

    cmp_deeply $drv->cookies, {
        foo => $cookie,
        baz => {
            domain   => '',
            httponly => bool(1),
            name     => 'baz',
            path     => Cwd::fastcwd,
            secure   => bool(0),
            value    => 'qux',
        },
    }, 'Cookies exists';

    $drv->cookie_delete('foo');

    is_deeply [ keys %{ $drv->cookies } ], ['baz'], 'Only "baz" left';

    $drv->cookie_delete;

    is keys %{ $drv->cookies }, 0, 'No cookies left';
}

done_testing;
