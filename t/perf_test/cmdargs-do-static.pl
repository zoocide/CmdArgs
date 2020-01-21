#!/usr/bin/perl
use strict;
use CmdArgs {
  version => '0.1',
  use_cases => [
    main => ['OPTIONS arg', ''],
  ],
  options => {
  },
};
CmdArgs->throw_errors;

my $str = '';
$str .= CmdArgs::ARG_arg if CmdArgs::ARG_arg eq 'ok';
