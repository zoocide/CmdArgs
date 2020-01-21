#!/usr/bin/perl
use strict;
use CmdArgs;

my $args = CmdArgs->declare(
  '0.1',
  use_cases => [
    main => ['OPTIONS arg', ''],
  ],
  options => {
  },
);
$args->parse;
my $str = '';
my $arg = $args->arg('arg');
$str .= $arg if $arg eq 'ok';
