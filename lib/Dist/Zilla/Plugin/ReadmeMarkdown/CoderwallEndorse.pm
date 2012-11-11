package Dist::Zilla::Plugin::ReadmeMarkdown::CoderwallEndorse;
# ABSTRACT: Adds a Coderwall 'endorse' button to README Markdown file

=head1 SYNOPSIS

    ; in dist.ini

    ; typically, to create the README off the main module
    [ReadmeMarkdownFromPod]

    [ReadmeMarkdow::CoderwallEndorse]
    users = coderwall_name : author name, other_cw_name : other author

=head1 DESCRIPTION

If a C<README.mkdn> file is presents, a Coderwall 'endorse' button will be
added beside author names if a author-name-to-coderwall-user mapping has been
given.

=head1 SEE ALSO

L<www.coderwall.com>

L<Dist::Zilla::Plugin:::ReadmeMarkdownFromPod>

=cut

use strict;
use warnings;

use Moose;

use List::Util qw/ first /;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
/;

has users => (
    is => 'ro',
    isa => 'Str',
);

has mapping => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my %m;
        for my $p ( split /\s*,\s*/, $self->users ) {
            my( $cd, $auth) = $p =~ /(\w+)\s*:\s*(.+?)\s*$/;
            $m{$auth} = $cd;
        }

        return \%m;
    },
    handles => {
        'authors' => 'keys',
        'cd_user' => 'get',
    },
);

sub munge_files {
    my $self = shift;

    my ( $readme ) = first { $_->name eq 'README.mkdn' } 
                           @{ $self->zilla->files } or return;

    my $new_content;

    for my $line ( split /\n/, $readme->content ) {
        if( $line=~ /^# AUTHOR/../^#/ ) {
            for my $auth ( $self->authors ) {
                next unless index $line, $auth > -1;
                $line .= sprintf " [![endorse](http://api.coderwall.com/%s/endorsecount.png)](http://coderwall.com/%s)",
                                ( $self->cd_user($auth) ) x 2;

            }
        }
        $new_content .= $line."\n";
    }

    $readme->content($new_content);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
