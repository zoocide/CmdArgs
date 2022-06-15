use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 15;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

my $args;

eval{
  $args = CmdArgs->declare(
    '0',
    use_cases => [ main => ['OPTIONS', ''], ],
    options => { opt1 => ['a'], opt2 => ['b'], opt3 => ['c'], }
  );
  $args->parse_begin;
  $args->parse_part([qw(a b)]);
  $args->parse_end;
};
is("$@", '');
ok($args->is_opt('opt1'));
ok($args->is_opt('opt2'));
ok(!$args->is_opt('opt3'));

eval{
  $args = CmdArgs->declare(
    '0',
    use_cases => [ main => ['~OPTIONS args...', ''], ],
    options => { opt1 => ['a'], opt2 => ['b'], opt3 => ['c'], }
  );
  $args->parse_begin;
  $args->parse_part([qw(a arg1)]);
  $args->parse_part([qw(c arg2)]);
  $args->parse_end;
};
is("$@", '');
ok($args->is_opt('opt1'));
ok(!$args->is_opt('opt2'));
ok($args->is_opt('opt3'));
is_deeply($args->arg('args'), [qw(arg1 arg2)]);

## check reset '--' state ##
eval{
  $args = CmdArgs->declare(
    '0',
    use_cases => [ main => ['~OPTIONS args...', ''], ],
    options => { opt1 => ['a'], opt2 => ['b'], opt3 => ['c'], }
  );
  $args->parse_begin;
  $args->parse_part([qw(a arg1 -- b)]);
  $args->parse_part([qw(c arg2)]);
  $args->parse_end;
};
is("$@", '');
ok($args->is_opt('opt1'));
ok(!$args->is_opt('opt2'));
ok($args->is_opt('opt3'));
is_deeply($args->arg('args'), [qw(arg1 b arg2)]);
