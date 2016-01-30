use lib 't';
use t scalar(
    @::methods = qw/
        accept_alert
        back
        base_url
        close_page
        cookie_delete
        dismiss_alert
        forward
        get
        refresh
        switch_page
        window_maximize
    /
) + 3;

is $drv->$_('foo'), $drv, "->$_ should return \$self" for @::methods;

is $drv->$_( 1, 1 ), $drv, "->$_ should return \$self"
    for qw/cookie window_position window_size/;
