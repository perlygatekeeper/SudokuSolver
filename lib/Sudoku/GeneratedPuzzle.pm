package Sudoku::GeneratedPuzzle;

use strict;
use warnings;

use JSON::PP;
use POSIX qw(strftime);
use Scalar::Util qw(blessed);

use Sudoku;
use Sudoku::CoordinateEncoding qw(encode_puzzle);

sub new {
    my ($class, %args) = @_;

    for my $required (qw(
        canonical_record corpus_seed symmetry_seed transform puzzle solution
    )) {
        die "$required is required\n" unless exists $args{$required};
    }
    die "transform must be a Sudoku::Symmetry object\n"
        unless blessed($args{transform}) && $args{transform}->isa('Sudoku::Symmetry');
    die "canonical_record must be a master corpus record\n"
        unless ref($args{canonical_record}) eq 'HASH'
            && ref($args{canonical_record}{identity}) eq 'HASH';
    die "reveal_cells must be an array reference\n"
        if exists $args{reveal_cells} && ref($args{reveal_cells}) ne 'ARRAY';
    die "difficulty must be a hash reference\n"
        if exists $args{difficulty}
            && defined $args{difficulty}
            && ref($args{difficulty}) ne 'HASH';

    return bless {
        canonical_record  => $args{canonical_record},
        corpus_seed       => 0 + $args{corpus_seed},
        symmetry_seed     => 0 + $args{symmetry_seed},
        transform         => $args{transform},
        base_puzzle       => $args{base_puzzle} // $args{puzzle},
        puzzle            => $args{puzzle},
        solution          => $args{solution},
        reveal_seed       => $args{reveal_seed},
        reveal_cells      => [ @{ $args{reveal_cells} // [] } ],
        target_clue_count => $args{target_clue_count}
            // Sudoku::CoordinateEncoding::clue_count($args{puzzle}),
        difficulty        => $args{difficulty},
        generation_attempts => $args{generation_attempts},
        generation_date   => $args{generation_date} // _utc_now(),
        generator_version => $args{generator_version} // $Sudoku::VERSION,
    }, $class;
}

sub canonical_record  { return $_[0]->{canonical_record} }
sub corpus_seed       { return $_[0]->{corpus_seed} }
sub symmetry_seed     { return $_[0]->{symmetry_seed} }
sub transform         { return $_[0]->{transform} }
sub base_puzzle       { return $_[0]->{base_puzzle} }
sub transformed_puzzle { return $_[0]->{base_puzzle} }
sub puzzle            { return $_[0]->{puzzle} }
sub solution          { return $_[0]->{solution} }
sub reveal_seed       { return $_[0]->{reveal_seed} }
sub target_clue_count { return $_[0]->{target_clue_count} }
sub generation_attempts { return $_[0]->{generation_attempts} }
sub generation_date   { return $_[0]->{generation_date} }
sub generator_version { return $_[0]->{generator_version} }

sub reveal_cells {
    my ($self) = @_;
    return [ @{ $self->{reveal_cells} } ];
}

sub difficulty {
    my ($self) = @_;
    return unless defined $self->{difficulty};
    return { %{ $self->{difficulty} } };
}

sub canonical_id {
    my ($self) = @_;
    return $self->canonical_record->{identity}{canonical_id};
}

sub fingerprint {
    my ($self) = @_;
    return $self->canonical_record->{identity}{fingerprint};
}

sub canonical_puzzle {
    my ($self) = @_;
    return $self->canonical_record->{identity}{canonical_puzzle};
}

sub canonical_solution {
    my ($self) = @_;
    return $self->canonical_record->{solution};
}

sub transform_shorthand {
    my ($self) = @_;
    return $self->transform->serialize;
}

sub clue_count {
    my ($self) = @_;
    return Sudoku::CoordinateEncoding::clue_count($self->puzzle);
}

sub base_clue_count {
    my ($self) = @_;
    return Sudoku::CoordinateEncoding::clue_count($self->base_puzzle);
}

sub coordinate_encoding {
    my ($self) = @_;
    return encode_puzzle($self->puzzle);
}

sub base_coordinate_encoding {
    my ($self) = @_;
    return encode_puzzle($self->base_puzzle);
}

sub difficulty_label {
    my ($self) = @_;
    return unless defined $self->{difficulty};
    return $self->{difficulty}{label};
}

sub difficulty_score {
    my ($self) = @_;
    return unless defined $self->{difficulty};
    return $self->{difficulty}{score};
}

sub highest_strategy {
    my ($self) = @_;
    return unless defined $self->{difficulty};
    return $self->{difficulty}{highest_strategy};
}

sub difficulty_rating_version {
    my ($self) = @_;
    return unless defined $self->{difficulty};
    return $self->{difficulty}{rating_version};
}

sub as_hash {
    my ($self) = @_;

    my $provenance = {
        canonical_id       => $self->canonical_id,
        fingerprint        => $self->fingerprint,
        coordinate_encoding => $self->coordinate_encoding,
        corpus_seed        => $self->corpus_seed,
        symmetry_seed      => $self->symmetry_seed,
        symmetry_transform => $self->transform_shorthand,
        final_clue_count   => $self->clue_count,
        generation_date    => $self->generation_date,
        generator_version  => $self->generator_version,
    };

    if (defined $self->reveal_seed) {
        $provenance->{reveal_seed} = $self->reveal_seed;
        $provenance->{reveal_cells} = $self->reveal_cells;
        $provenance->{target_clue_count} = $self->target_clue_count;
    }

    $provenance->{generation_attempts} = $self->generation_attempts
        if defined $self->generation_attempts;

    my $hash = {
        puzzle   => $self->puzzle,
        solution => $self->solution,
        provenance => $provenance,
    };

    $hash->{base_puzzle} = $self->base_puzzle
        if $self->base_puzzle ne $self->puzzle;
    $hash->{difficulty} = $self->difficulty
        if defined $self->{difficulty};

    return $hash;
}

sub as_json {
    my ($self) = @_;
    return JSON::PP->new->canonical(1)->pretty(1)->encode($self->as_hash);
}

sub write_file {
    my ($self, $path) = @_;
    die "write_file requires a path\n" unless defined $path && length $path;

    open my $out, '>:encoding(UTF-8)', $path
        or die "Cannot create '$path': $!\n";
    print {$out} $self->as_json
        or die "Cannot write '$path': $!\n";
    close $out
        or die "Cannot close '$path': $!\n";

    return $path;
}

sub _utc_now {
    return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
}

1;
