use strict;
use warnings;

use File::Temp;

for my $backend (@::backends) {
    note $backend->{name};

    my $drv = WebDriver::Tiny->new( %{ $backend->{args} } );

    my $png = $drv->screenshot;

    is substr( $png, 0, 8 ), "\211PNG\r\n\032\n", 'screenshot looks like a PNG';

    my $path = ( my $file = File::Temp->new )->filename;

    $drv->screenshot($path);

    local ( @ARGV, $/ ) = $path;

    is <>, $png, 'screenshot("file") matches screenshot';
}

done_testing;
