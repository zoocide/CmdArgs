# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CmdArgs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 43;
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
  use_cases => [main => ['~OPTIONS mopt args...', '']],
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
  '--mopt a b',
  sub {
    ok(!$args->is_opt('opt1'));
    is_deeply($args->arg('args'), [qw(a b)]);
  }
);
check_parse(
  \%decl,
  '--opt1 --mopt --opt2 a b',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    is_deeply($args->arg('args'), [qw(a b)]);
  }
);
check_parse(
  \%decl,
  '--mopt a --opt2 b --opt1',
  sub {
    ok($args->is_opt('opt1'));
    ok($args->is_opt('opt2'));
    is_deeply($args->arg('args'), [qw(a b)]);
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
