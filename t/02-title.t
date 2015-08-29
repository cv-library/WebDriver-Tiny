use lib 't';
use t   '2';

my $drv = WebDriver::Tiny->new( port => 1 );

$content = '{"value":"foo"}';

is $drv->title, 'foo';

args_are [ GET => 'http://localhost:1/session/:sid/title' ];
