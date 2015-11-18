use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 22;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

my $args;
my %ghelp = (ABOUT => [qw(HELP VERSION)]);
## default group OPTIONS ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b','']},
  );
};
is("$@", '');
is_deeply($args->{groups}, {%ghelp, OPTIONS => [qw(opt1 opt2)]});
undef $args;

## simple group declarations ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b','']},
    groups => {
      GROUP => [qw(opt1 opt2)],
      GR => [qw(opt2)],
    },
  );
};
is("$@", '');
is_deeply($args->{groups}, {%ghelp, GROUP => [qw(opt1 opt2)], GR => [qw(opt2)]});
undef $args;

## grop contains group and uniq options ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b',''], opt3 => ['c', ''],
                 opt4 => ['d',''], opt5 => ['e',''], opt6 => ['f', ''],},
    groups => {
      GR1 => [qw(opt4 opt2 opt1)],
      GR2 => [qw(opt3 GR1 opt1)],
    },
  );
};
is("$@", '');
#print Dumper($args->{groups});
is_deeply($args->{groups}, {%ghelp, GR1 => [qw(opt4 opt2 opt1)], GR2 => [qw(opt3 opt4 opt2 opt1)]});
undef $args;

## REVERSED: group contains group; uniq options ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b',''], opt3 => ['c', ''],
                 opt4 => ['d',''], opt5 => ['e',''], opt6 => ['f', ''],},
    groups => {
      GR2 => [qw(opt4 opt2 opt1)],
      GR1 => [qw(opt3 GR2 opt1)],
    },
  );
};
is("$@", '');
#print Dumper($args->{groups});
is_deeply($args->{groups}, {%ghelp, GR2 => [qw(opt4 opt2 opt1)], GR1 => [qw(opt3 opt4 opt2 opt1)]});
undef $args;

## cyclic references ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b',''], opt3 => ['c', ''],
                 opt4 => ['d',''], opt5 => ['e',''], opt6 => ['f', ''],},
    groups => {
      GR1 => [qw(opt3 GR2 opt1)],
      GR2 => [qw(opt4 opt2 GR3 opt1)],
      GR3 => [qw(GR1 opt5)],
    },
  );
};
like("$@", qr/cyclic/);
#print Dumper($args->{groups});
undef $args;

## ^ mark for option and group ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b',''], opt3 => ['c', ''],
                 opt4 => ['d',''], opt5 => ['e',''], opt6 => ['f', ''],},
    groups => {
      GR1 => [qw(opt1 opt2)],
      GR2 => [qw(opt1 opt3 opt4 opt2 opt5 ^GR1 ^opt3)],
    },
  );
};
is("$@", '');
#print Dumper($args->{groups});
is_deeply($args->{groups}, {%ghelp, GR2 => [qw(opt4 opt5)], GR1 => [qw(opt1 opt2)]});
undef $args;

## ^ mark: sequence test ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b',''], opt3 => ['c', ''],
                 opt4 => ['d',''], opt5 => ['e',''], opt6 => ['f', ''],},
    groups => {
      GR1 => [qw(opt1 ^opt1 opt1)],
    },
  );
};
is("$@", '');
#print Dumper($args->{groups});
is_deeply($args->{groups}, {%ghelp, GR1 => [qw(opt1)]});
undef $args;

## '*' test ##
## ^ mark for option and group ##
eval{
  $args = CmdArgs->declare(
    '0',
    options => { opt1 => ['a',''], opt2 => ['b',''], opt3 => ['c', '']},
    groups => {
      GR1 => [qw(* ^ABOUT)],
    },
  );
};
is("$@", '');
#print Dumper($args->{groups});
is_deeply($args->{groups}, {%ghelp, GR1 => [qw(opt1 opt2 opt3)]});
undef $args;

## _GROUP should not appear in help message ##
eval{
  $args = CmdArgs->declare(
    '0',
    groups => {
      _GROUP => [qw(ABOUT)],
      MY_GRP => [qw(ABOUT)],
    },
  );
  $args->parse('--help');
};
isa_ok($args, 'CmdArgs');
like("$@", qr/MY_GRP/);
unlike("$@", qr/_GROUP/);

## wrong group specification ##
eval{
  my $a = CmdArgs->declare(
    '0',
    groups => {
      GROUP => {},
    },
  );
};
like("$@", qr/GROUP/);

## unknown option specified ##
eval{
  my $a = CmdArgs->declare(
    '0',
    groups => {
      GROUP => [qw(my_opt)],
    },
  );
};
like("$@", qr/my_opt/);
like("$@", qr/GROUP/);