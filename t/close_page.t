use lib 't';
use t   '1';

$drv->close_page;

reqs_are [ [ DELETE => '/window' ] ], '->close_page';
