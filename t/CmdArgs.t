# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CmdArgs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 165;
use CmdArgs;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $args;
local @ARGV;

{
  package CmdArgs::Types::Word_ok;
  sub check
  {
    my ($class, $val) = @_;
    $val eq 'ok'
  }
}

## check interface and parse 2 arguments ##
undef $args;
@ARGV = qw(arg_1 arg_2);
eval{
  $args = CmdArgs->declare(
    '3.0',
    # main = ['OPTIONS args...'],
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
can_ok($args, 'opt');
can_ok($args, 'opts');
can_ok($args, 'is_opt');
can_ok($args, 'arg');
can_ok($args, 'args');
can_ok($args, 'use_case');
is($args->opt('not_existed'), undef);
is(ref $args->arg('args'), 'ARRAY');
cmp_ok(eval{$#{$args->arg('args')}}, '==', 1);
is(eval{${$args->arg('args')}[0]}, 'arg_1');
is(eval{${$args->arg('args')}[1]}, 'arg_2');

## one option and argument ##
undef $args;
@ARGV = qw(-v arg_1);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
    },
    # main = ['OPTIONS args...'],
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is($args->opt('not_existed'), undef);
ok($args->is_opt('verb'));
is($args->opt('verb'), 1);
is(ref $args->arg('args'), 'ARRAY');
cmp_ok(eval{$#{$args->arg('args')}}, '==', 0);
is(eval{${$args->arg('args')}[0]}, 'arg_1');

## flag and option with parameter ##
undef $args;
@ARGV = qw(--verbose -f filename arg);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      file => ['-f:', 'specify filename'],
    },
    # main = ['OPTIONS args...'],
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is($args->opt('not_existed'), undef);
ok($args->is_opt('verb'));
is($args->opt('verb'), 1);
ok($args->is_opt('file'));
is($args->opt('file'), 'filename');
is(ref $args->arg('args'), 'ARRAY');
cmp_ok(eval{$#{$args->arg('args')}}, '==', 0);

## no options ##
undef $args;
@ARGV = qw(arg);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      file => ['-f:', 'specify filename'],
    },
    # main = ['OPTIONS args...'],
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is($args->opt('not_existed'), undef);
ok(!$args->is_opt('verb'));
is($args->opt('verb'), undef);
ok(!$args->is_opt('file'));
is($args->opt('file'), undef);
is(ref $args->arg('args'), 'ARRAY');
cmp_ok(eval{$#{$args->arg('args')}}, '==', 0);

## no options no arguments ##
undef $args;
@ARGV = qw();
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      file => ['-f:', 'specify filename'],
    },
    use_cases => {
      main => ['args...?', ''],
    },
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is($args->opt('not_existed'), undef);
ok(!$args->is_opt('verb'));
is($args->opt('verb'), undef);
ok(!$args->is_opt('file'));
is($args->opt('file'), undef);
is(ref $args->arg('args'), 'ARRAY');
cmp_ok(eval{$#{$args->arg('args')}}, '==', -1);

## different simple arguments ##
undef $args;
@ARGV = qw(a_1 a_2);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      file => ['-f:', 'specify filename'],
    },
    use_cases => {
      main => ['arg1 arg2', ''],
    },
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is($args->opt('not_existed'), undef);
is($args->arg('args'), undef);
is($args->arg('arg1'), 'a_1');
is($args->arg('arg2'), 'a_2');

## optional argument ##
undef $args;
@ARGV = qw(a_2);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      file => ['-f:', 'specify filename'],
    },
    use_cases => {
      main => ['arg1? arg2', ''],
    },
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is($args->opt('not_existed'), undef);
is($args->arg('args'), undef);
is($args->arg('arg1'), undef);
is($args->arg('arg2'), 'a_2');

## argument and array ##
undef $args;
@ARGV = qw(arg1 a1 a2 a3);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      file => ['-f:', 'specify filename'],
    },
    use_cases => {
      main => ['arg1 arg2...', ''],
    },
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is(ref $args->arg('arg2'), 'ARRAY');
is($args->arg('arg1'), 'arg1');
ok(eq_array($args->arg('arg2'), [qw(a1 a2 a3)]));

## array and argument ##
undef $args;
@ARGV = qw(a1 a2 a3 arg1);
eval{
  $args = CmdArgs->declare(
    '3.0',
    use_cases => {
      main => ['arg2... arg1', ''],
    },
  );
  $args->parse;
};
ok(!$@);
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
is(ref $args->arg('arg2'), 'ARRAY');
is($args->arg('arg1'), 'arg1');
ok(eq_array($args->arg('arg2'), [qw(a1 a2 a3)]));

## typed option ##
undef $args;
@ARGV = qw(-v -w ok);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['OPTIONS', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
ok($args->is_opt('word_ok'));
is($args->opt('word_ok'), 'ok');

## typed option fault ##
undef $args;
@ARGV = qw(-w not_ok);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['OPTIONS', ''],
    },
  );
  $args->parse;
};
like("$@", qr/not_ok/);
isa_ok($args, 'CmdArgs');


## typed argument ##
undef $args;
@ARGV = qw(ok);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['OPTIONS arg:Word_ok', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('not_existed'));
ok(!$args->is_opt('word_ok'));
is($args->arg('arg'), 'ok');

## typed argument fault ##
undef $args;
@ARGV = qw(not_ok);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['OPTIONS arg:Word_ok', ''],
    },
  );
  $args->parse;
};
like("$@", qr/not_ok/);
isa_ok($args, 'CmdArgs');

## check mandatory option ##
undef $args;
@ARGV = qw(-w ok fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['word_ok arg', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');
ok(!$args->is_opt('verb'));
ok($args->is_opt('word_ok'));
is($args->arg('arg'), 'fname');

## mandatory option fault ##
undef $args;
@ARGV = qw(-v -w ok fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['word_ok OPTIONS arg', ''],
    },
  );
  $args->parse;
};
isnt("$@", '');
isa_ok($args, 'CmdArgs');

## no groups fault ##
undef $args;
@ARGV = qw(-v fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    use_cases => {
      main => ['arg', ''],
    },
  );
  $args->parse;
};
isnt("$@", '');
isa_ok($args, 'CmdArgs');

## slice OPTIONS group ##
undef $args;
@ARGV = qw(-w ok fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    groups => {
      OPTIONS => [qw(word_ok)],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');

## slice OPTIONS group fault ##
undef $args;
@ARGV = qw(-v -w ok fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      verb => ['-v --verbose', 'verbose mode'],
      word_ok => ['-w:Word_ok', ''],
    },
    groups => {
      OPTIONS => [qw(word_ok)],
    },
  );
  $args->parse;
};
isnt("$@", '');
isa_ok($args, 'CmdArgs');

## group-group ##
undef $args;
@ARGV = qw(-a -b -c -d);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    groups => {
      OPTS_1 => [qw(opt_a opt_b)],
      OPTS_2 => [qw(opt_c opt_d opt_e)],
    },
    use_cases => {
      main => ['OPTS_1 OPTS_2', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');

## group-group fault ##
undef $args;
@ARGV = qw(-a -c -b -d);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    groups => {
      OPTS_1 => [qw(opt_a opt_b)],
      OPTS_2 => [qw(opt_c opt_d opt_e)],
    },
    use_cases => {
      main => ['OPTS_1 OPTS_2', ''],
    },
  );
  $args->parse;
};
isnt("$@", '');
isa_ok($args, 'CmdArgs');

## group-empty_group ##
undef $args;
@ARGV = qw(-a);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    groups => {
      OPTS_1 => [qw(opt_a opt_b)],
      OPTS_2 => [qw(opt_c opt_d opt_e)],
    },
    use_cases => {
      main => ['OPTS_1 OPTS_2', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');

## empty_group-group-arg ##
undef $args;
@ARGV = qw(-c fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    groups => {
      OPTS_1 => [qw(opt_a opt_b)],
      OPTS_2 => [qw(opt_c opt_d opt_e)],
    },
    use_cases => {
      main => ['OPTS_1 OPTS_2 arg', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');
is($args->arg('arg'), 'fname');

## group-arg-group ##
undef $args;
@ARGV = qw(-a fname -cd -e);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    groups => {
      OPTS_1 => [qw(opt_a opt_b)],
      OPTS_2 => [qw(opt_c opt_d opt_e)],
    },
    use_cases => {
      main => ['OPTS_1 arg OPTS_2', ''],
    },
  );
  $args->parse;
};
is("$@", '');
isa_ok($args, 'CmdArgs');
ok($args->is_opt('opt_a'));
ok($args->is_opt('opt_c'));
ok($args->is_opt('opt_d'));
ok($args->is_opt('opt_e'));
is($args->arg('arg'), 'fname');

## group-arg-group fault ##
undef $args;
@ARGV = qw(fname -a -c -d -e);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    groups => {
      OPTS_1 => [qw(opt_a opt_b)],
      OPTS_2 => [qw(opt_c opt_d opt_e)],
    },
    use_cases => {
      main => ['OPTS_1 arg OPTS_2', ''],
    },
  );
  $args->parse;
};
isnt("$@", '');

## joined one char options ##
undef $args;
@ARGV = qw(-abcde);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    use_cases => {
      main => ['OPTIONS', ''],
    },
  );
  $args->parse;
};
is("$@", '');
ok($args->is_opt('opt_a'));
ok($args->is_opt('opt_b'));
ok($args->is_opt('opt_c'));
ok($args->is_opt('opt_d'));
ok($args->is_opt('opt_e'));

## joined one char options 2 ##
undef $args;
@ARGV = qw(-abc -de);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    use_cases => {
      main => ['OPTIONS', ''],
    },
  );
  $args->parse;
};
is("$@", '');
ok($args->is_opt('opt_a'));
ok($args->is_opt('opt_b'));
ok($args->is_opt('opt_c'));
ok($args->is_opt('opt_d'));
ok($args->is_opt('opt_e'));

## check '--' arguments only mode ##
undef $args;
@ARGV = qw(-abc -- -d -e);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
      opt_b => ['-b', ''],
      opt_c => ['-c', ''],
      opt_d => ['-d', ''],
      opt_e => ['-e', ''],
    },
    use_cases => {
      main => ['OPTIONS args...?', ''],
    },
  );
  $args->parse;
};
is("$@", '');
ok($args->is_opt('opt_a'));
ok($args->is_opt('opt_b'));
ok($args->is_opt('opt_c'));
ok(!$args->is_opt('opt_d'));
ok(!$args->is_opt('opt_e'));
ok(eq_array($args->arg('args'), [qw(-d -e)]));

## use_case ##
undef $args;
@ARGV = qw(-a);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
    },
    use_cases => {
      only_one => ['OPTIONS', ''],
    },
  );
  $args->parse;
};
is("$@", '');
ok($args->is_opt('opt_a'));
is($args->use_case, 'only_one');

## 2 use_cases: 1 ##
undef $args;
@ARGV = qw(-a);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
    },
    use_cases => {
      first  => ['OPTIONS', ''],
      second => ['arg', ''],
    },
  );
  $args->parse;
};
is("$@", '');
ok($args->is_opt('opt_a'));
is($args->use_case, 'first');

## 2 use_cases: 2 ##
undef $args;
@ARGV = qw(fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
    },
    use_cases => {
      first  => ['OPTIONS', ''],
      second => ['arg', ''],
    },
  );
  $args->parse;
};
is("$@", '');
ok(!$args->is_opt('opt_a'));
is($args->use_case, 'second');

## 2 use_cases: fault ##
undef $args;
@ARGV = qw(-a fname);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
    },
    use_cases => {
      first  => ['OPTIONS', ''],
      second => ['arg', ''],
    },
  );
  $args->parse;
};
isnt("$@", '');

## ambiguous use_cases fault ##
undef $args;
@ARGV = qw(-a);
eval{
  $args = CmdArgs->declare(
    '3.0',
    options => {
      opt_a => ['-a', ''],
    },
    use_cases => {
      first  => ['OPTIONS', ''],
      second => ['OPTIONS', ''],
    },
  );
  $args->parse;
};
like("$@", qr/suitable/);

{
  package CmdArgs::Types::MyStr;
  sub check{
    my ($class, $val) = @_;
    $val eq 'correct_string'
  }
}

### check parse string ###

## select untyped ##
undef $args;
eval{
  $args = CmdArgs->declare(
    '4.2',
    use_cases => {
      second => ['arg2:', 'arg2'],
      first => ['arg1:MyStr', 'arg1'],
    },
  );
  $args->parse(qw(correct_string_1));
};
is("$@", '');

## error: 2 variants are suitable ##
eval{
  $args->parse(qw(correct_string));
};
isnt("$@", '');

## --help option and check message ##
eval{
  $args->parse(qw(--help));
};
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/arg1.*arg2.*arg1.*ABOUT/s);

## --version option and check message ##
eval{
  $args->parse(qw(--version));
};
isnt("$@", '');
isa_ok($@, 'Exceptions::CmdArgsInfo');
like("$@", qr/4\.2/);

### more options syntax ###

## key1: key2 ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f: --file'], },
  );
  $args->parse('-f filename arg');
};
is("$@", '');
is(eval {$args->opt('f')}, 'filename');

## key1:Type key2 ##
eval{
  $args = CmdArgs->declare(
    '1.0',
    options => { f => ['-f:Word_ok --file'], },
  );
  $args->parse('--file ok arg');
};
is("$@", '');
is(eval {$args->opt('f')}, 'ok');
