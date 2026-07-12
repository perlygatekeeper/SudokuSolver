package Sudoku::Strategy::XYChains;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Wing qw(
    candidate_values
    cells_see_each_other
    common_peer_cells
    cell_label
);

use constant MAX_CHAIN_CELLS => 9;

sub name {
    return 'XY-Chains';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @bivalue_cells = grep {
           !$_->value
        && $_->possibilities->[0] == 2
    } @{ $grid->cells };

    my @deductions;
    my %seen_deduction;

    for my $start (@bivalue_cells) {
        my @start_values = candidate_values($start);

        for my $elimination (@start_values) {
            my ($outgoing) = grep { $_ != $elimination } @start_values;
            my @path = ($start);
            my %visited = ( _cell_key($start) => 1 );

            _search_chain(
                $self,
                $grid,
                \@bivalue_cells,
                $elimination,
                $outgoing,
                \@path,
                \%visited,
                \%seen_deduction,
                \@deductions,
            );
        }
    }

    return @deductions;
}

sub _search_chain {
    my (
        $self, $grid, $bivalue_cells, $elimination, $outgoing,
        $path, $visited, $seen_deduction, $out,
    ) = @_;

    return if @{$path} >= MAX_CHAIN_CELLS;

    my $current = $path->[-1];

    for my $next (@{$bivalue_cells}) {
        my $next_key = _cell_key($next);
        next if $visited->{$next_key};
        next unless cells_see_each_other($current, $next);

        my @next_values = candidate_values($next);
        next unless grep { $_ == $outgoing } @next_values;

        my ($next_outgoing) = grep { $_ != $outgoing } @next_values;
        next unless defined $next_outgoing;

        push @{$path}, $next;
        $visited->{$next_key} = 1;

        if ($next_outgoing == $elimination && @{$path} >= 3) {
            _add_endpoint_eliminations(
                $self,
                $grid,
                $elimination,
                $path,
                $seen_deduction,
                $out,
            );
        }
        else {
            _search_chain(
                $self,
                $grid,
                $bivalue_cells,
                $elimination,
                $next_outgoing,
                $path,
                $visited,
                $seen_deduction,
                $out,
            );
        }

        delete $visited->{$next_key};
        pop @{$path};
    }
}

sub _add_endpoint_eliminations {
    my ( $self, $grid, $elimination, $path, $seen, $out ) = @_;

    my $first = $path->[0];
    my $last  = $path->[-1];
    return if $first == $last;

    my $chain_text = _chain_text($path);

    for my $target (common_peer_cells($grid, $first, $last)) {
        next unless $target->possibilities->[$elimination];

        my $key = join q{:}, _cell_key($target), $elimination;
        next if $seen->{$key}++;

        push @{$out}, Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $target,
            value    => $elimination,
            cells    => [ @{$path} ],
            reason   => sprintf(
                'The bivalue cells form the XY-Chain %s. If %s is not %d, '
                . 'the alternating candidate links force %s to be %d. '
                . 'Therefore at least one endpoint contains %d, and %s, '
                . 'which sees both endpoints, cannot contain %d.',
                $chain_text,
                cell_label($first),
                $elimination,
                cell_label($last),
                $elimination,
                $elimination,
                cell_label($target),
                $elimination,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. XY-Chain endpoints %s and %s '
                . 'cannot both exclude %d.',
                $elimination,
                cell_label($target),
                cell_label($first),
                cell_label($last),
                $elimination,
            ),
        );
    }
}

sub _chain_text {
    my ($path) = @_;

    my @parts;
    for my $index (0 .. $#{$path}) {
        my @values = candidate_values($path->[$index]);
        push @parts, sprintf(
            '%s{%d,%d}',
            cell_label($path->[$index]),
            @values,
        );
    }

    return join q{ - }, @parts;
}

sub _cell_key {
    my ($cell) = @_;
    return join q{:}, $cell->row, $cell->column;
}

1;
