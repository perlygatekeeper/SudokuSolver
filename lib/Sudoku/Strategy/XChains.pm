package Sudoku::Strategy::XChains;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Fish qw(cell_label);
use Sudoku::StrongLinks qw(
    candidate_graph_for_digit
    cell_key
    cells_see_each_other
);

use constant MAX_CHAIN_LINKS => 9;

sub name {
    return 'X-Chains';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen_deduction;

    for my $digit (1 .. 9) {
        my $graph = candidate_graph_for_digit($grid, $digit);
        next unless keys %{ $graph->{nodes} };

        my @candidates = grep {
            !$_->value && $_->possibilities->[$digit]
        } @{ $grid->cells };

        my %candidate_by_key = map { cell_key($_) => $_ } @candidates;
        my @chain_candidates = values %{ $graph->{nodes} };
        my %weak_neighbors = _weak_neighbor_map(\@chain_candidates);

        for my $start_key (sort keys %{ $graph->{nodes} }) {
            for my $second_key (
                sort keys %{ $graph->{neighbors}{$start_key} || {} }
            ) {
                my @path = ($start_key, $second_key);
                my %visited = map { $_ => 1 } @path;

                _search_paths(
                    $self,
                    $digit,
                    $graph,
                    \%candidate_by_key,
                    \%weak_neighbors,
                    \@path,
                    \%visited,
                    'weak',
                    \%seen_deduction,
                    \@deductions,
                );
            }
        }
    }

    return @deductions;
}

sub _search_paths {
    my (
        $self, $digit, $graph, $candidate_by_key, $weak_neighbors,
        $path, $visited, $next_link_type, $seen_deduction, $out,
    ) = @_;

    my $link_count = @{$path} - 1;
    return if $link_count >= MAX_CHAIN_LINKS;

    my $current_key = $path->[-1];
    my @next_keys = $next_link_type eq 'strong'
        ? sort keys %{ $graph->{neighbors}{$current_key} || {} }
        : sort keys %{ $weak_neighbors->{$current_key} || {} };

    for my $next_key (@next_keys) {
        next if $visited->{$next_key};
        next unless exists $graph->{nodes}{$next_key};

        push @{$path}, $next_key;
        $visited->{$next_key} = 1;

        if ($next_link_type eq 'strong') {
            _add_endpoint_eliminations(
                $self,
                $digit,
                $candidate_by_key,
                $path,
                $seen_deduction,
                $out,
            );
        }

        _search_paths(
            $self,
            $digit,
            $graph,
            $candidate_by_key,
            $weak_neighbors,
            $path,
            $visited,
            $next_link_type eq 'strong' ? 'weak' : 'strong',
            $seen_deduction,
            $out,
        );

        delete $visited->{$next_key};
        pop @{$path};
    }
}

sub _add_endpoint_eliminations {
    my ( $self, $digit, $candidate_by_key, $path, $seen, $out ) = @_;

    # A useful X-Chain has at least strong-weak-strong: four nodes and
    # three links.  Shorter chains are ordinary conjugate-pair logic.
    return unless @{$path} >= 4;

    my $first = $candidate_by_key->{ $path->[0] };
    my $last  = $candidate_by_key->{ $path->[-1] };
    return if cells_see_each_other($first, $last);

    my %in_path = map { $_ => 1 } @{$path};
    my @chain_cells = map { $candidate_by_key->{$_} } @{$path};
    my $chain_text = _chain_text(\@chain_cells);

    for my $target_key (sort keys %{$candidate_by_key}) {
        next if $in_path{$target_key};

        my $target = $candidate_by_key->{$target_key};
        next unless cells_see_each_other($target, $first);
        next unless cells_see_each_other($target, $last);

        my $deduction_key = join q{:}, $target_key, $digit;
        next if $seen->{$deduction_key}++;

        push @{$out}, Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $target,
            value    => $digit,
            cells    => [@chain_cells],
            reason   => sprintf(
                'Candidate %d forms the alternating X-Chain %s. '
                . 'The chain begins and ends with strong links, so at least one endpoint (%s or %s) must contain %d. '
                . '%s sees both endpoints and therefore cannot contain %d.',
                $digit,
                $chain_text,
                cell_label($first),
                cell_label($last),
                $digit,
                cell_label($target),
                $digit,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. X-Chain endpoints %s and %s cannot both be false, and %s sees both.',
                $digit,
                cell_label($target),
                cell_label($first),
                cell_label($last),
                cell_label($target),
            ),
        );
    }
}

sub _weak_neighbor_map {
    my ($candidates) = @_;

    my %neighbors;

    for my $first_index (0 .. $#{$candidates} - 1) {
        for my $second_index ($first_index + 1 .. $#{$candidates}) {
            my $first  = $candidates->[$first_index];
            my $second = $candidates->[$second_index];
            next unless cells_see_each_other($first, $second);

            my $first_key  = cell_key($first);
            my $second_key = cell_key($second);
            $neighbors{$first_key}{$second_key} = 1;
            $neighbors{$second_key}{$first_key} = 1;
        }
    }

    return %neighbors;
}

sub _chain_text {
    my ($cells) = @_;

    my @parts = ( cell_label($cells->[0]) );
    for my $index (1 .. $#{$cells}) {
        push @parts, $index % 2 ? '=S=' : '-W-';
        push @parts, cell_label($cells->[$index]);
    }

    return join q{ }, @parts;
}

1;
