use lib 't';
use t   '2';

$content = '{"value":""}';

$drv->print;

reqs_are [ [ POST => '/print' ] ], '$drv->print';
