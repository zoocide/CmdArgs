# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CmdArgs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 22;
use CmdArgs;
use CmdArgs::BasicTypes;
ok(1); # If we made it this far, we're ok.

#########################

my $args;
## check Int ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    use_cases => { main => ['n:Int'], second => ['f:File'], },
  );
  $args->parse('10');
};
is("$@", '');
is(eval{ $args->arg('n') }, 10);
eval{ $args->parse('-- -10') };
is("$@", '');
is(eval{ $args->arg('n') }, -10);
eval{ $args->parse('1.2') };
isnt("$@", '');

## check PositiveInt ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    use_cases => { main => ['n:PositiveInt'], second => ['f:File'], },
  );
  $args->parse('10');
};
is("$@", '');
is(eval{ $args->arg('n') }, 10);
eval{ $args->parse('-- -10') };
isnt("$@", '');
eval{ $args->parse('0') };
isnt("$@", '');
eval{ $args->parse('1.2') };
isnt("$@", '');

## check NonnegativeInt ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    use_cases => { main => ['n:NonnegativeInt'], second => ['f:File'], },
  );
  $args->parse('10');
};
is("$@", '');
is(eval{ $args->arg('n') }, 10);
eval{ $args->parse('-- -10') };
isnt("$@", '');
eval{ $args->parse('0') };
is("$@", '');
is(eval{ $args->arg('n') }, 0);
eval{ $args->parse('1.2') };
isnt("$@", '');

## check Real ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    use_cases => { main => ['n:Real'], second => ['f:File'], },
  );
  $args->parse('10');
};
is("$@", '');
is(eval{ $args->arg('n') }, 10);
eval{ $args->parse('-- -1.2') };
is("$@", '');
is(eval{ $args->arg('n') }, -1.2);
eval{ $args->parse('not_a_number') };
isnt("$@", '');
