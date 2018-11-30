use strict;
use warnings;

use JSON::PP ();
use File::Temp;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => JSON::PP::decode_json($ENV{WEBDRIVER_CAPABILITIES} || '{}'),
    host         => $ENV{WEBDRIVER_HOST},
    port         => 4444,
);

$drv->get('http://httpd:8080');

my $png = $drv->screenshot;

is substr( $png, 0, 8 ), "\211PNG\r\n\032\n", 'screenshot looks like a PNG';

my $file = File::Temp->new;

$drv->screenshot( $file->filename );

local ( @ARGV, $/ ) = $file->filename;

is <>, $png, 'screenshot("file") matches screenshot';

my $elem = $drv->('form');

$png = $elem->screenshot;

is substr( $png, 0, 8 ), "\211PNG\r\n\032\n",
    'screenshot of element looks like a PNG';

$file = File::Temp->new;

$elem->screenshot( $file->filename );

local ( @ARGV, $/ ) = $file->filename;

is <>, $png, 'element screenshot("file") matches screenshot';

done_testing;
