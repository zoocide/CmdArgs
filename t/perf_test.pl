#!/usr/bin/perl
use strict;
use Time::HiRes qw(time);

my $pref='perf_test/';
my $perl='perl -I../lib';
my $args = 'ok';
my $h = {
  empty_program_inline => sub { `$perl -e '' $args` },
  empty_program => sub { `$perl ${pref}empty.pl $args` },
  CmdArgsEmpty  => sub { `$perl ${pref}cmdargs-empty.pl $args` },
  CmdArgsNormal => sub { `$perl ${pref}cmdargs-normal.pl $args` },
  CmdArgsStatic => sub { `$perl ${pref}cmdargs-static.pl $args` },
  CmdArgsDoNormal => sub { `$perl ${pref}cmdargs-do-normal.pl $args` },
  CmdArgsDoStatic => sub { `$perl ${pref}cmdargs-do-static.pl $args` },
};
my %res;

use constant N => 10;
for my $n (keys %$h) {
  print "test $n\n";
  my $t = time;
  for (1..N) {
    my $out = $h->{$n}->();
    $? and die "error\n";
    $out and die "output is not empty:\n$out";
  }
  $res{$n} = (time - $t)/N;
}
print "$_ = $res{$_}\n" for sort keys %res;
