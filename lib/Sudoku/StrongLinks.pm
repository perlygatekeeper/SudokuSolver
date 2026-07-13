package Sudoku::StrongLinks;

use strict;
use warnings;

use Exporter 'import';

use Sudoku::InferenceNode;

our @EXPORT_OK = qw(
    strong_links_for_digit
    candidate_graph_for_digit
    connected_components
    color_component
    cell_key
    cells_see_each_other
    grouped_strong_links_for_digit
    nodes_are_weakly_linked
    cell_sees_node
);

sub cell_key {
    my ($cell) = @_;
    return join q{:}, $cell->row, $cell->column;
}

sub cells_see_each_other {
    my ( $first, $second ) = @_;

    return 1 if $first->row == $second->row;
    return 1 if $first->column == $second->column;
    return 1 if $first->box == $second->box;

    return 0;
}

sub strong_links_for_digit {
    my ( $grid, $digit ) = @_;

    my @links;
    my %seen;

    for my $row (0 .. 8) {
        _add_unit_link(\@links, \%seen, 'row', $row,
            (map { $grid->cell_from_row_column($row, $_) } 0 .. 8),
            $digit);
    }

    for my $column (0 .. 8) {
        _add_unit_link(\@links, \%seen, 'column', $column,
            (map { $grid->cell_from_row_column($_, $column) } 0 .. 8),
            $digit);
    }

    for my $box (0 .. 8) {
        _add_unit_link(\@links, \%seen, 'box', $box,
            @{ $grid->boxes->[$box] }, $digit);
    }

    return @links;
}


sub grouped_strong_links_for_digit {
    my ( $grid, $digit ) = @_;

    my @links;
    my %seen;

    for my $box (0 .. 8) {
        my @cells = grep {
            !$_->value && $_->possibilities->[$digit]
        } @{ $grid->boxes->[$box] };

        _add_partitioned_group_link(
            \@links, \%seen, 'box-row', $box, \@cells,
            sub { $_[0]->row }, $digit,
        );
        _add_partitioned_group_link(
            \@links, \%seen, 'box-column', $box, \@cells,
            sub { $_[0]->column }, $digit,
        );
    }

    for my $row (0 .. 8) {
        my @cells = grep {
            !$_->value && $_->possibilities->[$digit]
        } map { $grid->cell_from_row_column($row, $_) } 0 .. 8;

        _add_partitioned_group_link(
            \@links, \%seen, 'row-box', $row, \@cells,
            sub { $_[0]->box }, $digit,
        );
    }

    for my $column (0 .. 8) {
        my @cells = grep {
            !$_->value && $_->possibilities->[$digit]
        } map { $grid->cell_from_row_column($_, $column) } 0 .. 8;

        _add_partitioned_group_link(
            \@links, \%seen, 'column-box', $column, \@cells,
            sub { $_[0]->box }, $digit,
        );
    }

    return @links;
}

sub nodes_are_weakly_linked {
    my ( $first, $second ) = @_;

    return 0 unless $first->digit == $second->digit;
    return 0 if $first->overlaps($second);

    for my $first_cell ( @{ $first->cells } ) {
        for my $second_cell ( @{ $second->cells } ) {
            return 0 unless cells_see_each_other($first_cell, $second_cell);
        }
    }

    return 1;
}

sub cell_sees_node {
    my ( $cell, $node ) = @_;

    for my $node_cell ( @{ $node->cells } ) {
        return 0 unless cells_see_each_other($cell, $node_cell);
    }

    return 1;
}

sub _add_partitioned_group_link {
    my ( $links, $seen, $type, $index, $cells, $group_key, $digit ) = @_;

    return unless @{$cells} >= 2;

    my %groups;
    push @{ $groups{ $group_key->($_) } }, $_ for @{$cells};
    return unless keys(%groups) == 2;

    my @nodes = map {
        Sudoku::InferenceNode->new(
            digit => $digit,
            cells => $groups{$_},
        )
    } sort { $a <=> $b } keys %groups;

    return unless grep { $_->is_group } @nodes;

    my $link_key = join q{|}, sort map { $_->key } @nodes;
    return if $seen->{$link_key}++;

    push @{$links}, {
        type  => $type,
        index => $index,
        nodes => \@nodes,
    };
}

sub candidate_graph_for_digit {
    my ( $grid, $digit ) = @_;

    my %nodes;
    my %neighbors;
    my @links = strong_links_for_digit($grid, $digit);

    for my $link (@links) {
        my ( $first, $second ) = @{ $link->{cells} };
        my $first_key  = cell_key($first);
        my $second_key = cell_key($second);

        $nodes{$first_key}  = $first;
        $nodes{$second_key} = $second;
        $neighbors{$first_key}{$second_key} = 1;
        $neighbors{$second_key}{$first_key} = 1;
    }

    return {
        digit     => $digit,
        nodes     => \%nodes,
        neighbors => \%neighbors,
        links     => \@links,
    };
}

sub connected_components {
    my ($graph) = @_;

    my @components;
    my %visited;

    for my $start (sort keys %{ $graph->{nodes} }) {
        next if $visited{$start};

        my @queue = ($start);
        my @keys;
        $visited{$start} = 1;

        while (@queue) {
            my $key = shift @queue;
            push @keys, $key;

            for my $neighbor (sort keys %{ $graph->{neighbors}{$key} || {} }) {
                next if $visited{$neighbor}++;
                push @queue, $neighbor;
            }
        }

        push @components, {
            keys  => \@keys,
            cells => [ map { $graph->{nodes}{$_} } @keys ],
        };
    }

    return @components;
}

sub color_component {
    my ( $graph, $component ) = @_;

    my %color;
    my @queue = ( $component->{keys}[0] );
    $color{ $component->{keys}[0] } = 0;
    my $conflicted = 0;

    while (@queue) {
        my $key = shift @queue;

        for my $neighbor (keys %{ $graph->{neighbors}{$key} || {} }) {
            my $expected = 1 - $color{$key};

            if (exists $color{$neighbor}) {
                $conflicted = 1 if $color{$neighbor} != $expected;
                next;
            }

            $color{$neighbor} = $expected;
            push @queue, $neighbor;
        }
    }

    return ( \%color, $conflicted );
}

sub _add_unit_link {
    my ( $links, $seen, $type, $index, @args ) = @_;
    my $digit = pop @args;

    my @candidates = grep {
        !$_->value && $_->possibilities->[$digit]
    } @args;

    return unless @candidates == 2;

    my @keys = sort map { cell_key($_) } @candidates;
    my $key = join q{|}, @keys;
    return if $seen->{$key}++;

    push @{$links}, {
        type  => $type,
        index => $index,
        cells => \@candidates,
    };
}

1;
