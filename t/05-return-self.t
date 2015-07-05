use lib 't';
use t scalar(
    @::methods = qw/
        accept_alert
        back
        base_url
        close_page
        delete_cookie
        dismiss_alert
        forward
        get
        refresh
        switch_page
        window_maximize
    /
) + 2;

my $drv = WebDriver::Tiny->new;

is $drv->$_('foo'), $drv, "->$_ should return \$self" for @::methods;

is $drv->$_( 1, 1 ), $drv, "->$_ should return \$self"
    for qw/window_position window_size/;
