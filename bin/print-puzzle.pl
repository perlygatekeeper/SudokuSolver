#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Grid;
use Solver;
use Sudoku::Render::Text;

binmode STDOUT, ':encoding(UTF-8)';

my $file;
my $puzzle_index = 1;
my $puzzle_string;
my $character_set = 'UNICODE_MIXED';
my $help;

GetOptions(
    'file|f=s'          => \$file,
    'puzzle|p=i'        => \$puzzle_index,
    'string|s=s'        => \$puzzle_string,
    'character-set|c=s' => \$character_set,
    'help|h'            => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

die "Provide either --string PUZZLE or --file FILE, not both\n"
    if defined($puzzle_string) && defined($file);
pod2usage("Provide --string PUZZLE or --file FILE\n")
    if !defined($puzzle_string) && !defined($file);

my $solver = Solver->new(output_mode => 'quiet');
my $normalized;

if (defined $puzzle_string) {
    $normalized = $solver->normalize_puzzle_string($puzzle_string);
} else {
    die "Puzzle number must be >= 1\n" if $puzzle_index < 1;

    my @puzzles = $solver->puzzle_strings_from_file($file);
    die "Puzzle number $puzzle_index not found in $file\n"
        if $puzzle_index > @puzzles;

    $normalized = $puzzles[$puzzle_index - 1];
}

my $grid = Grid->new;
$grid->load_from_string($normalized);

$character_set = uc $character_set;
$character_set =~ tr/-/_/;

my $renderer = Sudoku::Render::Text->new(
    character_set => $character_set,
    color         => 'never',
);

print $renderer->render_grid($grid, format => 'pretty');

exit 0;

__END__

=head1 NAME

print-puzzle.pl - print a Sudoku puzzle as entered

=head1 SYNOPSIS

  bin/print-puzzle.pl --string PUZZLE
  bin/print-puzzle.pl --file FILE [--puzzle N]

=head1 DESCRIPTION

Prints a Sudoku puzzle without solving it, using the project's Unicode pretty
grid renderer. Blanks may be written as C<0>, C<.>, or other non-digit
characters accepted by the normal puzzle-string loader.

=head1 OPTIONS

=over 4

=item B<-s, --string PUZZLE>

Puzzle string to print.

=item B<-f, --file FILE>

File containing one or more puzzles.

=item B<-p, --puzzle N>

1-based puzzle number to read from C<--file>. Defaults to 1.

=item B<-c, --character-set NAME>

Grid character set. Defaults to C<UNICODE_LIGHT>. Other existing renderer sets
include C<UNICODE_DOUBLE>, C<UNICODE_HEAVY>, and C<UNICODE_MIXED>.

=item B<-h, --help>

Show this help.

=back
