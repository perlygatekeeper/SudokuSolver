package Sudoku::Strategy::EmptyRectangle;
use strict;
use warnings;
use parent 'Sudoku::Strategy::Base';
use Sudoku::Deduction;
use Sudoku::Fish qw(cell_label);

sub name { return 'Empty Rectangle'; }

sub apply {
    my ($self, $grid) = @_;
    my (@deductions, %seen);

    for my $value (1 .. 9) {
        for my $box (0 .. 8) {
            my @cells = grep { !$_->value && $_->possibilities->[$value] }
                @{ $grid->boxes->[$box] };
            next unless @cells >= 2;

            my %rows = map { $_->row => 1 } @cells;
            my %cols = map { $_->column => 1 } @cells;

            for my $row (keys %rows) {
                for my $col (keys %cols) {
                    my $corner = $grid->cell_from_row_column($row, $col);
                    next unless $corner->box == $box;
                    next if $corner->possibilities->[$value];

                    my @row_arm = grep { $_->row == $row && $_->column != $col } @cells;
                    my @col_arm = grep { $_->column == $col && $_->row != $row } @cells;
                    next unless @row_arm && @col_arm;
                    next if grep { $_->row != $row && $_->column != $col } @cells;

                    _column_form($self, $grid, $value, $box, $row, $col,
                        \@row_arm, \@col_arm, \%seen, \@deductions);
                    _row_form($self, $grid, $value, $box, $row, $col,
                        \@row_arm, \@col_arm, \%seen, \@deductions);
                }
            }
        }
    }
    return @deductions;
}

sub _column_form {
    my ($self,$grid,$value,$box,$row,$col,$row_arm,$col_arm,$seen,$out)=@_;
    for my $link_col (0..8) {
        my $connector = $grid->cell_from_row_column($row,$link_col);
        next if $connector->box == $box || $connector->value;
        next unless $connector->possibilities->[$value];
        my @link = _column_candidates($grid,$link_col,$value);
        next unless @link == 2 && grep { $_ == $connector } @link;
        my ($remote) = grep { $_ != $connector } @link;
        my $target = $grid->cell_from_row_column($remote->row,$col);
        next if $target->value || !$target->possibilities->[$value];
        next if $target->box == $box;
        _add($self,$value,$box,$row,$col,$row_arm,$col_arm,
            $connector,$remote,$target,'column',$seen,$out);
    }
}

sub _row_form {
    my ($self,$grid,$value,$box,$row,$col,$row_arm,$col_arm,$seen,$out)=@_;
    for my $link_row (0..8) {
        my $connector = $grid->cell_from_row_column($link_row,$col);
        next if $connector->box == $box || $connector->value;
        next unless $connector->possibilities->[$value];
        my @link = _row_candidates($grid,$link_row,$value);
        next unless @link == 2 && grep { $_ == $connector } @link;
        my ($remote) = grep { $_ != $connector } @link;
        my $target = $grid->cell_from_row_column($row,$remote->column);
        next if $target->value || !$target->possibilities->[$value];
        next if $target->box == $box;
        _add($self,$value,$box,$row,$col,$row_arm,$col_arm,
            $connector,$remote,$target,'row',$seen,$out);
    }
}

sub _add {
    my ($self,$value,$box,$row,$col,$row_arm,$col_arm,
        $connector,$remote,$target,$orientation,$seen,$out)=@_;
    my $key = join ':',$target->row,$target->column,$value;
    return if $seen->{$key}++;
    push @$out, Sudoku::Deduction->new(
        strategy => $self->name,
        action => 'remove_candidate',
        cell => $target,
        value => $value,
        cells => [@$row_arm,@$col_arm,$connector,$remote],
        reason => sprintf(
            'Candidate %d forms an Empty Rectangle in box %d around the empty intersection R%dC%d. '
            . 'The box candidates are confined to row %d or column %d, and %s-%s is a strong link '
            . 'in %s %d. Therefore %s cannot contain %d.',
            $value,$box+1,$row+1,$col+1,$row+1,$col+1,
            cell_label($connector),cell_label($remote),$orientation,
            $orientation eq 'column' ? $connector->column+1 : $connector->row+1,
            cell_label($target),$value),
        explanation => sprintf(
            'Remove candidate %d from %s. Empty Rectangle in box %d with strong-link endpoints %s and %s.',
            $value,cell_label($target),$box+1,cell_label($connector),cell_label($remote)),
    );
}

sub _row_candidates {
    my ($grid,$row,$value)=@_;
    return grep { !$_->value && $_->possibilities->[$value] }
        map { $grid->cell_from_row_column($row,$_) } 0..8;
}
sub _column_candidates {
    my ($grid,$col,$value)=@_;
    return grep { !$_->value && $_->possibilities->[$value] }
        map { $grid->cell_from_row_column($_,$col) } 0..8;
}
1;
