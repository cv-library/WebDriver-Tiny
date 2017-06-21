use lib 't';
use t scalar(
    @::methods = qw/
        alert_accept
        alert_dismiss
        back
        base_url
        cookie_delete
        forward
        get
        refresh
        window_close
        window_maximize
        window_switch
    /
) + 2;

is $drv->$_('foo'), $drv, "->$_ should return \$self" for @::methods;

is $drv->$_( 1, 1 ), $drv, "->$_ should return \$self"
    for qw/cookie window_rect/;
