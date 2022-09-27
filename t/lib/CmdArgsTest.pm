use strict;

sub check_parse
{
  my ($decl, $str, $prove) = @_;
  local our $args = eval { CmdArgs->declare('0.1', %$decl) };
  {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is("$@", '', "decl: $str");
    if ($args) {
      eval { $args->parse($str) };
      is("$@", '', "parse: $str");
    }
  }
  $prove->() if defined $prove && $args;
}

sub check_parse_fail
{
  my ($decl, $str) = @_;
  local our $args = eval { CmdArgs->declare('0.1', %$decl) };
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is("$@", '', "decl: $str");
  if ($args) {
    eval { $args->parse($str) };
    isnt("$@", '', "parse fail: $str");
  }
}

1
