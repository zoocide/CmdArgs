# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CmdArgs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 19;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $args;

{
  package CmdArgs::Types::MyStr;
  sub check { my ($class, $val) = @_; $val eq 'correct_string' }
}

## select untyped ##
eval{
  $args = CmdArgs->declare(
    '0.1',
    use_cases => [
      second => ['arg2:', 'arg2'],
      first => ['arg1:MyStr', 'arg1'],
    ],
  );
  $args->parse(qw(correct_string_1));
};
is("$@", '');
isa_ok($args, 'CmdArgs');

## help order preservation 1 ##
eval{
  $args->parse(qw(--help));
};
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like  ("$@", qr/arg2.*arg1.*arg2.*arg1.*ABOUT/s);
unlike("$@", qr/arg1.*arg2.*arg1.*arg2.*ABOUT/s);

## help order preservation 2 ##
eval{
  $args = CmdArgs->declare(
    '0.1',
    use_cases => [
      first => ['arg1:MyStr', 'arg1'],
      second => ['arg2:', 'arg2'],
    ],
  );
  $args->parse(qw(--help));
};
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like  ("$@", qr/arg1.*arg2.*arg1.*arg2.*ABOUT/s);
unlike("$@", qr/arg2.*arg1.*arg2.*arg1.*ABOUT/s);

## hiden options ##
eval{
  $args = CmdArgs->declare(
    '1.0.1',
    options => {
      hiden => ['--hiden', undef],
      file  => ['--file'],
    }
  );
  $args->parse('--help');
};
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/--file/);
unlike("$@", qr/--hiden/);

## options action ##
my $str = 'untuched';
eval{
  $args = CmdArgs->declare(
    '1.0.1',
    options => {
      file => ['-f', '', sub {$str = 'new_str'} ],
    }
  );
  $args->parse('-f arg');
};
is("$@", '');
is($str, 'new_str');

## options action with parameter ##
$str = 'untuched';
eval{
  $args = CmdArgs->declare(
    '1.0.1',
    options => {
      file => ['-f:', undef, sub {$str = $_[0]} ],
    }
  );
  $args->parse('-f new_str2 arg');
};
is("$@", '');
is($str, 'new_str2');
