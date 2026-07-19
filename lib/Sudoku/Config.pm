package Sudoku::Config;

use strict;
use warnings;

use File::Spec;

sub new {
    my ($class, %args) = @_;

    my $file = exists $args{file} ? $args{file} : _default_file();
    return bless { file => $file }, $class;
}

sub file {
    my ($self) = @_;
    return $self->{file};
}

sub section {
    my ($self, $name) = @_;

    my $sections = $self->_read;
    my $key = _normalize_name($name);
    return %{ $sections->{$key} // {} };
}

sub defaults_for {
    my ($self, $name, @allowed) = @_;

    my %section = $self->section($name);
    return %section unless @allowed;

    my %allowed = map { _normalize_name($_) => 1 } @allowed;
    return map { $_ => $section{$_} }
        grep { $allowed{$_} }
        sort keys %section;
}

sub _read {
    my ($self) = @_;
    return $self->{sections} if exists $self->{sections};

    my $file = $self->file;
    return $self->{sections} = {} unless defined($file) && length($file);
    return $self->{sections} = {} unless -e $file;

    open my $fh, '<', $file or die "Cannot open SudokuSolver config '$file': $!\n";

    my %sections;
    my $section = 'default';
    my $line_number = 0;

    while (my $line = <$fh>) {
        ++$line_number;
        $line =~ s/\r?\n\z//;
        $line =~ s/\A\s+//;
        $line =~ s/\s+\z//;
        next if $line eq q{} || $line =~ /\A[;#]/;

        if ($line =~ /\A\[([A-Za-z0-9_-]+)\]\z/) {
            $section = _normalize_name($1);
            next;
        }

        die "Malformed SudokuSolver config '$file' line $line_number\n"
            unless $line =~ /\A([A-Za-z0-9_-]+)\s*=\s*(.*?)\s*\z/;

        my ($key, $value) = (_normalize_name($1), $2);
        $value =~ s/\A\s+//;
        $value =~ s/\s+\z//;
        $value =~ s/\A"(.*)"\z/$1/;
        $value =~ s/\A'(.*)'\z/$1/;

        $sections{$section}{$key} = $value;
    }

    close $fh or die "Cannot close SudokuSolver config '$file': $!\n";

    return $self->{sections} = \%sections;
}

sub _default_file {
    return $ENV{SUDOKU_SOLVER_CONFIG}
        if exists $ENV{SUDOKU_SOLVER_CONFIG};

    return if $ENV{HARNESS_ACTIVE};

    return unless defined($ENV{HOME}) && length($ENV{HOME});
    return File::Spec->catfile($ENV{HOME}, '.sudoku_solver');
}

sub _normalize_name {
    my ($name) = @_;
    $name = lc($name // q{});
    $name =~ tr/_/-/;
    return $name;
}

1;
