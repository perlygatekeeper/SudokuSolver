package Sudoku::Render::Text;

use strict;
use warnings;

use JSON::PP ();

use Sudoku::Render::GridCharacters;
use Sudoku::Render::GridBuilder;
use Sudoku::Render::Document;
use Sudoku::Render::Theme;

my @RESULT_FORMAT_ORDER = qw(json csv tsv);

my @GRID_FORMAT_ORDER = qw(
    pretty compact markdown html svg png pdf puzzle-line grid-line solution-line
    candidates candidate-list candidate-line candidate-json
);
my %GRID_FORMAT_METHOD = (
    pretty  => 'pretty_grid',
    compact         => 'compact_grid',
    markdown        => 'markdown_grid',
    html            => 'html_grid',
    svg             => 'svg_grid',
    png             => 'png_grid',
    pdf             => 'pdf_grid',
    'puzzle-line'   => 'puzzle_line',
    'grid-line'     => 'grid_line',
    'solution-line' => 'solution_line',
    candidates     => 'candidate_grid',
    'candidate-list' => 'candidate_list',
    'candidate-line' => 'candidate_line',
    'candidate-json' => 'candidate_json',
);

sub new {
    my ($class, %args) = @_;
    $args{mode} //= 'normal';
    $args{character_set} = Sudoku::Render::GridCharacters->canonical_name(
        $args{character_set},
    );
    $args{grid_characters} = Sudoku::Render::GridCharacters->character_set(
        $args{character_set},
    );
    $args{color} //= 'never';
    $args{color_theme} //= 'subtle';
    $args{theme} = Sudoku::Render::Theme->new(name => $args{color_theme});

    return bless \%args, $class;
}


sub character_set {
    my ($self) = @_;
    return $self->{character_set};
}

sub grid_characters {
    my ($self) = @_;

    my %copy = %{ $self->{grid_characters} };
    return \%copy;
}

sub available_color_themes {
    return Sudoku::Render::Theme->names;
}

sub color {
    my ($self, $value) = @_;
    $self->{color} = $value if @_ > 1;
    return $self->{color};
}

sub color_theme {
    my ($self) = @_;
    return $self->{theme}->name;
}

sub style {
    my ($self, $role, $text) = @_;
    return $text if !$self->{color_enabled};
    return $self->{theme}->style($role, $text);
}

sub color_enabled {
    my ($self, $value) = @_;
    $self->{color_enabled} = $value ? 1 : 0 if @_ > 1;
    return $self->{color_enabled} ? 1 : 0;
}

sub available_character_sets {
    return Sudoku::Render::GridCharacters->names;
}

sub available_grid_formats {
    return @GRID_FORMAT_ORDER;
}

sub default_grid_format {
    return 'pretty';
}

sub available_result_formats {
    return @RESULT_FORMAT_ORDER;
}

sub supports_result_format {
    my ($self, $format) = @_;
    return defined $format && grep { $_ eq $format } @RESULT_FORMAT_ORDER;
}

sub render_result {
    my ($self, $solver, $grid, %args) = @_;

    my $format = delete $args{format};
    $format //= 'json';

    if (!$self->supports_result_format($format)) {
        my $available = join ', ', $self->available_result_formats;
        die "Unknown result format '$format'; available formats: $available\n";
    }

    my $method = "result_$format";
    return $self->$method($solver, $grid, %args);
}

sub result_json {
    my ($self, $solver, $grid) = @_;
    my $document = $self->_result_document($solver, $grid);
    return JSON::PP->new->canonical(1)->pretty(1)->encode($document);
}

sub result_csv {
    my ($self, $solver, $grid) = @_;
    return $self->_result_delimited($solver, $grid, q{,});
}

sub result_tsv {
    my ($self, $solver, $grid) = @_;
    return $self->_result_delimited($solver, $grid, "\t");
}

sub _result_delimited {
    my ($self, $solver, $grid, $delimiter) = @_;

    my $document = $self->_result_document($solver, $grid);
    my @columns = qw(
        status puzzle current_grid solution solved_cells remaining_cells
        deductions difficulty_label difficulty_score difficulty_rating_version
        statistics_json contradiction_kind contradiction_message
        contradiction_location contradiction_explanation
    );

    my %values = (
        status                    => $document->{status},
        puzzle                    => $document->{puzzle},
        current_grid              => $document->{current_grid},
        solution                  => $document->{solution},
        solved_cells              => $document->{solved_cells},
        remaining_cells           => $document->{remaining_cells},
        deductions                => $document->{deductions},
        difficulty_label          => $document->{difficulty}{label},
        difficulty_score          => $document->{difficulty}{score},
        difficulty_rating_version => $document->{difficulty}{rating_version},
        statistics_json           => JSON::PP->new->canonical(1)->encode(
            $document->{statistics},
        ),
        contradiction_kind        => $document->{contradiction}
            ? $document->{contradiction}{kind} : undef,
        contradiction_message     => $document->{contradiction}
            ? $document->{contradiction}{message} : undef,
        contradiction_location    => $document->{contradiction}
            ? $document->{contradiction}{location} : undef,
        contradiction_explanation => $document->{contradiction}
            ? $document->{contradiction}{explanation} : undef,
    );

    my $header = join $delimiter, map {
        _delimited_field($_, $delimiter)
    } @columns;
    my $row = join $delimiter, map {
        _delimited_field($values{$_}, $delimiter)
    } @columns;

    return "$header\n$row\n";
}

sub _delimited_field {
    my ($value, $delimiter) = @_;
    $value = q{} if !defined $value;
    $value = "$value";

    if ($delimiter eq q{,}) {
        $value =~ s/"/""/g;
        return qq{"$value"} if $value =~ /[",\r\n]/;
        return $value;
    }

    $value =~ s/\\/\\\\/g;
    $value =~ s/\t/\\t/g;
    $value =~ s/\r/\\r/g;
    $value =~ s/\n/\\n/g;
    return $value;
}

sub _result_document {
    my ($self, $solver, $grid) = @_;

    die "result output requires a solver object\n"
        if !defined $solver || !$solver->can('deduction_count');
    die "result output requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $cells = $grid->cells;
    die "result output requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;

    my $status = $solver->has_contradiction ? 'contradiction'
        : $grid->solved == 81 ? 'solved'
        : 'stalled';

    my $puzzle = join q{}, map {
        $_->can('given') && $_->given ? ($_->value || 0) : 0
    } @$cells;
    my $current_grid = join q{}, map { $_->value || 0 } @$cells;
    my $difficulty = $solver->difficulty;
    my $statistics = $solver->statistics;

    my $document = {
        format          => 'SudokuSolver result',
        version         => 1,
        status          => $status,
        puzzle          => $puzzle,
        current_grid    => $current_grid,
        solved_cells    => 0 + $grid->solved,
        remaining_cells => 81 - $grid->solved,
        deductions      => 0 + $solver->deduction_count,
        difficulty      => $difficulty->as_hash,
        statistics      => $statistics->as_hash,
        solution        => $status eq 'solved' ? $current_grid : undef,
        contradiction   => undef,
    };

    if ($status eq 'contradiction') {
        my $contradiction = $solver->contradiction;
        $document->{contradiction} = {
            kind        => $contradiction->kind,
            message     => $contradiction->message,
            location    => $contradiction->location,
            explanation => $contradiction->explanation,
        };
    }

    return $document;
}


sub supports_grid_format {
    my ($self, $format) = @_;
    return defined $format && exists $GRID_FORMAT_METHOD{$format};
}

sub render_grid {
    my ($self, $grid, %args) = @_;

    my $format = delete $args{format};
    $format = $self->default_grid_format if !defined $format;

    if (!$self->supports_grid_format($format)) {
        my $available = join ', ', $self->available_grid_formats;
        die "Unknown grid format '$format'; available formats: $available\n";
    }

    my $method = $GRID_FORMAT_METHOD{$format};
    return $self->$method($grid, %args);
}

sub markdown_grid { return Sudoku::Render::Document->new->markdown($_[1]) }
sub html_grid     { return Sudoku::Render::Document->new->html($_[1]) }
sub svg_grid      { return Sudoku::Render::Document->new->svg($_[1]) }
sub png_grid      { return Sudoku::Render::Document->new->png($_[1]) }
sub pdf_grid      { return Sudoku::Render::Document->new->pdf($_[1]) }

sub grid_builder {
    my ($self) = @_;

    return Sudoku::Render::GridBuilder->new(
        character_set => $self->{character_set},
    );
}

sub puzzle_line {
    my ($self, $grid, %args) = @_;
    my $empty = _line_empty_character(%args);
    my $cells = _line_cells($grid, 'puzzle_line');

    return join(q{}, map {
        $_->can('given') && $_->given ? ($_->value || $empty) : $empty
    } @$cells) . "\n";
}

sub grid_line {
    my ($self, $grid, %args) = @_;
    my $empty = _line_empty_character(%args);
    my $cells = _line_cells($grid, 'grid_line');

    return join(q{}, map { $_->value || $empty } @$cells) . "\n";
}

sub solution_line {
    my ($self, $grid) = @_;
    my $cells = _line_cells($grid, 'solution_line');

    die "solution_line requires a solved grid\n"
        if grep { !$_->value } @$cells;

    return join(q{}, map { $_->value } @$cells) . "\n";
}

sub _line_cells {
    my ($grid, $context) = @_;
    die "$context requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $cells = $grid->cells;
    die "$context requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;
    return $cells;
}

sub _line_empty_character {
    my (%args) = @_;
    my $empty = exists $args{empty_cell_character}
        ? $args{empty_cell_character}
        : '0';
    die "empty_cell_character must be exactly one character\n"
        if !defined $empty || length($empty) != 1;
    return $empty;
}

sub compact_grid {
    my ($self, $grid, %args) = @_;

    die "compact_grid requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $empty = exists $args{empty_cell_character}
        ? $args{empty_cell_character}
        : '.';

    die "empty_cell_character must be exactly one character\n"
        if !defined $empty || length($empty) != 1;

    my $cells = $grid->cells;

    die "compact_grid requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;

    my @values = map {
        my $value = $_->value;
        $value ? $value : $empty;
    } @$cells;

    my @rows;
    for my $row (0 .. 8) {
        push @rows, join q{}, @values[$row * 9 .. $row * 9 + 8];
    }

    return join("\n", @rows) . "\n";
}


sub candidate_list {
    my ($self, $grid) = @_;

    die "candidate_list requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $cells = $grid->cells;
    die "candidate_list requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;

    my @fields = map { _candidate_field($_) } @$cells;
    my @rows;

    for my $row (0 .. 8) {
        push @rows, sprintf(
            'R%d: %s',
            $row + 1,
            join(q{ }, @fields[$row * 9 .. $row * 9 + 8]),
        );
    }

    return join("\n", @rows) . "\n";
}

sub candidate_line {
    my ($self, $grid) = @_;

    die "candidate_line requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $cells = $grid->cells;
    die "candidate_line requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;

    return join(q{,}, map { _candidate_field($_, 'candidate_line') } @$cells)
        . "\n";
}

sub candidate_json {
    my ($self, $grid) = @_;

    die "candidate_json requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $cells = $grid->cells;
    die "candidate_json requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;

    my @candidates = map { _candidate_field($_, 'candidate_json') } @$cells;
    my $current_grid = join q{}, map { $_->value || 0 } @$cells;
    my $puzzle = join q{}, map {
        $_->can('given') && $_->given ? ($_->value || 0) : 0
    } @$cells;

    my $document = {
        format       => 'SudokuSolver candidate-state',
        version      => 1,
        puzzle       => $puzzle,
        current_grid => $current_grid,
        candidates   => \@candidates,
    };

    return JSON::PP->new
        ->canonical(1)
        ->pretty(1)
        ->encode($document);
}

sub _candidate_field {
    my ($cell, $context) = @_;
    $context //= 'candidate_list';

    my $value = $cell->value;
    return $value if $value;

    die "$context cells must provide possibilities\n"
        if !$cell->can('possibilities');

    my $possibilities = $cell->possibilities;
    die "$context possibilities must be an array reference\n"
        if ref($possibilities) ne 'ARRAY';

    my $field = join q{}, grep { $possibilities->[$_] } 1 .. 9;
    return length($field) ? $field : '-';
}

sub candidate_grid {
    my ($self, $grid) = @_;

    die "candidate_grid requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $cells = $grid->cells;
    die "candidate_grid requires exactly 81 cells\n"
        if ref($cells) ne 'ARRAY' || @$cells != 81;

    my $builder = $self->grid_builder;
    my $chars   = $builder->characters;
    my @separators = map {
        $_ == 2 || $_ == 5 ? 'vertical' : 'vertical_minor'
    } 0 .. 7;

    my $major_rule = $builder->horizontal_rule(
        left          => 'corner_down_right',
        junction      => 'tee_down',
        right         => 'corner_down_left',
        segments      => 9,
        segment_width => 7,
    );

    my $middle_major_rule = $builder->horizontal_rule(
        left          => 'tee_right',
        junction      => 'cross',
        right         => 'tee_left',
        segments      => 9,
        segment_width => 7,
    );

    my $bottom_rule = $builder->horizontal_rule(
        left          => 'corner_up_right',
        junction      => 'tee_up',
        right         => 'corner_up_left',
        segments      => 9,
        segment_width => 7,
    );

    my $minor_segment = ' ' . ($chars->{horizontal} x 5) . ' ';
    my $minor_rule = $chars->{tee_right}
        . join($chars->{cross}, ($minor_segment) x 9)
        . $chars->{tee_left};

    my @lines = (
        ' ' x 79,
        '        1       2       3       4       5       6       7       8       9      ',
        '    ' . $major_rule . '  ',
    );

    for my $row (0 .. 8) {
        my @row_cells = @{$cells}[$row * 9 .. $row * 9 + 8];

        for my $candidate_row (0 .. 2) {
            my @contents = map {
                _candidate_cell_line($_, $candidate_row)
            } @row_cells;

            my $prefix = $candidate_row == 1
                ? sprintf('  %d ', $row + 1)
                : '    ';

            push @lines, $prefix . $builder->row(
                cells      => \@contents,
                width      => 7,
                align      => 'left',
                separators => \@separators,
            ) . '  ';
        }

        if ($row == 8) {
            push @lines, '    ' . $bottom_rule . '  ';
        }
        elsif ($row == 2 || $row == 5) {
            push @lines, '    ' . $middle_major_rule . '  ';
        }
        else {
            push @lines, '    ' . $minor_rule . '  ';
        }
    }

    return join("\n", @lines) . "\n";
}

sub _candidate_cell_line {
    my ($cell, $candidate_row) = @_;

    my @slots = (' ') x 7;
    my $value = $cell->value;

    if ($value) {
        $slots[3] = $value if $candidate_row == 1;
        return join q{}, @slots;
    }

    die "candidate_grid cells must provide possibilities\n"
        if !$cell->can('possibilities');

    my $possibilities = $cell->possibilities;
    die "candidate_grid possibilities must be an array reference\n"
        if ref($possibilities) ne 'ARRAY';

    my $first = $candidate_row * 3 + 1;
    for my $offset (0 .. 2) {
        my $candidate = $first + $offset;
        $slots[1 + ($offset * 2)] = $candidate
            if $possibilities->[$candidate];
    }

    return join q{}, @slots;
}

sub pretty_grid {
    my ($self, $grid) = @_;

    return $self->_mixed_pretty_grid($grid)
        if $self->character_set eq 'UNICODE_MIXED';

    die "pretty_grid requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $builder = $self->grid_builder;
    my $chars   = $builder->characters;
    my @values  = map {
        $_->value
            ? $self->style($_->can('given') && $_->given ? 'given' : 'solved', $_->value)
            : $self->style('empty', q{})
    } @{ $grid->cells };
    my @separators = map {
        $_ == 2 || $_ == 5 ? 'vertical' : 'vertical_minor'
    } 0 .. 7;

    my $top_rule = $builder->horizontal_rule(
        left          => 'corner_down_right',
        junction      => 'tee_down',
        right         => 'corner_down_left',
        segments      => 9,
        segment_width => 3,
    );

    my $middle_rule = $builder->horizontal_rule(
        left          => 'tee_right',
        junction      => 'cross',
        right         => 'tee_left',
        segments      => 9,
        segment_width => 3,
    );

    my $bottom_rule = $builder->horizontal_rule(
        left          => 'corner_up_right',
        junction      => 'tee_up',
        right         => 'corner_up_left',
        segments      => 9,
        segment_width => 3,
    );

    my $minor_segment = ' ' . $chars->{horizontal} . ' ';
    my $minor_rule = $chars->{tee_right}
        . join($chars->{cross}, ($minor_segment) x 9)
        . $chars->{tee_left};

    my @lines = (
        '     1   2   3   4   5   6   7   8   9  ',
        '   ' . $top_rule,
    );

    for my $row (0 .. 8) {
        my @row_values = @values[$row * 9 .. $row * 9 + 8];
        push @lines, sprintf(
            '%2d %s',
            $row + 1,
            $builder->row(
                cells      => \@row_values,
                width      => 3,
                separators => \@separators,
            ),
        );

        if ($row == 8) {
            push @lines, '   ' . $bottom_rule;
        }
        elsif ($row == 2 || $row == 5) {
            push @lines, '   ' . $middle_rule;
        }
        else {
            push @lines, '   ' . $minor_rule;
        }
    }

    return join("\n", @lines) . "\n";
}

sub _mixed_pretty_grid {
    my ($self, $grid) = @_;
    die "pretty_grid requires a grid object\n"
        if !defined $grid || !$grid->can('cells');

    my $c = $self->grid_characters;
    my @values = map {
        $_->value
            ? $self->style($_->can('given') && $_->given ? 'given' : 'solved', $_->value)
            : $self->style('empty', q{})
    } @{ $grid->cells };

    my $top = $c->{corner_down_right}
        . join(q{}, map { ($c->{horizontal} x 3) . ($_ == 8 ? q{} : ($_ == 2 || $_ == 5 ? $c->{tee_down} : $c->{top_minor})) } 0 .. 8)
        . $c->{corner_down_left};
    my $bottom = $c->{corner_up_right}
        . join(q{}, map { ($c->{horizontal} x 3) . ($_ == 8 ? q{} : ($_ == 2 || $_ == 5 ? $c->{tee_up} : $c->{bottom_minor})) } 0 .. 8)
        . $c->{corner_up_left};
    my $minor = $c->{minor_left}
        . join(q{}, map { ($c->{horizontal_minor} x 3) . ($_ == 8 ? q{} : ($_ == 2 || $_ == 5 ? $c->{minor_major_cross} : $c->{minor_cross})) } 0 .. 8)
        . $c->{minor_right};
    my $major = $c->{tee_right}
        . join(q{}, map { ($c->{horizontal} x 3) . ($_ == 8 ? q{} : ($_ == 2 || $_ == 5 ? $c->{cross} : $c->{major_minor_cross})) } 0 .. 8)
        . $c->{tee_left};

    my @lines = ('     1   2   3   4   5   6   7   8   9  ', '   ' . $top);
    for my $row (0 .. 8) {
        my @v = @values[$row * 9 .. $row * 9 + 8];
        my $line = $c->{vertical};
        for my $col (0 .. 8) {
            my $display = $v[$col] // q{};
            my $visible = $display;
            $visible =~ s/\e\[[0-9;]*m//g;
            $line .= ' ' . $display . (' ' x (2 - length($visible)));
            $line .= $col == 8 ? $c->{vertical}
                : ($col == 2 || $col == 5 ? $c->{vertical} : $c->{vertical_minor});
        }
        push @lines, sprintf('%2d %s', $row + 1, $line);
        push @lines, '   ' . ($row == 8 ? $bottom : ($row == 2 || $row == 5 ? $major : $minor));
    }
    return join("\n", @lines) . "\n";
}

sub mode {
    my ($self, $mode) = @_;
    $self->{mode} = $mode if @_ > 1;
    return $self->{mode};
}

sub pass_start {
    my ($self, $pass) = @_;

    my $title = $self->style('heading', "Pass $pass");
    return $title . "\n" . ('-' x (5 + length($pass))) . "\n";
}

sub pass_end {
    my ($self, $pass, $progress) = @_;

    return sprintf "End Pass %d: %s\n\n",
        $pass,
        $progress ? "applied $progress deduction" . ($progress == 1 ? q{} : 's') : 'no progress';
}

sub strategy_result {
    my ($self, $strategy_name, $count) = @_;

    return sprintf "    %s: %s\n",
        $self->style('strategy', $strategy_name),
        $count ? "applied $count deduction" . ($count == 1 ? q{} : 's') : 'no deductions';
}

sub restart_notice {
    my ($self) = @_;
    return "    " . $self->style('subheading', 'Restarting from Naked Singles.') . "\n";
}

sub deduction {
    my ($self, $deduction) = @_;

    my $title = $self->deduction_title($deduction);
    my @lines = ($self->style('strategy', $title));

    if (($deduction->action // q{}) eq 'set_value') {
        push @lines, sprintf '    Set %s = %s',
            $self->deduction_location($deduction),
            $deduction->has_value ? $deduction->value : '?';
    }
    elsif (($deduction->action // q{}) eq 'remove_candidate') {
        push @lines, sprintf '    Remove candidate %s from %s',
            $deduction->has_value ? $deduction->value : '?',
            $self->deduction_location($deduction);
    }
    else {
        push @lines, sprintf '    Action: %s', $deduction->action // 'unknown';
    }

    push @lines, '    Why: ' . $deduction->reason
        if length($deduction->reason // q{});

    if (length($deduction->explanation // q{})
        && $deduction->explanation ne $deduction->reason) {
        push @lines, '    Detail: ' . $deduction->explanation;
    }

    return join("\n", @lines) . "\n";
}

sub deduction_title {
    my ($self, $deduction) = @_;

    if (($deduction->strategy // q{}) eq 'Hidden Singles') {
        my $unit = $deduction->can('unit_label') ? $deduction->unit_label : q{};
        return length($unit) ? "Hidden Single in $unit:" : 'Hidden Single:';
    }

    return ($deduction->strategy // 'Deduction') . ':';
}

sub deduction_location {
    my ($self, $deduction) = @_;

    return $deduction->location if $deduction->can('location') && $deduction->location;
    return 'unknown cell';
}

sub debug_grid_header {
    my ($self, $deduction_number) = @_;

    return sprintf "Grid after deduction %d:\n", $deduction_number;
}

sub final_status {
    my ($self, $solver, $grid) = @_;

    my $deductions = $solver->deduction_count;
    my $difficulty = $solver->difficulty;

    if ($solver->has_contradiction) {
        return join q{},
            $self->style('error', "Contradiction") . "\n",
            "-------------\n",
            $solver->contradiction->summary . "\n",
            sprintf("Solved cells: %d / 81\n", $grid->solved),
            sprintf("Deductions applied: %d\n", $deductions),
            sprintf("Difficulty so far: %s (method v%s)\n",
                $difficulty->label, $difficulty->rating_version);
    }

    if ($grid->solved == 81) {
        my $solution = join q{}, map { $_->value } @{ $grid->cells };
        return join q{},
            $self->style('success', "Solved") . "\n",
            "------\n",
            sprintf("Solved all 81 cells in %d deduction%s.\n",
                $deductions, $deductions == 1 ? q{} : 's'),
            sprintf("Difficulty: %s (method v%s)\n",
                $difficulty->label, $difficulty->rating_version),
            "Solution: $solution\n";
    }

    return join q{},
        $self->style('warning', "Stalled") . "\n",
        "-------\n",
        sprintf("Solved cells: %d / 81\n", $grid->solved),
        sprintf("Remaining cells: %d\n", 81 - $grid->solved),
        sprintf("Deductions applied: %d\n", $deductions),
        sprintf("Difficulty so far: %s (method v%s)\n",
            $difficulty->label, $difficulty->rating_version),
        "Puzzle state: " . $grid->as_puzzle_string . "\n",
        "No registered strategy can make further progress.\n";
}

1;
