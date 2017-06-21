use strict;
use warnings;

use Test::Deep;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new( host => 'geckodriver', port => 4444 );

$drv->get('http://httpd:8080');

my $int = re qr/^\d+$/;
my $js  = <<'JS';
    return [
        window.outerWidth  || window.innerWidth,
        window.outerHeight || window.innerHeight,
    ];
JS

$drv->window_rect( 640, 480 );

is_deeply $drv->js($js), [ 640, 480 ], 'window_size( 640, 480 )';

is_deeply $drv->window_rect, { qw/width 640 height 480 x 0 y 0/ },
    'window_rect';

$drv->window_rect( 800, 600, 10, 20 );

is_deeply $drv->js($js), [ 800, 600 ], 'window_size( 800, 600 )';

is_deeply $drv->window_rect, { qw/width 800 height 600 x 10 y 20/ },
    'window_rect';

$drv->window_maximize;

#cmp_deeply [ $drv->window_size ], [ $int, $int ], 'window_maximize';

#$drv->window_size( current => 800, 600 );

#is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

#$drv->window_maximize('current');

#cmp_deeply [ $drv->window_size ], [ $int, $int ],
#    'window_maximize("current")';

done_testing;
