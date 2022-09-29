use strict;
use warnings;

use Test::More tests => 61;
#use constant 'CmdArgs::DEBUG_LEVEL' => 2;
use CmdArgs;
use FindBin;
use lib "$FindBin::Bin/lib";
use CmdArgsTest;
ok(1); # If we made it this far, we're ok.

our $args;
my %decl = (
  options => {OPT => ['-opt']},
  groups => {GROUP => [qw(OPT)]},
);

## OPT OPT ##
{
  local $decl{use_cases} = {main => ['OPT OPT']};
  check_parse(\%decl, '-opt -opt');
}

## OPT? OPT ##
{
  local $decl{use_cases} = {main => ['OPT? OPT']};
  check_parse(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
  check_parse_fail(\%decl, '-opt -opt -opt');
}

## ~OPT OPT ##
{
  local $decl{use_cases} = {main => ['~OPT OPT']};
  check_parse_fail(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
}


## ~OPT? OPT ##
{
  local $decl{use_cases} = {main => ['~OPT? OPT']};
  check_parse(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
}


## GROUP OPT ##
{
  local $decl{use_cases} = {main => ['GROUP OPT']};
  check_parse(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
}

## ~GROUP OPT ##
{
  local $decl{use_cases} = {main => ['~GROUP OPT']};
  check_parse(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
}

## ~OPT ~OPT OPT ##
{
  local $decl{use_cases} = {main => ['~OPT ~OPT OPT']};
  check_parse_fail(\%decl, '-opt');
  check_parse_fail(\%decl, '-opt -opt');
  check_parse(\%decl, '-opt -opt -opt');
  check_parse(\%decl, '-opt -opt -opt -opt');
}

## ~OPT ~OPT? OPT ##
{
  local $decl{use_cases} = {main => ['~OPT ~OPT? OPT']};
  check_parse_fail(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
  check_parse(\%decl, '-opt -opt -opt');
  check_parse(\%decl, '-opt -opt -opt -opt');
}

## ~GR1 GR2 OPT ##
%decl = (
  use_cases => {main => ['~GR1 GR2 OPT']},
  options => {
    OPT => ['-opt'],
    a => ['-a'],
    b => ['-b'],
  },
  groups => {
    GR1 => [qw(OPT)],
    GR2 => [qw(a b)],
  },
);
{
  check_parse(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
  check_parse(\%decl, '-opt -a -opt');
  check_parse(\%decl, '-a -opt -b -opt');
}

## ~OPT arg ##
{
  local $decl{use_cases} = {main => ['~OPT arg']};
  check_parse(\%decl, '-opt arg');
  check_parse(\%decl, 'arg -opt');
  check_parse_fail(\%decl, 'arg');
}

## ~OPT args... ##
{
  local $decl{use_cases} = {main => ['~OPT args...']};
  check_parse(\%decl, '-opt arg');
  check_parse(\%decl, 'arg1 -opt arg2');
  check_parse_fail(\%decl, 'arg');
}
