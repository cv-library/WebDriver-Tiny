use strict;
use warnings;

use File::Temp;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

$drv->get('http://httpd');

my $pdf = $drv->print;

is substr( $pdf, 0, 5 ), '%PDF-', 'output looks like a PDF';

my $file = File::Temp->new;

$drv->print( $file->filename );

local ( @ARGV, $/ ) = $file->filename;

is <>, $pdf, 'print("file") matches PDF';

done_testing;
