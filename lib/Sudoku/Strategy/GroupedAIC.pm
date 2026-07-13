package Sudoku::Strategy::GroupedAIC;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::InferenceNode;
use Sudoku::StrongLinks qw(
    strong_links_for_digit
    grouped_strong_links_for_digit
    nodes_are_weakly_linked
    cell_sees_node
);

use constant MAX_CHAIN_NODES => 9;

sub name {
    return 'Grouped AIC';
}

sub apply {
    my ( $self, $grid ) = @_;

    my $graph = _candidate_graph($grid);
    my @deductions;
    my %seen_deduction;

    for my $start_key (sort keys %{ $graph->{nodes} }) {
        my @path = ($start_key);
        my %visited = ($start_key => 1);

        _search(
            $self, $grid, $graph, $start_key, 'strong',
            \@path, \%visited, \%seen_deduction, \@deductions,
        );
    }

    return @deductions;
}

sub _search {
    my (
        $self, $grid, $graph, $start_key, $link_type,
        $path, $visited, $seen, $out,
    ) = @_;

    return if @{$path} >= MAX_CHAIN_NODES;

    my $current_key = $path->[-1];
    my $neighbors = $link_type eq 'strong'
        ? $graph->{strong}{$current_key}
        : $graph->{weak}{$current_key};

    for my $next_key (sort keys %{ $neighbors || {} }) {
        next if $visited->{$next_key};

        push @{$path}, $next_key;
        $visited->{$next_key} = 1;

        if ($link_type eq 'strong' && @{$path} >= 4) {
            _add_endpoint_eliminations(
                $self, $grid, $graph, $start_key, $next_key,
                $path, $seen, $out,
            );
        }

        _search(
            $self, $grid, $graph, $start_key,
            $link_type eq 'strong' ? 'weak' : 'strong',
            $path, $visited, $seen, $out,
        );

        delete $visited->{$next_key};
        pop @{$path};
    }
}

sub _add_endpoint_eliminations {
    my ( $self, $grid, $graph, $start_key, $end_key, $path, $seen, $out ) = @_;

    my $start = $graph->{nodes}{$start_key};
    my $end   = $graph->{nodes}{$end_key};

    return unless $start->digit == $end->digit;
    return unless grep { $graph->{nodes}{$_}->is_group } @{$path};
    return if $start->overlaps($end);

    my $digit = $start->digit;
    my %chain_cells = map { $_ => 1 }
        map { @{ $graph->{nodes}{$_}->cells } } @{$path};
    my $chain_text = _chain_text($graph, $path);

    for my $target (@{ $grid->cells }) {
        next if $target->value;
        next unless $target->possibilities->[$digit];
        next if $chain_cells{$target};
        next unless cell_sees_node($target, $start);
        next unless cell_sees_node($target, $end);

        my $deduction_key = join q{:}, $target->row, $target->column, $digit;
        next if $seen->{$deduction_key}++;

        push @{$out}, Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $target,
            value    => $digit,
            cells    => [ _path_cells($graph, $path) ],
            reason   => sprintf(
                'The grouped alternating inference chain %s begins and ends '
                . 'with strong links. At least one endpoint must contain %d. '
                . '%s sees every possible location in both endpoints and '
                . 'therefore cannot contain %d.',
                $chain_text,
                $digit,
                _cell_label($target),
                $digit,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. Grouped AIC endpoints %s and %s '
                . 'cannot both be false.',
                $digit,
                _cell_label($target),
                $start->label,
                $end->label,
            ),
        );
    }
}

sub _candidate_graph {
    my ($grid) = @_;

    my %nodes;
    my %strong;
    my %weak;

    for my $cell (@{ $grid->cells }) {
        next if $cell->value;

        my @digits = grep { $cell->possibilities->[$_] } 1 .. 9;
        my @singletons;
        for my $digit (@digits) {
            my $node = Sudoku::InferenceNode->new(
                digit => $digit,
                cells => [$cell],
            );
            $nodes{ $node->key } = $node;
            push @singletons, $node;
        }

        if (@singletons == 2) {
            _add_link(\%strong, $singletons[0]->key, $singletons[1]->key);
        }

        for my $first_index (0 .. $#singletons - 1) {
            for my $second_index ($first_index + 1 .. $#singletons) {
                _add_link(\%weak,
                    $singletons[$first_index]->key,
                    $singletons[$second_index]->key);
            }
        }
    }

    for my $digit (1 .. 9) {
        for my $link (strong_links_for_digit($grid, $digit)) {
            my @link_nodes = map {
                Sudoku::InferenceNode->new(digit => $digit, cells => [$_])
            } @{ $link->{cells} };
            $nodes{ $_->key } = $_ for @link_nodes;
            _add_link(\%strong, $link_nodes[0]->key, $link_nodes[1]->key);
        }

        for my $link (grouped_strong_links_for_digit($grid, $digit)) {
            my @link_nodes = @{ $link->{nodes} };
            $nodes{ $_->key } = $_ for @link_nodes;
            _add_link(\%strong, $link_nodes[0]->key, $link_nodes[1]->key);
        }
    }

    my %by_digit;
    push @{ $by_digit{ $nodes{$_}->digit } }, $nodes{$_} for keys %nodes;

    for my $digit (keys %by_digit) {
        my $digit_nodes = $by_digit{$digit};
        for my $first_index (0 .. $#{$digit_nodes} - 1) {
            for my $second_index ($first_index + 1 .. $#{$digit_nodes}) {
                my $first  = $digit_nodes->[$first_index];
                my $second = $digit_nodes->[$second_index];
                next unless nodes_are_weakly_linked($first, $second);
                _add_link(\%weak, $first->key, $second->key);
            }
        }
    }

    my %active = map { $_ => 1 } keys %strong;
    for my $key (keys %nodes) {
        delete $nodes{$key} unless $active{$key};
    }
    for my $key (keys %weak) {
        delete $weak{$key} unless $active{$key};
        next unless exists $weak{$key};
        for my $neighbor (keys %{ $weak{$key} }) {
            delete $weak{$key}{$neighbor} unless $active{$neighbor};
        }
    }

    return {
        nodes  => \%nodes,
        strong => \%strong,
        weak   => \%weak,
    };
}

sub _add_link {
    my ( $links, $first, $second ) = @_;
    return if $first eq $second;
    $links->{$first}{$second} = 1;
    $links->{$second}{$first} = 1;
}

sub _path_cells {
    my ( $graph, $path ) = @_;
    my %seen;
    return grep { !$seen{$_}++ }
        map { @{ $graph->{nodes}{$_}->cells } } @{$path};
}

sub _cell_label {
    my ($cell) = @_;
    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

sub _chain_text {
    my ( $graph, $path ) = @_;

    my @parts;
    for my $index (0 .. $#{$path}) {
        push @parts, $graph->{nodes}{ $path->[$index] }->label;
        next if $index == $#{$path};
        push @parts, $index % 2 ? '-W-' : '=S=';
    }

    return join q{ }, @parts;
}

1;
