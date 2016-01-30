use lib 't';
use t   '1';

$drv->switch_page('foo');

reqs_are [ [ POST => '/window', { name => "foo" } ] ], '->switch_page("foo")';
