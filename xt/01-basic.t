use strict;
use utf8;
use warnings;

for my $backend (@::backends) {
    note $backend->{name};

    my $drv = WebDriver::Tiny->new( %{ $backend->{args} } );

    cmp_deeply $drv->capabilities, $backend->{capabilities}, 'capabilities';

    $drv->get($::url);

    cmp_deeply $drv->page_ids, [ re qr/^[-\w]+$/ ], 'page_ids';

    {
        open my $fh, '<:encoding(UTF-8)', 'xt/test.html';

        local $/;

        my $got = $drv->source;

        # Try to normalise the HTML.
        $got =~ s/\s//g;
        $got =~ s/\/>/>/g;
        $got =~ s|xmlns="http://www.w3.org/1999/xhtml"||;

        is $got, <$fh> =~ s/\s//gr, 'source';
    }

    is $drv->('h1')->text, 'ᴛ̲ʜ̲ᴇ̲ʀ̲ᴇ̲ ̲ɪ̲s̲ ̲ɴ̲ᴏ̲ ̲U̲ɴ̲ɪ̲ᴄ̲ᴏ̲ᴅ̲ᴇ̲ ̲ᴍ̲ᴀ̲ɢ̲ɪ̲ᴄ̲ ̲ʙ̲ᴜ̲ʟ̲ʟ̲ᴇ̲ᴛ̲', 'text';

    is $drv->('h3')->text, 'foo bar', 'text on more than one element';

    is_deeply [ map $_->text, $drv->('h3') ], [qw/foo bar/],
        'find is list context';

    is_deeply [ map $_->text, $drv->('h3')->split ], [qw/foo bar/],
        'split';

    is $drv->title, 'Frosty the ☃', 'title';

    is $drv->url, $::url, 'url';

    like $drv->user_agent, $backend->{user_agent}, 'user_agent';

    $drv->( 'go to bottom', method => 'link_text' )->click;

    is $drv->url, $::url . '#bottom', 'click';

    $drv->( 'go to top', method => 'link_text' )->click;

    is $drv->url, $::url . '#top', 'click';
}

done_testing;
