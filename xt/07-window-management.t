use strict;
use warnings;

my $js = <<'JS';
    return [
        window.outerWidth  || window.innerWidth,
        window.outerHeight || window.innerHeight,
    ];
JS

for my $backend (@::backends) {
    note $backend->{name};

    my $drv = WebDriver::Tiny->new( %{ $backend->{args} } );
 
    $drv->window_size( 640, 480 );

    is_deeply $drv->js($js), [ 640, 480 ], 'window_size( 640, 480 )';

    is_deeply [ $drv->window_size ], [ 640, 480 ], 'window_size';

    $drv->window_size( 800, 600 );

    is_deeply $drv->js($js), [ 800, 600 ], 'window_size( 800, 600 )';

    is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

    $drv->window_maximize;

    is_deeply [ $drv->window_size ], $backend->{maximized}, 'window_maximize';

    $drv->window_size( current => 800, 600 );

    is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

    $drv->window_maximize('current');

    is_deeply [ $drv->window_size ], $backend->{maximized},
        'window_maximize("current")';

    # FIXME ChromeDriver doesn't choke on unknown windows :-(
    next if $backend->{name} eq 'ChromeDriver';

    eval { $drv->window_maximize('foo') };

    like $@, qr(\QWindow handle/name 'foo' is invalid (closed?)),
        'window_maximize("foo")';
}

done_testing;
