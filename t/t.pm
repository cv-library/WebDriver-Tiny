package t;

use strict;
use warnings;

my ( $reply, @args ) = { content => '{"sessionId":":sid"}', success => 1 };

sub HTTP::Tiny::new { bless {}, 'HTTP::Tiny' }

sub HTTP::Tiny::_request { shift; @args = @_; $reply }

BEGIN { $INC{'HTTP/Tiny.pm'} = 1; require WebDriver::Tiny }

sub import {
    strict->import;
    warnings->import;

    my $pkg = caller;

    eval "package $pkg; use Test::More tests => $_[1]";

    no strict 'refs';

    *{ $pkg . '::args_are' } = sub { Test::More::is_deeply( \@args, @_ ) };
    *{ $pkg . '::content'  } = \$reply->{content};
}

1;
