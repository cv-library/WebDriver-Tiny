use strict;
use warnings;

use Test::More tests => 2;
use WebDriver::Tiny;

my %got = %WebDriver::Tiny::;

# Delete stuff that varies by perl version.
delete @got{ qw/(( OVERLOAD/ };

is_deeply [ sort keys %got ], [ qw/
    (&{}
    ()
    BEGIN
    CARP_NOT
    DESTROY
    Elements::
    VERSION
    __ANON__
    _req
    accept_alert
    back
    base_url
    capabilities
    close_page
    cookie
    cookie_delete
    cookies
    dismiss_alert
    execute
    execute_phantom
    find
    forward
    get
    import
    new
    page_ids
    refresh
    screenshot
    source
    switch_page
    title
    url
    user_agent
    window_maximize
    window_position
    window_size
/ ], "WebDriver::Tiny has the correct stuff in it's namespace";

%got = %WebDriver::Tiny::Elements::;

# Delete stuff that varies by perl version.
delete @got{ qw/CARP_NOT ISA/ };

is_deeply [ sort keys %got ], [ qw/
    BEGIN
    VERSION
    _req
    attr
    clear
    click
    css
    enabled
    find
    first
    import
    last
    move_to
    rect
    screenshot
    selected
    send_keys
    size
    slice
    submit
    tag
    tap
    text
    visible
/ ], "WebDriver::Tiny::Elements has the correct stuff in it's namespace";
