use lib 't';
use t   '2';

my $drv = WebDriver::Tiny->new;

args_are [
    POST => 'http://localhost:4444/wd/hub/session',
    { content => '{"desiredCapabilities":{"browserName":"firefox"}}' },
], 'Session is created at construction time';

undef $drv;

args_are [ DELETE => 'http://localhost:4444/wd/hub/session/:sid', {} ],
    'Session is removed at destruction time';
