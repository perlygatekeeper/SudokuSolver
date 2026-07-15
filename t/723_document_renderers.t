#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Sudoku::Render::Text;

{ package Local::Cell; sub new { bless { value=>$_[1], given=>$_[2] }, $_[0] } sub value { $_[0]{value} } sub given { $_[0]{given} } }
{ package Local::Grid; sub new { bless { cells=>[map { Local::Cell->new($_, 1) } 1..9, map { Local::Cell->new(0,0) } 1..72] }, $_[0] } sub cells { $_[0]{cells} } }

my $grid = Local::Grid->new;
my $r = Sudoku::Render::Text->new;
for my $format (qw(markdown html svg png pdf)) {
    ok($r->supports_grid_format($format), "$format is registered");
}
like($r->render_grid($grid, format=>'markdown'), qr/^\|   \| 1 \| 2 \|/m, 'Markdown table has column headings');
like($r->render_grid($grid, format=>'html'), qr/<table class="sudoku"/, 'HTML contains Sudoku table');
like($r->render_grid($grid, format=>'html'), qr/class="given">1<\/td>/, 'HTML marks given cells');
like($r->render_grid($grid, format=>'svg'), qr/^<svg xmlns=/, 'SVG is a standalone SVG document');
like($r->render_grid($grid, format=>'svg'), qr/<text [^>]*>1<\/text>/, 'SVG contains cell values');
my $png = $r->render_grid($grid, format=>'png');
is(substr($png,0,8), "\x89PNG\r\n\x1a\n", 'PNG has standard signature');
my $pdf = $r->render_grid($grid, format=>'pdf');
like($pdf, qr/^%PDF-1\.4/, 'PDF has standard header');
like($pdf, qr/%%EOF\n\z/, 'PDF has EOF marker');
done_testing;
