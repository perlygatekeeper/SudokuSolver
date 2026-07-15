#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Text::ParseWords qw(parse_line);

use lib 'lib';

use Sudoku::Render::Text;

{
    package Local::DelimitedCell;
    sub new { my ($class, %args) = @_; return bless \%args, $class; }
    sub value { return $_[0]{value}; }
    sub given { return $_[0]{given}; }
}

{
    package Local::DelimitedGrid;
    sub new { my ($class, @cells) = @_; return bless { cells => \@cells }, $class; }
    sub cells { return $_[0]{cells}; }
    sub solved { return 2; }
}

{
    package Local::DelimitedHash;
    sub new { my ($class, $value) = @_; return bless $value, $class; }
    sub as_hash { return +{ %{ $_[0] } }; }
}

{
    package Local::DelimitedSolver;
    sub deduction_count { return 7; }
    sub has_contradiction { return 0; }
    sub difficulty {
        return Local::DelimitedHash->new({
            label          => 'Hard, but fair',
            score          => 4,
            rating_version => '2.5',
        });
    }
    sub statistics {
        return Local::DelimitedHash->new({
            note             => "line one\nline two",
            total_deductions => 7,
        });
    }
}

my @cells = (
    Local::DelimitedCell->new(value => 5, given => 1),
    Local::DelimitedCell->new(value => 3, given => 0),
    map { Local::DelimitedCell->new(value => 0, given => 0) } 3 .. 81,
);
my $grid = Local::DelimitedGrid->new(@cells);
my $solver = bless {}, 'Local::DelimitedSolver';
my $renderer = Sudoku::Render::Text->new;

my $csv = $renderer->result_csv($solver, $grid);
my @csv_lines = split /\n/, $csv;
is(scalar @csv_lines, 2, 'CSV contains a header and one result row');
my @csv_header = parse_line(q{,}, 0, $csv_lines[0]);
my @csv_row = parse_line(q{,}, 0, $csv_lines[1]);
is(scalar @csv_header, 15, 'CSV exposes the stable column set');
is(scalar @csv_row, 15, 'CSV result has one value per column');
is($csv_header[0], 'status', 'CSV begins with status');
is($csv_row[0], 'stalled', 'CSV records solve status');
is($csv_row[7], 'Hard, but fair', 'CSV quotes delimiters within fields');
like($csv, qr/""total_deductions"":7/, 'CSV escapes canonical statistics JSON');

my $tsv = $renderer->result_tsv($solver, $grid);
my @tsv_lines = split /\n/, $tsv;
is(scalar @tsv_lines, 2, 'TSV contains a header and one result row');
my @tsv_header = split /\t/, $tsv_lines[0], -1;
my @tsv_row = split /\t/, $tsv_lines[1], -1;
is(scalar @tsv_header, 15, 'TSV exposes the stable column set');
is(scalar @tsv_row, 15, 'TSV result has one value per column');
is($tsv_row[7], 'Hard, but fair', 'TSV preserves commas without quoting');
like($tsv_row[10], qr/\\\\n/, 'TSV escapes embedded newlines');

is(
    $renderer->render_result($solver, $grid, format => 'csv'),
    $csv,
    'result dispatcher renders CSV',
);
is(
    $renderer->render_result($solver, $grid, format => 'tsv'),
    $tsv,
    'result dispatcher renders TSV',
);

is_deeply(
    [ $renderer->available_result_formats ],
    [ qw(json csv tsv) ],
    'result discovery includes JSON, CSV, and TSV',
);

my $error = q{};
eval { $renderer->render_result($solver, $grid, format => 'xml') };
$error = $@;
like(
    $error,
    qr/Unknown result format 'xml'; available formats: json, csv, tsv/,
    'result dispatcher reports unknown formats',
);

done_testing;
