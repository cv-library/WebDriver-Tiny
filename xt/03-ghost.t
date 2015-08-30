use strict;
use utf8;
use warnings;

for my $backend (@::backends) {
    note $backend->{name};

    my $drv = WebDriver::Tiny->new( %{ $backend->{args} } );

    $drv->get($::url);

    my $ghost = $drv->('body')->find('#ghost');

    is $ghost->attr('id'), 'ghost', '$ghost->attr("id")';
    is $ghost->css('display'), 'none', '$ghost->css("display")';
    is $ghost->tag, 'h2', '$ghost->tag';
    is $ghost->text, '', '$ghost->text';
    ok !$ghost->visible, '$ghost->visible';

    $drv->js( 'arguments[0].style.display = "block"', $ghost );

    ok $ghost->visible, '$ghost is now visible';
    is $ghost->text, '👻', '$ghost now has text';
}

done_testing;
