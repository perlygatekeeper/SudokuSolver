#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use lib 'lib';
use Sudoku::Render::Text;

{ package Local::ResultCell; sub new { my ($c,%a)=@_; bless \%a,$c } sub value {$_[0]{value}} sub given {$_[0]{given}} }
{ package Local::ResultGrid; sub new { my ($c,@x)=@_; bless {cells=>\@x,solved=>2},$c } sub cells {$_[0]{cells}} sub solved {$_[0]{solved}} }
{ package Local::HashObject; sub new { bless $_[1],$_[0] } sub as_hash { +{%{$_[0]}} } }
{ package Local::ResultSolver;
  sub new { bless {contradiction=>$_[1]{contradiction}},$_[0] }
  sub deduction_count { 7 }
  sub has_contradiction { defined $_[0]{contradiction} }
  sub contradiction { $_[0]{contradiction} }
  sub difficulty { Local::HashObject->new({label=>'Hard',rating_version=>'2.5',score=>4}) }
  sub statistics { Local::HashObject->new({total_deductions=>7}) }
}

my @cells=(Local::ResultCell->new(value=>5,given=>1),Local::ResultCell->new(value=>3,given=>0),map {Local::ResultCell->new(value=>0,given=>0)} 3..81);
my $grid=Local::ResultGrid->new(@cells);
my $solver=Local::ResultSolver->new({});
my $r=Sudoku::Render::Text->new;
my $json=$r->result_json($solver,$grid);
my $d=decode_json($json);
is($d->{format},'SudokuSolver result','format');
is($d->{version},1,'version');
is($d->{status},'stalled','status');
is(substr($d->{puzzle},0,2),'50','givens only');
is(substr($d->{current_grid},0,2),'53','current values');
is($d->{solved_cells},2,'solved count');
is($d->{remaining_cells},79,'remaining count');
is($d->{deductions},7,'deductions');
is($d->{difficulty}{label},'Hard','difficulty');
is($d->{statistics}{total_deductions},7,'statistics');
ok(!defined $d->{solution},'no solution when stalled');
ok(!defined $d->{contradiction},'no contradiction when stalled');
is(substr($json,-1),"\n",'newline');
ok($r->supports_result_format('json'),'json supported');
is_deeply([$r->available_result_formats],['json'],'result discovery');
my $e=''; eval {$r->result_json(undef,$grid)}; $e=$@; like($e,qr/requires a solver/,'solver required');
done_testing;
