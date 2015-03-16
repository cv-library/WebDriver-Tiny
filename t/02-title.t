use lib 't';
use t   '2';

my $drv = WebDriver::Tiny->new;

$content = '{"value":"foo"}';

is $drv->title, 'foo';

args_are [ GET => 'http://localhost:4444/session/:sid/title', {} ];
