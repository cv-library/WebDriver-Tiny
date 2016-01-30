use lib 't';
use t   '1';

$drv->screenshot;

reqs_are [ [ GET => '/screenshot' ] ], '->screenshot';
