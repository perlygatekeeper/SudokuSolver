#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Grid;
use Solver;
use Sudoku::Render::Text;

binmode STDOUT, ':encoding(UTF-8)';

my $sample_puzzle =
      '000000013'
    . '000800070'
    . '000502000'
    . '000400900'
    . '107000000'
    . '000000200'
    . '890000050'
    . '040000600'
    . '000010000';

my $sample_solution =
      '258674913'
    . '913826475'
    . '674592138'
    . '526487391'
    . '187239546'
    . '439165287'
    . '891743652'
    . '745921863'
    . '362358719';

my $character_set = 'UNICODE_LIGHT';
my $binary_dir;
my $help;

GetOptions(
    'character-set|c=s' => \$character_set,
    'binary-dir=s'      => \$binary_dir,
    'help|h'            => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

$character_set = uc $character_set;
$character_set =~ tr/-/_/;

my $renderer = Sudoku::Render::Text->new(
    character_set => $character_set,
    color         => 'never',
);

my $puzzle_grid = _grid_from_string($sample_puzzle);
my $solved_grid = _grid_from_string($sample_solution);

make_path($binary_dir) if defined $binary_dir && !-d $binary_dir;

for my $format ($renderer->available_grid_formats) {
    say "== $format ==";

    my $grid = $format eq 'solution-line' ? $solved_grid : $puzzle_grid;
    my $output = eval { $renderer->render_grid($grid, format => $format) };

    if (!$output) {
        chomp(my $error = $@ || 'unknown rendering error');
        say "Could not render example: $error\n";
        next;
    }

    if ($format eq 'png' || $format eq 'pdf') {
        _print_binary_example($format, $output);
    }
    else {
        print $output;
        print "\n" unless $output =~ /\n\z/;
    }

    print "\n";
}

exit 0;

sub _grid_from_string {
    my ($string) = @_;

    my $solver = Solver->new(output_mode => 'quiet');
    my $grid = Grid->new;
    $grid->load_from_string($solver->normalize_puzzle_string($string));
    return $grid;
}

sub _print_binary_example {
    my ($format, $output) = @_;

    my $bytes = length($output);
    my $signature = unpack 'H*', substr($output, 0, 12);
    say "Binary $format example: $bytes bytes";
    say "First 12 bytes: $signature";

    return unless defined $binary_dir;

    my $path = File::Spec->catfile($binary_dir, "grid-example.$format");
    open my $out, '>:raw', $path
        or die "Cannot create '$path': $!\n";
    print {$out} $output
        or die "Cannot write '$path': $!\n";
    close $out
        or die "Cannot close '$path': $!\n";

    say "Wrote example file: $path";
}

__END__

=head1 NAME

list-grid-format-examples.pl - show examples of every grid format

=head1 SYNOPSIS

  bin/list-grid-format-examples.pl
  bin/list-grid-format-examples.pl --character-set UNICODE_DOUBLE
  bin/list-grid-format-examples.pl --binary-dir examples-output/grid-formats

=head1 DESCRIPTION

Prints each grid format supported by C<Sudoku::Render::Text>, followed by an
example rendered from a built-in puzzle. Text formats are printed inline.
Binary C<png> and C<pdf> formats are summarized by byte count and file
signature; pass C<--binary-dir> to write those examples to files.

=head1 OPTIONS

=over 4

=item B<-c, --character-set NAME>

Character set for text grid examples. Defaults to C<UNICODE_LIGHT>.

=item B<--binary-dir DIR>

Directory where binary C<png> and C<pdf> examples should be written.

=item B<-h, --help>

Show this help.

=back
