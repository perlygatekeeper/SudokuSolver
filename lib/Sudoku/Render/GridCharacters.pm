package Sudoku::Render::GridCharacters;

use strict;
use warnings;
use utf8;

my @REQUIRED_COMPONENTS = qw(
    horizontal
    vertical
    vertical_minor
    cross
    tee_down
    tee_up
    tee_right
    tee_left
    corner_down_right
    corner_down_left
    corner_up_right
    corner_up_left
);

my %GRID_CHARACTER_SETS = (
    ASCII => {
        horizontal         => '-',
        vertical           => '|',
        vertical_minor     => q{'},
        cross              => '+',
        tee_down           => '+',
        tee_up             => '+',
        tee_right          => '+',
        tee_left           => '+',
        corner_down_right  => '+',
        corner_down_left   => '+',
        corner_up_right    => '+',
        corner_up_left     => '+',
    },

    UNICODE_LIGHT => {
        horizontal         => '─',
        vertical           => '│',
        vertical_minor     => '│',
        cross              => '┼',
        tee_down           => '┬',
        tee_up             => '┴',
        tee_right          => '├',
        tee_left           => '┤',
        corner_down_right  => '┌',
        corner_down_left   => '┐',
        corner_up_right    => '└',
        corner_up_left     => '┘',
    },

    UNICODE_DOUBLE => {
        horizontal         => '═',
        vertical           => '║',
        vertical_minor     => '║',
        cross              => '╬',
        tee_down           => '╦',
        tee_up             => '╩',
        tee_right          => '╠',
        tee_left           => '╣',
        corner_down_right  => '╔',
        corner_down_left   => '╗',
        corner_up_right    => '╚',
        corner_up_left     => '╝',
    },

    UNICODE_HEAVY => {
        horizontal         => '━',
        vertical           => '┃',
        vertical_minor     => '┃',
        cross              => '╋',
        tee_down           => '┳',
        tee_up             => '┻',
        tee_right          => '┣',
        tee_left           => '┫',
        corner_down_right  => '┏',
        corner_down_left   => '┓',
        corner_up_right    => '┗',
        corner_up_left     => '┛',
    },
);

my %ALIASES = (
    UNICODE_NORMAL => 'UNICODE_LIGHT',
    UNICODE_BOLD   => 'UNICODE_HEAVY',
);

sub names {
    return sort keys %GRID_CHARACTER_SETS;
}

sub required_components {
    return @REQUIRED_COMPONENTS;
}

sub canonical_name {
    my ($class, $name) = @_;

    $name = 'ASCII' if !defined $name || $name eq q{};
    return $ALIASES{$name} // $name;
}

sub character_set {
    my ($class, $name) = @_;

    my $canonical = $class->canonical_name($name);
    die "Unknown grid character set '$name'\n"
        if !exists $GRID_CHARACTER_SETS{$canonical};

    my %copy = %{ $GRID_CHARACTER_SETS{$canonical} };
    return \%copy;
}

sub validate_character_set {
    my ($class, $name, $set) = @_;

    die "Grid character set '$name' must be a hash reference\n"
        if ref($set) ne 'HASH';

    for my $component (@REQUIRED_COMPONENTS) {
        die "Grid character set '$name' is missing '$component'\n"
            if !exists $set->{$component};

        die "Grid character '$name/$component' must be exactly one character\n"
            if !defined $set->{$component} || length($set->{$component}) != 1;
    }

    return 1;
}

sub validate_all {
    my ($class) = @_;

    for my $name ($class->names) {
        $class->validate_character_set($name, $GRID_CHARACTER_SETS{$name});
    }

    return 1;
}

__PACKAGE__->validate_all;

1;
