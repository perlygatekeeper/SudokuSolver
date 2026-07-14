package Sudoku::Render::GridBuilder;

use strict;
use warnings;

use Sudoku::Render::GridCharacters;

sub new {
    my ($class, %args) = @_;

    my $character_set = Sudoku::Render::GridCharacters->canonical_name(
        $args{character_set},
    );

    my $characters = $args{characters}
        ? _copy_and_validate_characters($args{characters})
        : Sudoku::Render::GridCharacters->character_set($character_set);

    return bless {
        character_set => $character_set,
        characters    => $characters,
    }, $class;
}

sub character_set {
    my ($self) = @_;
    return $self->{character_set};
}

sub characters {
    my ($self) = @_;

    my %copy = %{ $self->{characters} };
    return \%copy;
}

sub horizontal_rule {
    my ($self, %args) = @_;

    my $left       = $args{left}       // 'tee_right';
    my $junction   = $args{junction}   // 'cross';
    my $right      = $args{right}      // 'tee_left';
    my $horizontal = $args{horizontal} // 'horizontal';
    my @widths     = _segment_widths(%args);

    my $characters = $self->{characters};
    _require_components($characters, $left, $junction, $right, $horizontal);

    return $characters->{$left}
        . join(
            $characters->{$junction},
            map { $characters->{$horizontal} x $_ } @widths,
        )
        . $characters->{$right};
}

sub row {
    my ($self, %args) = @_;

    die "Grid row requires 'cells' as an array reference\n"
        if ref($args{cells}) ne 'ARRAY';

    my @cells = @{ $args{cells} };
    die "Grid row requires at least one cell\n" if !@cells;

    my $left  = $args{left}  // 'vertical';
    my $right = $args{right} // 'vertical';
    my @widths = _cell_widths(scalar @cells, %args);
    my @separators = _separator_components(scalar @cells, %args);
    my $align = $args{align} // 'center';

    die "Unknown grid row alignment '$align'\n"
        if $align ne 'left' && $align ne 'center' && $align ne 'right';

    my $characters = $self->{characters};
    _require_components($characters, $left, $right, @separators);

    my @rendered;
    for my $index (0 .. $#cells) {
        push @rendered, _fit_cell($cells[$index], $widths[$index], $align);
    }

    my $text = $characters->{$left};
    for my $index (0 .. $#rendered) {
        $text .= $rendered[$index];
        $text .= $characters->{ $separators[$index] }
            if $index < $#rendered;
    }
    $text .= $characters->{$right};

    return $text;
}

sub _segment_widths {
    my (%args) = @_;

    if (exists $args{segment_widths}) {
        die "'segment_widths' must be a non-empty array reference\n"
            if ref($args{segment_widths}) ne 'ARRAY'
                || !@{ $args{segment_widths} };

        my @widths = @{ $args{segment_widths} };
        _validate_widths(@widths);
        return @widths;
    }

    my $segments = $args{segments} // 1;
    my $width    = $args{segment_width} // 1;

    die "'segments' must be a positive integer\n"
        if $segments !~ /\A\d+\z/ || $segments < 1;

    _validate_widths($width);
    return ($width) x $segments;
}

sub _cell_widths {
    my ($cell_count, %args) = @_;

    if (exists $args{widths}) {
        die "'widths' must be an array reference with one entry per cell\n"
            if ref($args{widths}) ne 'ARRAY'
                || @{ $args{widths} } != $cell_count;

        my @widths = @{ $args{widths} };
        _validate_widths(@widths);
        return @widths;
    }

    my $width = $args{width} // 1;
    _validate_widths($width);
    return ($width) x $cell_count;
}

sub _separator_components {
    my ($cell_count, %args) = @_;

    return () if $cell_count == 1;

    if (exists $args{separators}) {
        die "'separators' must have one entry between each pair of cells\n"
            if ref($args{separators}) ne 'ARRAY'
                || @{ $args{separators} } != $cell_count - 1;

        return @{ $args{separators} };
    }

    my $separator = $args{separator} // 'vertical_minor';
    return ($separator) x ($cell_count - 1);
}

sub _fit_cell {
    my ($value, $width, $align) = @_;

    $value = q{} if !defined $value;
    $value = "$value";

    die "Cell value '$value' is wider than its configured width $width\n"
        if length($value) > $width;

    my $padding = $width - length($value);

    return $value . (' ' x $padding) if $align eq 'left';
    return (' ' x $padding) . $value if $align eq 'right';

    my $left_padding  = int($padding / 2);
    my $right_padding = $padding - $left_padding;
    return (' ' x $left_padding) . $value . (' ' x $right_padding);
}

sub _validate_widths {
    my (@widths) = @_;

    for my $width (@widths) {
        die "Grid widths must be positive integers\n"
            if !defined $width || $width !~ /\A\d+\z/ || $width < 1;
    }

    return 1;
}

sub _require_components {
    my ($characters, @components) = @_;

    for my $component (@components) {
        die "Unknown grid character component '$component'\n"
            if !exists $characters->{$component};
    }

    return 1;
}

sub _copy_and_validate_characters {
    my ($characters) = @_;

    die "Custom grid characters must be a hash reference\n"
        if ref($characters) ne 'HASH';

    Sudoku::Render::GridCharacters->validate_character_set(
        'CUSTOM',
        $characters,
    );

    my %copy = %{$characters};
    return \%copy;
}

1;
