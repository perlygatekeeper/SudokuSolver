package Sudoku::Strategy::AIC;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::StrongLinks qw(cells_see_each_other);

use constant MAX_CHAIN_NODES => 9;

sub name {
    return 'AIC';
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
            $self,
            $grid,
            $graph,
            $start_key,
            'strong',
            \@path,
            \%visited,
            \%seen_deduction,
            \@deductions,
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
            $self,
            $grid,
            $graph,
            $start_key,
            $link_type eq 'strong' ? 'weak' : 'strong',
            $path,
            $visited,
            $seen,
            $out,
        );

        delete $visited->{$next_key};
        pop @{$path};
    }
}

sub _add_endpoint_eliminations {
    my ( $self, $grid, $graph, $start_key, $end_key, $path, $seen, $out ) = @_;

    my $start = $graph->{nodes}{$start_key};
    my $end   = $graph->{nodes}{$end_key};

    return unless $start->{digit} == $end->{digit};
    return if $start->{cell} == $end->{cell};

    my $digit = $start->{digit};
    my %chain_cells = map { $graph->{nodes}{$_}{cell} => 1 } @{$path};
    my $chain_text = _chain_text($graph, $path);

    for my $target (@{ $grid->cells }) {
        next if $target->value;
        next unless $target->possibilities->[$digit];
        next if $chain_cells{$target};
        next unless cells_see_each_other($target, $start->{cell});
        next unless cells_see_each_other($target, $end->{cell});

        my $deduction_key = join q{:}, $target->row, $target->column, $digit;
        next if $seen->{$deduction_key}++;

        push @{$out}, Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $target,
            value    => $digit,
            cells    => [ map { $graph->{nodes}{$_}{cell} } @{$path} ],
            reason   => sprintf(
                'The alternating inference chain %s begins and ends with strong links. '
                . 'If %s(%d) were false, the alternating strong and weak implications '
                . 'would force %s(%d) true. Therefore at least one endpoint is true, '
                . 'and %s, which sees both endpoints, cannot contain %d.',
                $chain_text,
                _cell_label($start->{cell}), $digit,
                _cell_label($end->{cell}),   $digit,
                _cell_label($target),        $digit,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. AIC endpoints %s(%d) and %s(%d) '
                . 'cannot both be false.',
                $digit,
                _cell_label($target),
                _cell_label($start->{cell}), $digit,
                _cell_label($end->{cell}),   $digit,
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
        for my $digit (@digits) {
            my $key = _node_key($cell, $digit);
            $nodes{$key} = { cell => $cell, digit => $digit };
        }

        if (@digits == 2) {
            _add_link(\%strong,
                _node_key($cell, $digits[0]),
                _node_key($cell, $digits[1]));
        }

        if (@digits > 1) {
            for my $first_index (0 .. $#digits - 1) {
                for my $second_index ($first_index + 1 .. $#digits) {
                    _add_link(\%weak,
                        _node_key($cell, $digits[$first_index]),
                        _node_key($cell, $digits[$second_index]));
                }
            }
        }
    }

    for my $digit (1 .. 9) {
        for my $units ($grid->rows, $grid->columns, $grid->boxes) {
            for my $unit (@{$units}) {
                my @cells = grep {
                    !$_->value && $_->possibilities->[$digit]
                } @{$unit};

                if (@cells == 2) {
                    _add_link(\%strong,
                        _node_key($cells[0], $digit),
                        _node_key($cells[1], $digit));
                }

                if (@cells > 1) {
                    for my $first_index (0 .. $#cells - 1) {
                        for my $second_index ($first_index + 1 .. $#cells) {
                            _add_link(\%weak,
                                _node_key($cells[$first_index],  $digit),
                                _node_key($cells[$second_index], $digit));
                        }
                    }
                }
            }
        }
    }

    # Internal AIC nodes must participate in a strong link. Removing all other
    # nodes keeps the bounded search practical without changing valid chains.
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

sub _node_key {
    my ( $cell, $digit ) = @_;
    return join q{:}, $cell->row, $cell->column, $digit;
}

sub _cell_label {
    my ($cell) = @_;
    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

sub _chain_text {
    my ( $graph, $path ) = @_;

    my @parts;
    for my $index (0 .. $#{$path}) {
        my $node = $graph->{nodes}{ $path->[$index] };
        push @parts, sprintf '%s(%d)', _cell_label($node->{cell}), $node->{digit};
        next if $index == $#{$path};
        push @parts, $index % 2 ? '-W-' : '=S=';
    }

    return join q{ }, @parts;
}

1;
