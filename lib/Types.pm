package Types;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'CellValue',
    as 'Int',
    where { $_ >= 0 && $_ <= 9 },
    message { "$_ is not an integer between 0 and 9." };

subtype 'Difficulty',
    as 'Int',
    where { $_ >= 0 && $_ <= 4 },
    message { "$_ is not an integer between 0 and 4." };

1;
