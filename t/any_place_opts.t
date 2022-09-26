# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CmdArgs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 87;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

#########################

our $args;

## ~OPTIONS args... ##
my %decl = (
  use_cases => [main => ['~OPTIONS args...', '']],
  options => {
    opt1 => ['--opt1', ''],
    opt2 => ['--opt2', ''],
    opt3 => ['--opt3', ''],
  },
);
check_parse(
  \%decl,
  'a b',
  sub {
    ok(!$args->is_opt('opt1'));
    ok(!$args->is_opt('opt2'));
    ok(!$args->is_opt('opt3'));
    is_deeply($args->arg('args'), [qw(a b)]);
  }
);
check_parse(
  \%decl,
  '--opt1 a',
  sub {
    ok($args->is_opt('opt1'));
    ok(!$args->is_opt('opt2'));
    is_deeply($args->arg('args'), [qw(a)]);
  }
);
check_parse(
  \%decl,
  'a --opt1',
  sub {
    ok($args->is_opt('opt1'));
    is_deeply($args->arg('args'), [qw(a)]);
  }
);
check_parse(
  \%decl,
  '--opt1 a --opt3 b --opt2',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    ok($args->is_opt('opt3'));
    is_deeply($args->arg('args'), [qw(a b)]);
  }
);

## ~OPTIONS ##
%decl = (
  use_cases => [main => ['~OPTIONS', '']],
  options => {
    opt1 => ['--opt1', ''],
    opt2 => ['--opt2', ''],
  },
);
check_parse(
  \%decl,
  '--opt1 --opt2',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
  }
);
check_parse(
  \%decl,
  '',
  sub {
    ok(!$args->is_opt('opt1'));
  }
);

## ~OPTIONS --mopt args... ##
%decl = (
  use_cases => [main => ['~OPTIONS mopt arg', '']],
  options => {
    opt1 => ['--opt1', ''],
    opt2 => ['--opt2', ''],
    mopt => ['--mopt', ''],
  },
  groups => {
    OPTIONS => [qw(opt1 opt2)],
  },
);
check_parse(
  \%decl,
  '--mopt a',
  sub {
    ok(!$args->is_opt('opt1'));
    is($args->arg('arg'), 'a');
  }
);
check_parse(
  \%decl,
  '--opt1 --mopt --opt2 a',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    is($args->arg('arg'), 'a');
  }
);
check_parse(
  \%decl,
  '--mopt --opt2 a --opt1',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    is($args->arg('arg'), 'a');
  }
);

## ~OPTIONS arg --mopt ##
%decl = (
  use_cases => [main => ['~OPTIONS arg mopt', '']],
  options => {
    opt1 => ['--opt1', ''],
    opt2 => ['--opt2', ''],
    mopt => ['--mopt', ''],
  },
  groups => {
    OPTIONS => [qw(opt1 opt2)],
  },
);
check_parse(
  \%decl,
  'a --mopt',
  sub {
    ok(!$args->is_opt('opt1'));
    is($args->arg('arg'), 'a');
  }
);
check_parse(
  \%decl,
  'a --opt1 --mopt --opt2',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    is($args->arg('arg'), 'a');
  }
);

## ~GR1 arg1 ~GR2 arg2 ##
%decl = (
  use_cases => [main => ['~GR1 arg1 ~GR2 arg2', '']],
  options => {
    opt1 => ['--opt1', ''],
    opt2 => ['--opt2', ''],
    opt3 => ['--opt3', ''],
  },
  groups => {
    GR1 => [qw(opt1 opt2)],
    GR2 => [qw(opt3)],
  },
);
check_parse(
  \%decl,
  'a b',
  sub {
    ok(!$args->is_opt('opt1'));
    ok(!$args->is_opt('opt3'));
    is($args->arg('arg1'), 'a');
    is($args->arg('arg2'), 'b');
  }
);
check_parse(
  \%decl,
  '--opt1 a --opt3 b',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt3'));
    is($args->arg('arg1'), 'a');
    is($args->arg('arg2'), 'b');
  }
);
check_parse(
  \%decl,
  'a --opt1 --opt3 b',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt3'));
    is($args->arg('arg1'), 'a');
    is($args->arg('arg2'), 'b');
  }
);
check_parse(
  \%decl,
  'a b --opt1 --opt3 --opt2',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    ok($args->is_opt('opt3'));
    is($args->arg('arg1'), 'a');
    is($args->arg('arg2'), 'b');
  }
);

## ~mopt ~OPTS arg1 ##
%decl = (
  use_cases => [main => ['~mopt? ~OPTS arg', '']],
  options => {
    mopt => ['--mopt', ''],
    opt2 => ['--opt2', ''],
    opt3 => ['--opt3', ''],
  },
  groups => {
    OPTS => [qw(opt2 opt3)],
  },
);
check_parse(
  \%decl,
  'a',
  sub {
    ok(!$args->is_opt('mopt'));
    ok(!$args->is_opt('opt3'));
    is($args->arg('arg'), 'a');
  }
);
check_parse(
  \%decl,
  'a --opt3 --mopt',
  sub {
    ok($args->is_opt('mopt'));
    ok($args->is_opt('opt3'));
    is($args->arg('arg'), 'a');
  }
);


sub check_parse
{
  my ($decl, $str, $prove) = @_;
  local our $args = eval { CmdArgs->declare('0.1', %$decl) };
  is("$@", '', "decl: $str");
  if ($args) {
    eval { $args->parse($str) };
    is("$@", '', "parse: $str");
    $prove->();
  }
}

sub check_parse_fail
{
  my ($decl, $str, $prove) = @_;
  local our $args = eval { CmdArgs->declare('0.1', %$decl) };
  is("$@", '', "decl: $str");
  if ($args) {
    eval { $args->parse($str) };
    isnt("$@", '', "parse fail: $str");
  }
}
