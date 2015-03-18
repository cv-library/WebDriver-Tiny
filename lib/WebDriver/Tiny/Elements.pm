package WebDriver::Tiny::Elements 0.001;

use 5.014;
use warnings;

# Manip
sub first { bless [ @{ $_[0] }[ 0,  1 ] ] }
sub last  { bless [ @{ $_[0] }[ 0, -1 ] ] }
sub size  { $#{ $_[0] } }
sub slice { my ( $drv, @ids ) = @{ +shift }; bless [ $drv, @ids[@_] ] }

sub attr { $_[0]->_req( GET => "/attribute/$_[1]" )->{value} }
sub css  { $_[0]->_req( GET =>       "/css/$_[1]" )->{value} }

sub clear { $_[0]->_req( POST => '/clear' ); $_[0] }
sub click { $_[0]->_req( POST => '/click' ); $_[0] }
sub tap   { $_[0]->_req( POST => '/tap'   ); $_[0] }

sub enabled  { $_[0]->_req( GET => '/enabled'   )->{value} }
sub rect     { $_[0]->_req( GET => '/rect'      )->{value} }
sub selected { $_[0]->_req( GET => '/selected'  )->{value} }
sub tag      { $_[0]->_req( GET => '/name'      )->{value} }
sub visible  { $_[0]->_req( GET => '/displayed' )->{value} }

*find       = \&WebDriver::Tiny::find;
*screenshot = \&WebDriver::Tiny::screenshot;

sub move_to {
    $_[0][0]->_req( POST => '/moveto', { element => $_[0][1] } );

    $_[0];
}

sub send_keys {
    my ( $self, @keys ) = @_;

    $self->_req( POST => '/value', { value => \@keys } );

    $self;
}

sub submit {
    my ( $self, %values ) = @_;

    while ( my ( $name, $value ) = each %values ) {
        my $elem = $self->find("[name='$name']");
        my $tag  = $elem->tag;

        if ( $tag =~ /^(?:input|textarea)$/ ) {
            my $type = $elem->attr('type');

            if ( $type eq 'checkbox' ) {
                # Click the element if the desired value is different to its
                # current selected state, i.e. value xor state.
                #
                # We not each value to get a consistent true/false.
                $elem->click if !$value != !$elem->selected;
            }
            elsif ( $type eq 'radio' ) {
                $self->find("[name='$name'][value='$value']")->click;
            }
            else {
                # Selenium won't let you clear a file input.
                $elem->clear if $type ne 'file';

                # Stringify potential objects, like File::Temp.
                $elem->send_keys("$value");
            }
        }
        elsif ( $tag eq 'select' ) {
            $elem->find("[value='$_']")->click
                for ref $value ? @$value : $value;
        }
    }

    $self->_req( POST => '/submit' );

    $self;
}

sub text {
    my ( $drv, @ids ) = @{ $_[0] };

    join ' ', map $drv->_req( GET => "/element/$_/text" )->{value}, @ids;
}

# Call driver's ->_req, prepend "/element/:id" to the path first.
sub _req { $_[0][0]->_req( $_[1], "/element/$_[0][1]$_[2]", $_[3] ) }

1;
