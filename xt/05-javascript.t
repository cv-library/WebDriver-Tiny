use strict;
use warnings;

for my $backend (@::backends) {
    note $backend->{name};

    my $drv = WebDriver::Tiny->new( %{ $backend->{args} } );

    is $drv->js('return "foo"'), 'foo', q/js('return "foo"')/;

    is $drv->js_async('arguments[0]("bar")'), 'bar',
        q/js_async('arguments[0]("bar")')/;

    is $drv->js_phantom('return "baz"'), 'baz',
        q/js_phantomjs('return "baz"')/
        if $backend->{name} eq 'PhantomJS';
}

done_testing;
