# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CmdArgs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 33;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $args;

{
  package CmdArgs::Types::Word_ok;
  sub check { my ($class, $val) = @_; $val eq 'ok' }
}

### named options argument ###

## key1:<ARG> ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f:<FILE>'], },
  );
  $args->parse('-f filename arg');
};
is("$@", '');
is(eval{ $args->opt('f') }, 'filename');
eval{ $args->parse('--help') };
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/FILE/);

## key1:<ARG> key2 ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f:<FILE> --file'], },
  );
  $args->parse('--file filename arg');
};
is("$@", '');
is(eval{ $args->opt('f') }, 'filename');
eval{ $args->parse('--help') };
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/FILE/);

## key1:Type<ARG> key2 ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f:Word_ok<FILE> --file'], },
  );
  $args->parse('--file ok arg');
};
is("$@", '');
is(eval{ $args->opt('f') }, 'ok');
eval{ $args->parse('--help') };
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/FILE/);
eval{ $args->parse('--file not_ok arg') };
isnt("$@", '');
like("$@", qr/not_ok/);

## key1:<<ARG>> key2 ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f:<<FILE>> --file'], },
  );
  $args->parse('--file filename arg');
};
is("$@", '');
is(eval{ $args->opt('f') }, 'filename');
eval{ $args->parse('--help') };
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/<FILE>/);

## key1:<ARG> key2 in use_case ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f:<FILE> --file'], },
    use_cases => { main => ['f'], },
  );
  $args->parse('--file filename');
};
is("$@", '');
is(eval{ $args->opt('f') }, 'filename');
eval{ $args->parse('a') };
isnt("$@", '');
like("$@", qr/FILE/);
eval{ $args->parse('--help') };
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/FILE/);

### restrictions ###
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { o1 => ['-a'], o2 => ['-b'], o3 => ['-c'], },
    restrictions => ['o1|o2', 'o2|o3'],
  );
  $args->parse('-ac arg');
};
is("$@", '');
eval { $args->parse('-b arg') };
is("$@", '');
eval { $args->parse('-bc arg') };
isnt("$@", '');

## convert method of Types ##
