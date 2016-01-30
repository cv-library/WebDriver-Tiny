use lib 't';
use t   '1';

$drv->page_ids;

reqs_are [ [ GET => '/window_handles' ] ], '->page_ids';
