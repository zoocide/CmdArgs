use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 13;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

my $args;
my $val;
my @arr;
my @common_decl = ('0', use_cases => {main => ['OPTIONS', '']});

## simple action ##
eval{
  $args = CmdArgs->declare(
    @common_decl,
    options => { opt1 => ['a','', sub {$val = $_[0]}] }
  );
  $args->parse('a');
};
is("$@", '');
is($val, 1);
undef $args;
undef $val;

## scalar ref ##
eval{
  $args = CmdArgs->declare(
    @common_decl,
    options => { opt1 => ['a','', \$val] }
  );
  $args->parse('a');
};
is("$@", '');
is($val, 1);
undef $args;
undef $val;

## array ref ##
eval{
  $args = CmdArgs->declare(
    @common_decl,
    options => { opt1 => ['a','', \@arr] }
  );
  $args->parse('a a');
};
is("$@", '');
is_deeply(\@arr, [1, 1]);
undef $args;
@arr = ();

## simple action with parameter ##
eval{
  $args = CmdArgs->declare(
    @common_decl,
    options => { opt1 => ['a:','', sub {$val = $_[0]}] }
  );
  $args->parse('a str');
};
is("$@", '');
is($val, 'str');
undef $args;
undef $val;

## scalar ref with parameter ##
eval{
  $args = CmdArgs->declare(
    @common_decl,
    options => { opt1 => ['a:','', \$val] }
  );
  $args->parse('a str');
};
is("$@", '');
is($val, 'str');
undef $args;
undef $val;

## array ref with parameter ##
eval{
  $args = CmdArgs->declare(
    @common_decl,
    options => { opt1 => ['-I:','', \@arr] }
  );
  $args->parse('-Idir1 -Idir2');
};
is("$@", '');
is_deeply(\@arr, [qw(dir1 dir2)]);
undef $args;
@arr = ();
