use strict;
use Test::More tests => 19;

BEGIN {
  @ARGV = qw(-f=filename -v an_argument foo bar);
}

use CmdArgs {
  version => '1.0',
  use_cases => [
    main => ['OPTIONS arg1 arg2 arg4', ''],
    second => ['OPTIONS arg2 arg3'],
  ],
  options => {
    file => ['-f:'],
    verbose => ['-v'],
    debug => ['-D'],
  },
};
ok (1);
ok (defined &CmdArgs::throw_errors);
ok (defined &CmdArgs::USE_CASE);
ok (defined &CmdArgs::OPT_file);
ok (defined &CmdArgs::OPT_verbose);
ok (defined &CmdArgs::OPT_debug);
ok (defined &CmdArgs::ARG_arg1);
ok (defined &CmdArgs::ARG_arg2);
ok (defined &CmdArgs::ARG_arg3);
ok (defined &CmdArgs::ARG_arg4);
eval { CmdArgs::throw_errors };
is ("$@", '');
is (CmdArgs::USE_CASE, 'main');
is (CmdArgs::OPT_file, 'filename');
is (CmdArgs::OPT_verbose, 1);
is (CmdArgs::OPT_debug, undef);
is (CmdArgs::ARG_arg1, 'an_argument');
is (CmdArgs::ARG_arg2, 'foo');
is (CmdArgs::ARG_arg3, undef);
is (CmdArgs::ARG_arg4, 'bar');
