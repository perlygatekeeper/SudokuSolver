#!/usr/bin/env perl 
# A perl script to read in, solve and output a sudoku puzzle.

use strict;
use warnings;
use v5.10;

use Grid;
use Data::Dump;

my $puzzle_strings;
my $puzzle_name;
while (<DATA>) {
  chomp;
  if (/^\s*$|^\s*#/) { # found a puzzle header
    $puzzle_name = $_;
    $puzzle_name =~ s/^\s*#\s*//;
  } else {
    $puzzle_strings->{$puzzle_name} .= $_;
  }
}

# print "puzzle_string: $puzzle_string\n";
my $puzzle = Grid->new;
$puzzle->load_from_string($puzzle_strings->{Puzzle_06});

# $puzzle->out; exit;

my($this_cell);
my($progress);
my($pass_progress) = 1;
my($pass) = 0;
# $puzzle->find_and_set_singletons;

while ( $puzzle->solved <= 80 and $pass_progress ) {
  print "==== Pass " . ++$pass . " ====\n"; $pass_progress = 0;

  # Singletons
  while ( $puzzle->solved <= 80 and $progress = $puzzle->find_and_set_singletons ) {
    print "So far we filled this many cells: " . $puzzle->solved . "\n";
    $puzzle->pretty_print;
    $puzzle->multi_column_status;
    $pass_progress += $progress;
    print "---- end singletons method ----\n\n";
  }

  # Lone Representatives
  while ( $puzzle->solved <= 80 and $progress = $puzzle->find_and_set_lone_representatives ) {
    print "So far we filled this many cells: " . $puzzle->solved . "\n";
    $puzzle->pretty_print;
    $puzzle->multi_column_status;
    $pass_progress += $progress;
    print "---- end lone representatives method ----\n\n";
  }

  # Naked Pairs
  # Naked Triplets
  # XY Wings

  print "==== End Pass " . $pass . " (progress is $pass_progress) ====\n";

}

if ( $puzzle->solved == 81 ) {
  print "We have solved this puzzle.  Final solution is:\n";
  print $_->value foreach ( @{$puzzle->cells} );
  print "\n";
} else {
  printf "We were able to determine %d cells.\n", $puzzle->solved;
}


1;
__END__
# Puzzle_01
003020600
900305001
001806400
008102900
700000008
006708200
002609500
800203009
005010300
# Puzzle_02
200080300
060070084
030500209
000105408
000000000
402706000
301007040
720040060
004010003
# Puzzle_03
000000907
000420180
000705026
100904000
050000040
000507009
920108000
034059000
507000000
# Puzzle_04
030050040
008010500
460000012
070502080
000603000
040109030
250000098
001020600
080060020
# Puzzle_05
020810740
700003100
090002805
009040087
400208003
160030200
302700060
005600008
076051090
# Puzzle_06
100920000
524010000
000000070
050008102
000000000
402700090
060000000
000030945
000071006
# Puzzle_07
043080250
600000000
000001094
900004070
000608000
010200003
820500000
000000005
034090710
# Puzzle_08
480006902
002008001
900370060
840010200
003704100
001060049
020085007
700900600
609200018
# Puzzle_09
000900002
050123400
030000160
908000000
070000090
000000205
091000050
007439020
400007000
# Puzzle_10
001900003
900700160
030005007
050000009
004302600
200000070
600100030
042007006
500006800
# Puzzle_11
000125400
008400000
420800000
030000095
060902010
510000060
000003049
000007200
001298000
# Puzzle_12
062340750
100005600
570000040
000094800
400000006
005830000
030000091
006400007
059083260
# Puzzle_13
300000000
005009000
200504000
020000700
160000058
704310600
000890100
000067080
000005437
# Puzzle_14
630000000
000500008
005674000
000020000
003401020
000000345
000007004
080300902
947100080
# Puzzle_15
000020040
008035000
000070602
031046970
200000000
000501203
049000730
000000010
800004000
# Puzzle_16
361025900
080960010
400000057
008000471
000603000
259000800
740000005
020018060
005470329
# Puzzle_17
050807020
600010090
702540006
070020301
504000908
103080070
900076205
060090003
080103040
# Puzzle_18
080005000
000003457
000070809
060400903
007010500
408007020
901020000
842300000
000100080
# Puzzle_19
003502900
000040000
106000305
900251008
070408030
800763001
308000104
000020000
005104800
# Puzzle_20
000000000
009805100
051907420
290401065
000000000
140508093
026709580
005103600
000000000
# Puzzle_21
020030090
000907000
900208005
004806500
607000208
003102900
800605007
000309000
030020050
# Puzzle_22
005000006
070009020
000500107
804150000
000803000
000092805
907006000
030400010
200000600
# Puzzle_23
040000050
001943600
009000300
600050002
103000506
800020007
005000200
002436700
030000040
# Puzzle_24
004000000
000030002
390700080
400009001
209801307
600200008
010008053
900040000
000000800
# Puzzle_25
360020089
000361000
000000000
803000602
400603007
607000108
000000000
000418000
970030014
# Puzzle_26
500400060
009000800
640020000
000001008
208000501
700500000
000090084
003000600
060003002
# Puzzle_27
007256400
400000005
010030060
000508000
008060200
000107000
030070090
200000004
006312700
# Puzzle_28
000000000
079050180
800000007
007306800
450708096
003502700
700000005
016030420
000000000
# Puzzle_29
030000080
009000500
007509200
700105008
020090030
900402001
004207100
002000800
070000090
# Puzzle_30
200170603
050000100
000006079
000040700
000801000
009050000
310400000
005000060
906037002
# Puzzle_31
000000080
800701040
040020030
374000900
000030000
005000321
010060050
050802006
080000000
# Puzzle_32
000000085
000210009
960080100
500800016
000000000
890006007
009070052
300054000
480000000
# Puzzle_33
608070502
050608070
002000300
500090006
040302050
800050003
005000200
010704090
409060701
# Puzzle_34
050010040
107000602
000905000
208030501
040070020
901080406
000401000
304000709
020060010
# Puzzle_35
053000790
009753400
100000002
090080010
000907000
080030070
500000003
007641200
061000940
# Puzzle_36
006080300
049070250
000405000
600317004
007000800
100826009
000702000
075040190
003090600
# Puzzle_37
005080700
700204005
320000084
060105040
008000500
070803010
450000091
600508007
003010600
# Puzzle_38
000900800
128006400
070800060
800430007
500000009
600079008
090004010
003600284
001007000
# Puzzle_39
000080000
270000054
095000810
009806400
020403060
006905100
017000620
460000038
000090000
# Puzzle_40
000602000
400050001
085010620
038206710
000000000
019407350
026040530
900020007
000809000
# Puzzle_41
000900002
050123400
030000160
908000000
070000090
000000205
091000050
007439020
400007000
# Puzzle_42
380000000
000400785
009020300
060090000
800302009
000040070
001070500
495006000
000000092
# Puzzle_43
000158000
002060800
030000040
027030510
000000000
046080790
050000080
004070100
000325000
# Puzzle_44
010500200
900001000
002008030
500030007
008000500
600080004
040100700
000700006
003004050
# Puzzle_45
080000040
000469000
400000007
005904600
070608030
008502100
900000005
000781000
060000010
# Puzzle_46
904200007
010000000
000706500
000800090
020904060
040002000
001607000
000000030
300005702
# Puzzle_47
000700800
006000031
040002000
024070000
010030080
000060290
000800070
860000500
002006000
# Puzzle_48
001007090
590080001
030000080
000005800
050060020
004100000
080000030
100020079
020700400
# Puzzle_49
000003017
015009008
060000000
100007000
009000200
000500004
000000020
500600340
340200000
# Puzzle_50
300200000
000107000
706030500
070009080
900020004
010800050
009040301
000702000
000008006
