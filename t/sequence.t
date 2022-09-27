use strict;
use warnings;

use Test::More tests => 31;
#use constant 'CmdArgs::DEBUG_LEVEL' => 1;
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
TODO: {
  local $TODO = "~OPT is not supported yet";
  local $decl{use_cases} = {main => ['~OPT OPT']};
  check_parse(\%decl, '-opt');
  check_parse(\%decl, '-opt -opt');
}


## ~OPT? OPT ##
{
  local $decl{use_cases} = {main => ['~OPT? OPT']};
  check_parse(\%decl, '-opt');
  TODO: {
  local $TODO = "deal with ~OPT? OPT";
  check_parse(\%decl, '-opt -opt');
  }
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
  TODO: {
  local $TODO = "deal with ~OPT? OPT";
  check_parse(\%decl, '-opt -opt');
  }
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
  TODO: {
  local $TODO = "deal with ~OPT? OPT";
  check_parse(\%decl, '-opt -opt');
  }
  check_parse(\%decl, '-opt -a -opt');
  TODO: {
  local $TODO = "deal with ~OPT? OPT";
  check_parse(\%decl, '-a -opt -b -opt');
  }
}