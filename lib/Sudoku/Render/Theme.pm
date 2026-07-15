package Sudoku::Render::Theme;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec ();

my @THEME_ORDER = qw(subtle bright greyscale);

my %ANSI = (
    reset          => 0,
    bold           => 1,
    dim            => 2,
    underline      => 4,
    reverse        => 7,
    black          => 30,
    red            => 31,
    green          => 32,
    yellow         => 33,
    blue           => 34,
    magenta        => 35,
    cyan           => 36,
    white          => 37,
    'bright-black' => 90,
    'bright-red'   => 91,
    'bright-green' => 92,
    'bright-yellow'=> 93,
    'bright-blue'  => 94,
    'bright-magenta'=> 95,
    'bright-cyan'  => 96,
    'bright-white' => 97,
);

sub names { return @THEME_ORDER }

sub new {
    my ($class, %args) = @_;
    my $name = lc($args{name} // 'subtle');
    die "Unknown color theme '$name'; available themes: " . join(', ', @THEME_ORDER) . "\n"
        if !grep { $_ eq $name } @THEME_ORDER;

    my $file = $args{file} // _theme_file($name);
    my $roles = _load_theme($file);
    return bless { name => $name, roles => $roles }, $class;
}

sub name { return $_[0]{name} }

sub style {
    my ($self, $role, $text) = @_;
    return q{} if !defined $text;
    my $spec = $self->{roles}{$role} // 'normal';
    return "$text" if $spec eq 'normal' || $spec eq q{};

    my @codes;
    for my $token (split /\s+/, $spec) {
        next if $token eq 'normal';
        die "Unknown ANSI style '$token' in theme '$self->{name}'\n"
            if !exists $ANSI{$token};
        push @codes, $ANSI{$token};
    }
    return "$text" if !@codes;
    return "\e[" . join(';', @codes) . "m$text\e[0m";
}

sub _theme_file {
    my ($name) = @_;
    my $module_dir = dirname(__FILE__);
    my $root = File::Spec->rel2abs(File::Spec->catdir($module_dir, '..', '..', '..'));
    return File::Spec->catfile($root, 'themes', "$name.theme");
}

sub _load_theme {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot open color theme '$file': $!\n";
    my %roles;
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/#.*\z//;
        $line =~ s/^\s+|\s+$//g;
        next if $line eq q{};
        die "Invalid theme line in '$file': $line\n"
            if $line !~ /\A([a-z][a-z0-9_]*)\s*=\s*(.*?)\s*\z/;
        $roles{$1} = $2;
    }
    close $fh;
    return \%roles;
}

1;
