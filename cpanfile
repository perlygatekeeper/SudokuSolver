requires 'perl', '5.034';

# Object system
requires 'Moose';

# Testing
requires 'Test::More';

# PNG renderer (core on supported Perl releases)
requires 'Compress::Zlib';

# Local corpus acceleration cache
requires 'DBI';
requires 'DBD::SQLite';
