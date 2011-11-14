package Catalyst::Plugin::SanitizeUrl::PrepAction;

use strict;
use warnings;

our $VERSION = '0.2.0';

=head1 NAME

Catalyst::Plugin::SanitizeUrl::PrepAction  - A class to abstract functionality 
out of the prepare_action method.

=head1 SYNOPSIS

For internal use by L<Catalyst::Plugin::SanitizeUrl> .

=head2 $c->get_action_path

Calculate the path components for the action. Returns an array reference
containing the 

=cut

sub get_action_path {
    my ($self, $c) = @_;
    my $path = $c->req->path;
    return [ split /\//, $c->req->path ];
}

=head2 $c->prepare_action

Prepare action. This function is nearly identical to the one in Catalyst.pm
with the only difference is the extraction of the get_action_path() 
method. <sigh />

=cut

sub prepare_action {
    my ( $self, $c ) = @_;
    my $req = $c->req;
    my $path = $req->path;
    my @path = @{$self->get_action_path($c)};
    $req->args( \my @args );
 
    unshift( @path, '' );    # Root action
 
  DESCEND: while (@path) {
        $path = join '/', @path;
        $path =~ s#^/+##;
 
        # Check out dispatch types to see if any will handle the path at
        # this level
 
        foreach my $type ( @{ $self->dispatch_types } ) {
            last DESCEND if $type->match( $c, $path );
        }
 
        # If not, move the last part path to args
        my $arg = pop(@path);
        $arg =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        unshift @args, $arg;
    }
 
    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg for grep { defined } @{$req->captures||[]};
 
    $c->log->debug( 'Path is "' . $req->match . '"' )
      if ( $c->debug && defined $req->match && length $req->match );
 
    $c->log->debug( 'Arguments are "' . join( '/', @args ) . '"' )
      if ( $c->debug && @args );
}

=head1 SEE ALSO

L<Catalyst::Plugin::SanitizeUrl>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

Modified by Shlomi Fish, C<shlomif@iglu.org.il> (All rights disclaimed).

=head1 LICENSE

This program is free software. You may copy or redistribute it under the same 
terms as Perl itself.

=cut

