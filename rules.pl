#!/usr/bin/perl -w
#
# Please consider using Python or Bash instead of Perl. The use of Perl is
# discouraged. If you must use Perl, make sure it is legible and consistent!

=pod

=head1 NAME

rules - One-line documentation for rules script

=head1 SYNOPSIS

 rules [options] [file ...]
     -helpshort   Display brief help message
     -help        Display full POD documentation

=head1 DESCRIPTION

A detailed description of rules.

=cut

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use vars qw($VERSION);

$VERSION = sprintf('%s', q$Change$ =~ /(\d+|.*)/g);

my ($flag_helpshort,$flag_help);
GetOptions( 'helpshort|?' => \$flag_helpshort,
            'help'        => \$flag_help
          ) or pod2usage(2);
pod2usage(1) if $flag_helpshort;
pod2usage(-exitstatus => 0, -verbose => 2) if $flag_help;

sub main() {
}

&main;

exit;

=pod

=head1 OPTIONS

=over 8

=item B<-helpshort>

Prints a brief help message and exits.

=item B<-help>

Prints the manual page and exits.

=back

=head1 VERSION

$Change$

=cut

__END__
