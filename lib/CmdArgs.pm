package CmdArgs;
use v5.10;
use strict;
use warnings;
use parent qw(Exporter);
use Exceptions;
use Exceptions::InternalError;

use Carp;
BEGIN {
  if (!defined &DEBUG_LEVEL) {
    my $v = defined &CmdArgs::DEBUG::ALL && CmdArgs::DEBUG::ALL() ? 2 : 0;
    *DEBUG_LEVEL = sub () { $v };
  }
}
use constant {
  dbg1 => DEBUG_LEVEL > 0,
  dbg2 => DEBUG_LEVEL > 1,
};
use if dbg1, 'Data::Dumper';

our $VERSION = '0.8.0';
our @EXPORT_OK = qw(ptext);

## TODO: Add more tests (help and usage! messages).
## TODO: Add tests for 'opt_or_default' method.
## TODO: Add tests for the new help message customizing system.
## TODO:+Add documentation for the new help message customizing system.
## TODO:+groups: update documentation
## TODO:+groups: add * to include all options
## TODO:+groups: allow to include whole groups, by specifying its name.
## TODO:+groups: add ^ exculde mark
## TODO:+groups: make _GROUPS not appearing in help message.
## TODO:+groups: add default group ABOUT
## TODO:+options: update documentation
## TODO:+options: allow to specify variables references instead of subroutines.
## TODO:+allow to have '-parameter'
## TODO:+allow to specify '--filename=filename'
## TODO:+add static variant of CmdArgs

=head1 NAME

CmdArgs - Parse command line arguments and automate help message creation.

=head1 SYNOPSIS

  use CmdArgs;

  ## simple expamle ##
  my $args = CmdArgs->declare(
    '0.1.0',
    use_cases => { main => ['OPTIONS my_arg', 'Description...'] },
    options => { verbose => ['-v --verbose', 'Print more information.'], }
  );
  $args->parse;

  my $verb = $args->is_opt('verbose');
  my $arg = $args->arg('my_arg');

  ========================================
  ## Main capabilities ##
  use CmdArgs;
  use CmdArgs::BasicTypes;

  {package CmdArgs::Types::Filename; sub check{my $arg = $_[1]; -f $arg}}

  my $args = CmdArgs->declare(
    $version,
    use_cases => [
      main   => ['OPTIONS arg1:Filename arg2:Int', 'The main use case.'],
      second => ['OPTS_GROUP_1 arg_1:Dir OPTS_GROUP_2 arg_2...?', 'The second usage.'],
    ],
    groups => {
      OPTS_GROUP_1 => [qw(opt_1 opt_2 silent)],
      OPTS_GROUP_2 => [qw(opt_9 opt_17)],
      OPTIONS => [qw(name verbose silent)],
    },
    options => {
      opt_1  => ['-f:Filename --filename', 'specify filename'],
      opt_2  => ['-i:<FILE> --input'     , 'read input from FILE'],
      silent => ['-s'                    , 'silent mode'],
      opt_9  => ['-z'                    , 'Zzz'],
      opt_17 => ['-0 --none --bla-bla'   , '0. simply 0'],
      verbose=> ['-v' , 'more verbose', sub {$verbose++}],
      name => ['-n:', 'set a name', sub {$name = $_}],
    },
    restrictions => [
      'verbose|opt_9|silent',
      'opt_2|opt_9',
    ]
  );

  $args->parse;
  ## or ##
  $args->parse('string args');

  if ($args->use_case eq 'main'){
    my $arg1 = $args->arg('arg1');
    my $silent = $args->is_opt('silent');
    my $name = $args->opt_or_default('name', 'default_name');
  }
  if ($args->use_case eq 'second'){
    my @arg2 = @{ $args->arg('arg_2') };
    my $f = 'my_filename';
    $f = $args->opt('opt_1') if $args->is_opt('opt_1');
  }

  ========================================
  ## static usage of CmdArgs ##
  use CmdArgs {
    version => $version,
    use_cases => ...
    options => {
      opt_1  => ['-f:Filename --filename', 'specify filename'],
      verbose => ['-v', 'more verbose'],
    },
  };
  # Throw errors as Exceptions::List if any occurred
  CmdArgs->throw_errors;

  # Statically optimized print. Perl will remove this line if verbose option is not specified.
  print "something\n" if CmdArgs::OPT_verbose;
  # CmdArgs::OPT_opt_1 is the constant contained specified filename or undefined otherwise
  print CmdArgs::OPT_opt_1, "\n";

  ========================================
  ## partial parsing of arguments ##
  $args->parse_begin;
  $args->parse_part(\@ARGV);
  $args->parse_part(\@additional_options);
  $args->parse_end;

=cut

sub dprint
{
  print "DEBUG: CmdArgs: $_\n" for split /\n/, join '', @_;
}

our $object;

sub import
{
  my $self = shift;
  if (@_ == 1 && ref $_[0] eq 'HASH') {
    dprint('compile time parsing of command line arguments is used') if dbg1;
    my $h = $_[0];

    ## parse specified options ##
    my $version = delete local $h->{version};
    croak "version parameter is not specified" if !defined $version;
    $object = CmdArgs->declare($version, %$h);
    eval { $object->parse };
    my $errors = $@;

    ## set static accessors ##
    no strict 'refs';
    *CmdArgs::throw_errors = sub () { die $errors if $errors };
    for my $opt (keys %{$object->{options}}) {
      my $v = $object->opt_or_default($opt);
      *{'CmdArgs::OPT_'.$opt} = sub () { $v };
    }
    for my $arg (keys %{$object->{arguments}}) {
      my $v = exists $object->{parsed}{args}{$arg}
            ? $object->{parsed}{args}{$arg}
            : undef;
      *{'CmdArgs::ARG_'.$arg} = sub () { $v };
    }
    my $uc = $object->{parsed}{use_case};
    *CmdArgs::USE_CASE = sub () { $uc };
  }
  else {
    dprint('runtime parsing of command line arguments is used') if dbg1;
    $self->export_to_level(1, undef, @_)
  }
}

###### PUBLIC FUNCTIONS ######

# my $plain_text = ptext $text;
sub ptext($)
{
  my $s=shift;
  $s =~ s/\n(\s*(\n(\s*\n)*))?/$2||''/ge;
  $s
}
##############################

sub arg { $_[0]{parsed}{args}{$_[1]} }
sub opt { $_[0]{parsed}{options}{$_[1]} }
sub opt_or_default
{
  exists $_[0]{parsed}{options}{$_[1]} ?
         $_[0]{parsed}{options}{$_[1]} : $_[2]
}
sub is_opt { exists $_[0]{parsed}{options}{$_[1]} }
sub args { %{$_[0]{parsed}{args}} }
sub opts { %{$_[0]{parsed}{options}} }
sub use_case { $_[0]{parsed}{use_case} }

# throws: string
sub declare
{
  my $class = shift;
  my $self = bless {}, $class;
  eval { $self->init(@_) };
  croak "$@" if $@;
  $self
}

# throws: Exceptions::Exception
sub init
{
  my ($self, $version, %h) = @_;

  ($self->{script_name} = $0) =~ s/.*[\/\\]//;
  $self->{version} = $version;
  $self->m_init_defaults;

  foreach my $sect (qw(options groups use_cases restrictions)){
    exists $h{$sect} || next;
    my $func = "m_$sect";
    $h{$sect} || throw Exception => "wrong $sect specification";
    $self->$func($h{$sect});
    delete $h{$sect};
  }

  scalar keys %h == 0 || throw Exception => 'unknown options: '.join(', ', keys %h);
}

# throws: Exceptions::List
sub parse
{
  my $self = shift;

  ## initialize ##
  $self->{parsed} = { options => {}, args => {}, args_arr => [] };
  $self->{options_end} = 0;

  ## obtain @args array ##
  my @args = @_ ? split(/\s+/, $_[0]) : @ARGV;
  dprint("parse string = '", join(' ', @args)."'") if dbg1;

  ## parse ##
  try{
    # @wrp_iters = ([$uc_name, [$uc_sequence, []]], ...)
    my @wrp_iters = map { [$_, [$self->{use_cases}{$_}{sequence}, []]] }
                        keys %{$self->{use_cases}};
    while (@args){
      my $atom = $self->m_get_atom(\@args);

      ## for error handling ##
      $self->{parse}{failed_arg_checks} = [];

      @wrp_iters = map {
        my $u = $_->[0];
        map [$u, $_], $self->m_fwd_iter($atom, $_->[1])
      } @wrp_iters;

      ## handle errors ##
      if (!@wrp_iters){
        if (@{$self->{parse}{failed_arg_checks}}){
          my @uniq_errors;
          for my $e (@{$self->{parse}{failed_arg_checks}}){
            push @uniq_errors, $e if !grep "$e" eq "$_", @uniq_errors;
          }
          throw List => @uniq_errors;
        }
        throw Exception => 'unexpected '.(  $atom->[0] eq 'opt'
                                        ? "option '$atom->[2]'"
                                        : "argument '$atom->[1]'");
      }
    }
    # finish with 'end' atom
    @wrp_iters = map {
      my $u = $_->[0];
      map [$u, $_], $self->m_fwd_iter(['end'], $_->[1])
    } @wrp_iters;
    dbg1 and dprint("num suitable sequences = ", scalar @wrp_iters);
    $#wrp_iters < 0 && throw Exception => 'wrong arguments';
    #$#wrp_iters > 0 && throw Exception => 'internal error: more then one use cases are suitable';
    if ($#wrp_iters > 0) {
      # Using any-place options may cause alternative parsed sequences.
      # But use case should be the only one.
      my $wi = $wrp_iters[0];
      for (@wrp_iters[1..$#wrp_iters]) {
        next if m_eq_end_wrp_iters($wi, $_);
        throw Exception => 'internal error: more then one use cases are suitable';
      }
    }
    $self->{parsed}{use_case} = $wrp_iters[0][0];
    $self->m_set_arg_names($wrp_iters[0][1]);
    if (dbg1) {
      dprint("use_case = $self->{parsed}{use_case}");
      my $popts = $self->{parsed}{options};
      dprint("option $_ = '$popts->{$_}'") for sort keys %$popts;
    }
  }
  catch{ throw } 'Exceptions::CmdArgsInfo',
  make_exlist
  catch{
    push @{$@}, Exceptions::CmdArgsInfo->new($self->m_usage_message);
    throw;
  };
}

# $args->parse_begin();
# throws:
sub parse_begin
{
  my $self = shift;
  dbg1 and dprint("begin arguments parsing");

  ## initialize ##
  $self->{parsed} = { options => {}, args => {}, args_arr => [] };
  $self->{options_end} = 0;

  # @wrp_iters = ([$uc_name, [$uc_sequence, []]], ...)
  $self->{parse}{wrp_iters} = [
    map { [$_, [$self->{use_cases}{$_}{sequence}, []]] }
      keys %{$self->{use_cases}}
  ];
}

# $args->parse_part(\@ARGV);
# throws: Exceptions::List
sub parse_part
{
  my $self = shift;
  my @args = @{shift()};
  my $wrp_iters = $self->{parse}{wrp_iters};

  dbg1 and dprint("parse arguments = '", join(' ', @args)."'");

  # Reset '--' only arguments state.
  $self->{options_end} = 0;

  ## parse ##
  try{
    while (@args){
      my $atom = $self->m_get_atom(\@args);

      ## for error handling ##
      $self->{parse}{failed_arg_checks} = [];

      @$wrp_iters = map {
        my $u = $_->[0];
        map [$u, $_], $self->m_fwd_iter($atom, $_->[1])
      } @$wrp_iters;

      ## handle errors ##
      if (!@$wrp_iters){
        if (@{$self->{parse}{failed_arg_checks}}){
          my @uniq_errors;
          for my $e (@{$self->{parse}{failed_arg_checks}}){
            push @uniq_errors, $e if !grep "$e" eq "$_", @uniq_errors;
          }
          throw List => @uniq_errors;
        }
        throw Exception => 'unexpected '.(  $atom->[0] eq 'opt'
                                        ? "option '$atom->[2]'"
                                        : "argument '$atom->[1]'");
      }
    }
  }
  catch{ throw } 'Exceptions::CmdArgsInfo',
  make_exlist
  catch{
    push @{$@}, Exceptions::CmdArgsInfo->new($self->m_usage_message);
    throw;
  };
}

# $args->parse_end();
# throws: Exceptions::List
sub parse_end
{
  my $self = shift;
  my $wrp_iters = $self->{parse}{wrp_iters};

  try {
    # finish with 'end' atom
    @$wrp_iters = map {
      my $u = $_->[0];
      map [$u, $_], $self->m_fwd_iter(['end'], $_->[1])
    } @$wrp_iters;
    $#$wrp_iters < 0 && throw Exception => 'wrong arguments';
    $#$wrp_iters > 0 && throw Exception => 'internal error: more then one use cases are suitable';
    $self->{parsed}{use_case} = $wrp_iters->[0][0];
    $self->m_set_arg_names($wrp_iters->[0][1]);
    if (dbg1) {
      dprint("use_case = $self->{parsed}{use_case}");
      my $popts = $self->{parsed}{options};
      dprint("option $_ = '$popts->{$_}'") for sort keys %$popts;
    }
  }
  catch{ throw } 'Exceptions::CmdArgsInfo',
  make_exlist
  catch{
    push @{$@}, Exceptions::CmdArgsInfo->new($self->m_usage_message);
    throw;
  };
}


sub print_help
{
  my $self = shift;
  print $self->m_version_message;
  print $self->m_help_message;
}

sub print_usage_and_exit
{
  my $self = shift;
  print $self->m_usage_message;
  exit -1;
}

sub print_version
{
  my $self = shift;
  print $self->m_version_message;
}

# $args->set_help_params(
#   key_indent => $key_indent,
#   line_indent => $line_indent,
#   opt_descr_indent => $opt_descr_indent,
#   kd_min_space => $kd_min_space,
#   max_gap => $max_gap
# );
sub set_help_params($%)
{
  my ($self, %p) = @_;
  my @vkeys = keys %{$self->{help}{params}};
  for my $k (keys %p){
    grep $k eq $_, @vkeys or croak "invalid parameter '$k'";
    $self->{help}{params}{$k} = $p{$k};
  }
}

# my %params = $args->get_help_params;
sub get_help_params
{
  my $self = shift;
  (%{$self->{help}{params}})
}

# $msg = $args->usage_custom_usecases(['usecase', 'scheme', 'descr'],...);
sub usage_custom_usecases
{
  my ($self, @ucs) = @_;
  my $ret = "usage:\n";
  if (@ucs > 1){
    my $i = 1;
    $ret .= join '', map '  '.($i++).": $_->[1]\n", @ucs;
  }
  elsif (@ucs) {
    $ret .= "  $ucs[0][1]\n";
  }
  else{
    dbg1 and dprint(Dumper($self));
    throw InternalError => 'no use_cases are defined';
  }

  $ret .= "Try --help option for help.\n";
  $ret
}

# $msg = $args->help_custom_usecases(['usecase', 'scheme', 'descr'],...);
sub help_custom_usecases
{
  my ($self, @ucs) = @_;
  my $max_gap = $self->{help}{params}{max_gap};
  my $w = $self->{terminal}{w};

  my $ret = "usage:\n";
  if (@ucs > 1){
    my $i = 1;
    my $d;
    for (@ucs){
      $ret .= "  $i: $_->[1]\n";

      my $p = "$i: ";
      $d .= $p.m_format_text($_->[2], $w-1-length($p), 2, $w-3, $max_gap)."\n";
      $i++;
    }
    $ret.=$d;
  }
  else{
    $ret .= "  $ucs[0][1]\n";
    $ret .= m_format_text($ucs[0][2], $w-1, 0, $w-1, $max_gap)."\n";
  }
  $ret."\n"
}

# @group_names = $args->help_custom_groups_filter(@group_names);
sub help_custom_groups_filter
{
  shift;
  sort @_
}

# $msg.= $args->help_custom_group('group_name');
sub help_custom_group_name
{
  my ($self, $group_name) = @_;
  "$group_name:\n"
}

# @opt_names = $args->help_custom_options_filter('group_name', @opt_names);
sub help_custom_options_filter
{
  my $self = shift;
  my $gr = shift;
  @_
}

# $msg.= $args->help_custom_option(
#     'opt', [@keys], 'arg_type', 'arg_name', 'descr');
sub help_custom_option
{
  my ($self, $opt_name, $keys, $type, $arg, $descr) = @_;
  my ($kpos, $fl_shift, $dpos, $mdist, $max_gap) =
    @{$self->{help}{params}}{qw(
      key_indent line_indent opt_descr_indent kd_min_space max_gap
    )};
  my ($w, $h) = @{$self->{terminal}}{qw(w h)};
  return '' if !defined $descr;
  my $ret = ' ' x $kpos;
  $ret .= join ', ', @$keys;
  $ret .= " $arg" if defined $type;
  $descr ||= '<no description>';

  ## finish current line ##
  $dpos += $fl_shift;
  my $l = (length($ret) + $mdist) % $w;
  if ($l < $dpos){
    $ret .= ' ' x ($dpos - $l);
    $l = $dpos;
  }
  my $n = $w - 1 - $l;
  $descr =~ s/\t/ /g;
  my @lines = split /\n/, $descr;
  my ($lf, $rt) = m_smart_split_by_width($lines[0], $n, $max_gap, 1);
  $ret .= (' ' x $mdist)."$lf\n";
  $lines[0] = $rt;

  ## process next lines ##
  $dpos -= $fl_shift;
  my @strs;
  for my $line (@lines){
    while ($line){
      ($lf, $line) = m_smart_split_by_width($line, $w-1-$dpos, $max_gap, 0);
      push @strs, $lf;
    }
  }
  $ret .= (' ' x $dpos)."$_\n" for @strs;
  $ret
}

###### PRIVATE METHODS ######

# self structure
# $self = bless {
#   keys    => { $single_opt_key => $opt_name, },
#   arguments => { $arg_name => 1 },
#   options => {
#     $opt_name => {
#       keys => [@keys],
#       type => $type,  #< Type of the argument. It corresponds to CmdArgs::Types::Type;
#       descr => $description_str,
#       action => $act,  #< action may be sub{} or scalar ref or array ref.
#       arg_name => $argument_name_str,
#     },
#   },
#   groups => {
#     $group_name => [@opt_names],
#   },
#   use_cases => {
#     $use_case_name => {
#       use_case => $string_for_help_message,
#       sequence => $uc_list,  #< recursive list: $uc_list = [[$atom, $permitted_opts], $uc_list]
#       descr    => $string_for_help_message,
#   },
#   restrictions => {
#     $opt_name => [@options_conflicting_with_opt],
#   },
#   arrangement => {
#     first_keys => {
#       $first_key => $opt_name,
#     },
#   },
#   help => {
#     params => {
#       key_indent => $integer,
#       line_indent => $integer,
#       opt_descr_indent => $integer,
#       kd_min_space => $integer,
#       max_gap => $integer,
#     },
#   },
#   options_end => $bool, #< mark that options cannot appear further
#   parsed => {
#     use_case => $use_case_name,
#     args => {
#       $arg_name => $value | [@values],
#     },
#     options => {
#       $opt_name => $value,
#     },
#     option_keys => {
#       $opt_name => $used_key,
#     },
#     args_arr => [@parsed_args],
#   },
#   parse => {
#     failed_arg_checks => [@exceptions], #< for error handling
#     split_one_char_options => $bool,
#     wrp_iters => [...], #< the current parse state of the partial parsing.
#   },
# }, CmdArgs;

sub m_update_terminal_info
{
  my $self = shift;
  my $min_w = $self->{help}{params}{opt_descr_indent} + 5;
  my @default_size = (80 < $min_w ? $$min_w : 80, 24);
  my $f; #< get rid from GetTerminalSize() messages
  eval{
    require Term::ReadKey;
    require File::Spec;
    open STDERR, '>', File::Spec->devnull if open $f, '>&STDERR';
    my ($w, $h) = Term::ReadKey::GetTerminalSize();
    @{$self->{terminal}}{qw(w h)} = $w <= $min_w ? @default_size : ($w, $h);
  };
  if ($@){
    @{$self->{terminal}}{qw(w h)} = @default_size;
  }
  if (defined $f){
    open STDERR, '>&', $f;
    close $f;
  }
}

sub m_use_case_msg
{
  my ($self, $uc) = @_;
  my $ret = $self->{script_name};
  for(my $seq = $uc->{sequence}; !m_is_p_empty($seq); m_move_next_p($seq)){
    my $cur = m_value_p($seq);
    if    ($cur->[0] eq 'group'){
      $ret.= ' '.($cur->[2] eq '~' ? "[$cur->[1]]" : $cur->[1]);
    }
    elsif ($cur->[0] eq 'mopt' ){
      my $o = $self->{options}{$cur->[1]};
      my @keys = @{$o->{keys}};
      my $s = join '|', @keys;
      $s  = '('.$s.')'       if @keys > 1;
      $s .= ' '.$o->{arg_name} if defined $o->{type};
      $s  = '['.$s.']'       if $cur->[2];
      $ret.= ' '.$s;
    }
    elsif ($cur->[0] eq 'arg'){
      my $s = $cur->[1];
      $s .= '...'      if $cur->[4];
      $s  = '['.$s.']' if $cur->[3];
      $ret .= ' '.$s;
    }
  }
  $ret
}

sub m_usecases_to_str
{
  my ($self, $method) = @_;
  my @uc_names = exists $self->{arrangement}{use_cases}
               ? @{$self->{arrangement}{use_cases}}
               : keys %{$self->{use_cases}};
  $self->$method(
    map {
      my $name = $_;
      my $uc = $self->{use_cases}{$name};
      [$name, $self->m_use_case_msg($uc), $uc->{descr}]
    } @uc_names
  )
}

sub m_usage_message
{
  my $self = shift;
  $self->m_usecases_to_str('usage_custom_usecases');
}

sub m_help_message
{
  my $self = shift;
  $self->m_update_terminal_info;
  my $ret = $self->m_usecases_to_str('help_custom_usecases');
  my @gr_names = $self->help_custom_groups_filter(keys %{$self->{groups}});
  for my $gr (@gr_names){
    next if substr($gr,0,1) eq '_';
    $ret .= $self->help_custom_group_name($gr);
    my @opt_names = $self->help_custom_options_filter(
      $gr, @{$self->{groups}{$gr}}
    );
    for my $opt_name (@opt_names){
      my $opt = $self->{options}{$opt_name};
      $ret .= $self->help_custom_option(
        $opt_name,
        $opt->{keys},
        $opt->{type},
        $opt->{arg_name},
        $opt->{descr}
      );
    }
  }
  $ret
}

# my $formatted_text = m_format_text(
#   $text, $fl_width, $body_indent, $width, $max_gap);
sub m_format_text
{
  my ($text, $flw, $ind, $w, $max_gap) = @_;
  my @lines = m_split_text($text, $flw, $w, $max_gap);
  my $ret = shift @lines;
  my $sh = $ind > 0 ? ' ' x $ind : '';
  $ret .= join '', map "\n$sh".$_, @lines;
  $ret
}

# my @lines = m_split_text($text, $fl_width, $width, $max_gap);
sub m_split_text
{
  my ($text, $flw, $w, $max_gap) = @_;
  my @ret;

  $text =~ s/\t/ /g;
  my @lines = split /\n/, $text;
  return @ret if !@lines;

  ## process first line ##
  my ($lf, $rt) = m_smart_split_by_width($lines[0], $flw, $max_gap, 1);
  push @ret, $lf;
  $lines[0] = $rt;

  ## process next lines ##
  for my $line (@lines){
    while ($line){
      ($lf, $line) = m_smart_split_by_width($line, $w, $max_gap, 0);
      push @ret, $lf;
    }
  }
  @ret
}

# my ($left_part, $right_part) = m_smart_split_by_width(
#   $str, $width, $max_gap, $first_line);
sub m_smart_split_by_width
{
  my ($str, $w, $max_gap, $first_line) = @_;
  return ($str, '') if !$str || length $str <= $w;
  return ('', $str) if $w <= 0;

  ## $str = $l . $r ##
  my $l = substr $str, 0, $w;
  my $r = substr $str, $w;

  ## process "empty" left part ##
  if ($l =~ /^\s*$/){
    return ('', $str) if $first_line;
    do{
      return ($r, '') if length $r <= $w;
      $l = substr $r, 0, $w;
      $r = substr $r, $w;
    } while($l && $l =~ /^\s*$/);
  }

  ## decide to cut off broken word from left part ##
  return ($l, $r) if $r =~ s/^\s+// || $l =~ /\s$/;
  return ($l, $r) if $l !~ /([^{(\[,\s]+)$/ || length $1 >= $max_gap;
  return ($l, $r) if !$first_line && !$`;
  ($`, $1.$r)
}

sub m_version_message
{
  my $self = shift;
  "version $self->{version}\n";
}

# throws: -
sub m_init_defaults
{
  my $self = shift;
  $self->{keys}{'--help'}    = 'HELP';
  $self->{keys}{'--version'} = 'VERSION';
  $self->{options}{HELP}    = { keys  => ['--help'   ], type  => undef, descr => 'Print help.' };
  $self->{options}{VERSION} = { keys  => ['--version'], type  => undef, descr => 'Print version.' };
  $self->{groups}{ABOUT}    = [qw(HELP VERSION)];
  $self->{arrangement}{first_keys}{'--help'} = 'HELP';
  $self->{arrangement}{first_keys}{'--version'} = 'VERSION';
  # TODO: make default use_case '~OPTIONS args...'.
  $self->{use_cases}{main} = { use_case => 'OPTIONS args...',
                               sequence => [[['group', 'OPTIONS', ''], {}],
                                           [[['arg','args','','','...'], {}],
                                           [[['end'],{}],
                                           []]]],
                               descr => ''};
  $self->{help}{params}{key_indent} = 2;
  $self->{help}{params}{line_indent} = 0;
  $self->{help}{params}{opt_descr_indent} = 13 + 4;
  $self->{help}{params}{kd_min_space} = 4;
  $self->{help}{params}{max_gap} = 15;
  $self->{parse}{split_one_char_options} = 1;
}

# throws: Exceptions::Exception
sub m_options
{
  my ($self, $opts) = @_;

  ref $opts eq 'HASH' || throw Exception => 'wrong options specification: hash should be used';

  for my $name (keys %$opts) {
    $self->{options}{$name} = $self->m_option($name, $opts->{$name});
  }

  ## arrange options by the first key ##
  my $fks = $self->{arrangement}{first_keys};
  @{$self->{groups}{OPTIONS}} = grep $_ ne 'HELP' && $_ ne 'VERSION',
      map $fks->{$_}, sort keys %$fks;
}

# throws: Exceptions::Exception
sub m_groups
{
  my ($self, $groups) = @_;

  ## check correctness of the specification ##
  ref $groups eq 'HASH' || throw Exception => 'wrong groups specification: hash should be used';

  delete $self->{groups}{OPTIONS};
  my %grs = (%{$self->{groups}}, %$groups);
  $self->{groups} = {};

  my $modify_gr = sub{
    my ($gr_name, $op_del, @opts) = @_;
    if ($op_del){
      @{$self->{groups}{$gr_name}} = grep {
        my $opt = $_; !grep $opt eq $_, @opts
      } @{$self->{groups}{$gr_name}};
    }
    else {
      for my $opt (@opts){
        next if grep $opt eq $_, @{$self->{groups}{$gr_name}};
        push @{$self->{groups}{$gr_name}}, $opt;
      }
    }
  };

  my @working_on;

  my $process_gr;
  $process_gr = sub{
    my $gr_name = shift;
    my $gr = $grs{$gr_name};

    delete $grs{$gr_name};
    push @working_on, $gr_name;

    ref $gr eq 'ARRAY' || throw Exception => "worng group '$gr_name' specification:"
                                           .' group must be an array of options';

    $self->{groups}{$gr_name} = [];
    for my $name (@$gr){
      my $to_del = ($name =~ s/^\^//);
      if ($name eq '*'){
        # sort all options by the first key
        my $fks = $self->{arrangement}{first_keys};
        my @opts = map $fks->{$_}, sort keys %$fks;
        &$modify_gr($gr_name, $to_del, @opts);
      }
      elsif (exists $self->{options}{$name}){
        &$modify_gr($gr_name, $to_del, $name);
      }
      elsif (exists $grs{$name}){
        &$process_gr($name);
        &$modify_gr($gr_name, $to_del, @{$self->{groups}{$name}});
      }
      elsif (grep $name eq $_, @working_on){
        throw Exception => 'cyclic references detected ('
                         .join('-', @working_on, $name).')';
      }
      elsif (exists $self->{groups}{$name}){
        &$modify_gr($gr_name, $to_del, @{$self->{groups}{$name}});
      }
      else {
        throw Exception => "unknown option '$name' specified for group '$gr_name'";
      }
    }
    pop @working_on;
  };

  &$process_gr((keys %grs)[0]) while %grs;
}

# throws: Exceptions::Exception
sub m_use_cases
{
  my ($self, $use_cases) = @_;

  # remove default main use_case
  delete $self->{use_cases}{main};

  if (ref $use_cases eq 'ARRAY'){
    $self->{arrangement}{use_cases} = [@{$use_cases}[grep {!($_ & 1)} 0..$#$use_cases]];
    $use_cases = {@$use_cases};
  }

  ref $use_cases eq 'HASH'
    || throw Exception => 'wrong use cases specification: hash or array should be used';
  %$use_cases or throw Exception => 'one or more use cases should be defined';

  for my $name (keys %$use_cases) {
    $self->{use_cases}{$name} = $self->m_use_case($name, $use_cases->{$name});
  }
}

# on result:
#   for each $opt, specified in restrictions:
#   $self->{restrictions}{$opt} = [@options_conflicting_with_opt];
# throws: Exceptions::Exception
sub m_restrictions
{
  my ($self, $restrs) = @_;

  ## unpack restrictions ##
  my %res;
  ref $restrs eq 'ARRAY'
    || throw Exception => 'wrong restrictions specification: array must be used';
  for (@$restrs){
    my @opts = split /\|/;
    for my $o (@opts){
      exists $self->{options}{$o}
        || throw Exception => "unknow option '$o' is specified in restriction";
      $res{$o} ||= [];
      push @{$res{$o}}, grep {
        my $a = $_;
        $a ne $o && !grep {$a eq $_} @{$res{$o}}
      } @opts;
    }
  }

  ## set restrictions ##
  $self->{restrictions} = \%res;
}

# on result:
#   $self->{keys}{@keys_of_option} = $option_name
#   return { keys  => [@keys_of_option],
#            type  => $type_of_the_first_key,
#            descr => $opt_value->[1],
#           (action=> $opt_value->[2] if exists),
#            arg_name => $argument_name }
# throws: Exceptions::Exception
sub m_option
{
  my ($self, $name, $opt_value) = @_;

  ## unpack $opt_value ##
  ref $opt_value eq 'ARRAY' && @$opt_value > 0
    or throw Exception => "wrong option '$name' specification";

  my $val = $opt_value->[0];

  ## parse the first key ##
  my $type = undef;
  my $arg_name = undef;
  if ($val =~ s/^\s*(\S+?):(\w*)(<(.+)>)?/$1/){
    $type = $2;
    $arg_name = $4 || '<arg>';
    $self->m_check_type($type);
  }

  my @keys  = split /\s+/, $val;
  $#keys < 0 && throw Exception => "no keys specified for option '$name'";

  ## save the first key for options arrangement ##
  $self->{arrangement}{first_keys}{$keys[0]} = $name;

  ## check all keys ##
  foreach (@keys){
    /[^\w_=-]/ && throw Exception => "worong option '$name' specification: '$_'";
    exists $self->{keys}{$_} && throw Exception => "key '$_' duplicate";
    $self->{keys}{$_} = $name;

    ## disable one char splitting for options ##
    $self->{parse}{split_one_char_options} = 0 if /^-[^-]./;
  }

  ## define action ##
  my @action;
  if ($#$opt_value > 1 && defined $opt_value->[2]){
    my $p = $opt_value->[2];
    my $a = $p;
    ref $p or throw Exception => "wrong action specified for option '$name'";

    if (ref $p eq 'SCALAR'){
      $a = sub { $$p = $_[0] };
    }
    elsif (ref $p eq 'ARRAY'){
      $a = sub { push @$p, $_[0] }
    }
    @action = (action => $a);
  }

  ## return new option ##
  my $ret = {
    keys  => [@keys],
    type  => $type,
    descr => ($#$opt_value > 0 ? $opt_value->[1] : ''),
    @action,
    arg_name => $arg_name,
  };
  $ret
}

# throws: Exceptions::Exception
sub m_use_case
{
  my ($self, $name, $use_case) = @_;

  ## unpack $use_case ##
  ref $use_case eq 'ARRAY' || throw Exception => "wrong use case '$name' specification: "
                                                .'array should be used';
  $#$use_case < 0 && throw Exception => "worng use case '$name' specification: "
                                       .'use case sequence is not specified';
  my @seq = split /\s+/, $use_case->[0];

  ## parse sequence ##
  my %cur_opts; # { $opt => $min_num, ... }
  for my $i (0..$#seq){
    my $w = $seq[$i];
    if (exists $self->{groups}{$w}){
    ## options group ##
      $seq[$i] = ['group', $w, '']; #< [type, group_name, msg_flag]
    }
    elsif ($w =~ /^~(\w+)$/ && exists $self->{groups}{$1}) {
      ## any place options group ##
      $seq[$i] = ['group', $1, '~']; #< [type, group_name, msg_flag]
      $cur_opts{$_} //= 0 for @{$self->{groups}{$1}};
    }
    elsif ($w =~ /^(~)?(\w+)(?::(.*?))?(\.\.\.)?(\?)?$/){
      my ($ap, $n, $t, $mult, $q) = ($1, $2, $3, $4, $5);
      if (exists $self->{options}{$n}){
      ## mandatory option ##
        ($t || $mult) && throw Exception => "wrong use case '$name' specification: "
                                           ."syntax error in option '$n' specification";
        $seq[$i] = ['mopt', $n, $q, $ap]; #< [type, option_name, can_absent, ap_flag]
        $cur_opts{$n} += $q ? 0 : 1 if $ap;
      }
      else{
      ## argument ##
        $ap and throw Exception => "wrong use case '$name' spceification at '$w': "
          ."arguments does not support ~ modifier";
        $self->m_check_type($t);
        $seq[$i] = ['arg', $n, $t, $q, $mult]; #<[type, arg_name, arg_type, can_absent, array]
        $self->{arguments}{$n} = 1;
      }
    }
    else{
      throw Exception => "wrong use case '$name' spceification: syntax error in '$w'";
    }
    $seq[$i] = [$seq[$i], {%cur_opts}] if $seq[$i];
  }

  my $p_seq = m_p_add([], [['end'],{%cur_opts}]);
  $p_seq = m_p_add($p_seq, $_) for reverse @seq;

  ## return new use_case ##
  my $ret = {
    use_case => $use_case->[0],
    sequence => $p_seq,
    descr    => $#$use_case > 0 ? $use_case->[1] : '',
  };
  $ret
}

# throws: Exceptions::Exception
sub m_check_type
{
  my ($self, $type) = @_;
  return if !$type;
  my $package = "CmdArgs::Types::$type";
  exists $CmdArgs::Types::{$type.'::'}
    or throw Exception => "wrong type specified '$type'. "
      ."Type '$type' should be defined by package 'CmdArgs::Types::$type'. "
	  ."See CmdArgs manual for more details.";
  eval{ $package->can('check') } || $@
    or throw Exception => "$package should have subroutine 'check'.";
}

# throws: Exceptions::Exception, ...
sub m_check_arg
{
  my ($self, $arg, $type) = @_;
  !$type || "CmdArgs::Types::$type"->check($arg) || throw Exception => "'$arg' is not $type";
}

# throws: Exceptions::Exception, Exceptions::CmdArgsInfo, ...
sub m_get_atom
{
  my ($self, $args) = @_;

  @$args || return 0;
  my $cur = shift @$args;

  # parse 'option=value' case
  if (!$self->{options_end} && $cur =~ /^(.+?)=(.*)/ && exists $self->{keys}{$1}){
    $cur = $1;
    unshift @$args, $2;
  }

  if (!$self->{options_end} && (substr($cur,0,1) eq '-' || exists $self->{keys}{$cur}))
  {
  ## option ##
    if ($cur eq '--'){
    # case '--' #
      $self->{options_end} = 1; ##< enable arguments only mode
      return $self->m_get_atom($args);
    }

    ## get option ##
    my $add_sub = 0;
    if ($self->{parse}{split_one_char_options} && $cur =~ /^\-[^\-]/ && length $cur > 2){
    # split one-char options #
      unshift @$args, substr($cur, 2);
      $add_sub = 1;
      $cur = substr $cur, 0, 2;
    }
    exists $self->{keys}{$cur} || throw Exception => "unknown option '$cur'";
    my $opt = $self->{keys}{$cur};

    ## check restrictions ##
    if (exists $self->{restrictions}{$opt}){
      for (@{$self->{restrictions}{$opt}}){
        exists $self->{parsed}{options}{$_}
            && throw Exception => "option '$cur' can not be used with option "
                                 ."'$self->{parsed}{option_keys}{$_}'";
      }
    }

    my $param = 1;
    if (defined $self->{options}{$opt}{type}){
    # option with parameter #
      my $type = $self->{options}{$opt}{type};
      @$args || throw Exception => "parameter for option '$cur' is not specified";
      $param = shift @$args;
      $add_sub = 0;
      $self->m_check_arg($param, $type)
        || throw Exception => "wrong parameter '$param' for option '$cur'";
    }
    $self->{parsed}{options}{$opt} = $param;
    $self->{parsed}{option_keys}{$opt} = $cur;
    # do action
    if (exists $self->{options}{$opt}{action}){
      local $_ = $param;
      &{$self->{options}{$opt}{action}}($param);
    }
    $args->[0] = '-'.$args->[0] if $add_sub;

    $opt eq 'HELP'    && throw CmdArgsInfo => $self->m_help_message;
    $opt eq 'VERSION' && throw CmdArgsInfo => $self->m_version_message;

    return ['opt', $opt, $cur]; #< $cur here needed only for nicer error message.
  }

  ## get argument ##
  push @{$self->{parsed}{args_arr}}, $cur;
  ['arg', $cur]
}

# iter: [sequence, parsed_arguments, opt_state]
# sequence         = [] | [elm1, []] | [elm1, [elm2, []]] | ...
# parsed_arguments = [] | [arg1, []] | [arg1, [arg2, []]] | ...
# opt_state = { opt => $state }
# returns: (@fwd_iters)
# throws: Exceptions::Exception, Exceptions::InternalError
sub m_fwd_iter
{
  my ($self, $atom, $iter) = @_;
  my @ret;

  if ($atom->[0] eq 'opt'){
  # option #
    my $opt_name = $atom->[1];
    my $ap;
    my $occurred;
    for(my $seq = $iter->[0]; !m_is_p_empty($seq); m_move_next_p($seq)){
      $ap = $seq if !defined $ap && m_is_opt_permitted($seq, $opt_name);
      my $cur = m_value_p($seq);
      if    ($cur->[0] eq 'group'){
        #$cur = ['group', $name, $ap_flag]
        next if $cur->[2];
        if (!$occurred && $self->m_group_contains($cur->[1], $opt_name)){
        # group contains current option
          push @ret, [$seq, @{$iter}[1,2]];
          $occurred = 1;
        }
        next;
      }
      elsif ($cur->[0] eq 'mopt'){
        #$cur = ['mopt', $name, $can_absent, $ap_flag]
        next if $cur->[3];
        if ($opt_name eq $cur->[1]) {
          push @ret, [m_get_next_p($seq), @{$iter}[1,2]];
          $occurred = 1;
        }
        next if $cur->[2]; #< '?' is present
        last;
      }
      elsif ($cur->[0] eq 'arg' && $cur->[3]){ #< '?' is presented
        next;
      }
      elsif ($cur->[0] eq 'arg'){ #< '?' is not persented
        last;
      }
      elsif ($cur->[0] eq 'end'){
        last;
      }
      else{
        throw InternalError => "wrong type '$cur->[0]' of sequence";
      }
    }
    if (defined $ap) {
      my $n = $iter->[2]{$opt_name} // 0;
      my $k = m_opt_permitted_val($ap, $opt_name);
      local $iter->[2]{$opt_name} = $k > $n ? $n+1 : $n;
      dbg2 and dprint("any-place $opt_name appears ($iter->[2]{$opt_name}/$k)");
      push @ret, [$ap, $iter->[1], {%{$iter->[2]}}];
    }
  }
  elsif ($atom->[0] eq 'arg'){
  # argument #
    for(my $seq = $iter->[0]; !m_is_p_empty($seq); m_move_next_p($seq)){
      my $cur = m_value_p($seq);
      if    ($cur->[0] eq 'group'){
        next;
      }
      elsif ($cur->[0] eq 'mopt'){
        next if $cur->[2] || $cur->[3]; #< '?' or '~' is present
        last;
      }
      elsif ($cur->[0] eq 'arg'){
        my $present = !m_is_p_empty($iter->[1]) && m_parsed_value_p($iter->[1]) eq $cur;
        if (!$cur->[2] || eval{$self->m_check_arg($atom->[1], $cur->[2])}){
          push @ret, [
            $cur->[4] ? $seq : m_get_next_p($seq),
            m_p_add($iter->[1], $cur),
            $iter->[2]
          ];
        }
        elsif($cur->[2] && $@){
          # m_check_arg failed
          push @{$self->{parse}{failed_arg_checks}}, $@;
        }
        next if $cur->[3] || ($cur->[4] && $present);
        last;
      }
      elsif ($cur->[0] eq 'end') {
        last;
      }
      else{
        throw InternalError => "wrong type '$cur->[0]' of sequence";
      }
    }
  }
  elsif ($atom->[0] eq 'end'){
  # end of parse #
    m_is_iter_empty($iter) && return $iter;
    for(my $seq = $iter->[0]; !m_is_p_empty($seq); m_move_next_p($seq)){
      my $cur = m_value_p($seq);
      if    ($cur->[0] eq 'group'){
        next;
      }
      elsif ($cur->[0] eq 'mopt'){
        next if $cur->[2] || $cur->[3]; #< '?' or '~' is present
        return ();
      }
      elsif ($cur->[0] eq 'arg'){
        my $present = !m_is_p_empty($iter->[1]) && m_parsed_value_p($iter->[1]) eq $cur;
        next if $cur->[3] || ($cur->[4] && $present);
        return ();
      }
      elsif ($cur->[0] eq 'end'){
        m_check_required_opts($seq, $iter->[2]) or return ();
        last;
      }
      else{
        throw InternalError => "wrong type '$cur->[0]' of sequence";
      }
    }
    return [[], @{$iter}[1,2]]; #< return empty sequence
  }
  else{
    throw InternalError => "wrong atom type ($atom->[0])";
  }

  @ret
}

# p = [[$value, {%global_options}], $next]
sub m_is_p_empty  { @{$_[0]} == 0 }                   #< $bool = m_is_p_empty($p);
sub m_move_next_p { $_[0] = $_[0][1] }                #< m_move_next_p($p);
sub m_get_next_p  { $_[0][1] }                        #< $next = m_get_next_p($p);
sub m_value_p     { $_[0][0][0] }                     #< $value = m_value_p($p);
sub m_parsed_value_p { $_[0][0] }                     #< for lists of form [$value, $next]
sub m_p_add       { [$_[1], $_[0]] }                  #< $new_p = m_p_add($p, $value)
sub m_is_opt_permitted { exists ${$_[0][0][1]}{$_[1]} }  #< $bool = m_is_opt_permitted($p, $opt_name);
sub m_opt_permitted_val { ${$_[0][0][1]}{$_[1]} }     #< $val = m_opt_permitted_val($p, $opt_name);

# m_dbg($condition, caller_depth);
sub m_dbg
{
  if ($_[0]){
    my (undef, $cf, $cl) = caller;
    my (undef, $f, $l) = caller($_[1]);
    print "DEBUG: assert $cf:$cl. Called from $f:$l\n";
  }
}

# iter: [sequence, parsed_arguments]
# sequence         = [] | [elm1, []] | [elm1, [elm2, []]] | ...
# parsed_arguments = [] | [arg1, []] | [arg1, [arg2, []]] | ...
sub m_is_iter_empty { @{$_[0][0]} == 0 } #< $bool = m_is_iter_empty($iter);

# throws: Exceptions::Exception
sub m_set_arg_names
{
  my ($self, $iter) = @_;
  my @args = @{$self->{parsed}{args_arr}};

  ## init all arrays arguments ##
  my $uc = $self->{use_cases}{$self->{parsed}{use_case}};
  for (my $s = $uc->{sequence}; !m_is_p_empty($s); m_move_next_p($s)){
    my $cur = m_value_p($s);
    $self->{parsed}{args}{$cur->[1]} = [] if $cur->[0] eq 'arg' && $cur->[4];
  }

  ## set arguments values ##
  for (my $p = $iter->[1]; !m_is_p_empty($p); m_move_next_p($p)){
    my $cur = m_parsed_value_p($p);
    $cur->[0] eq 'arg' || throw InternalError => "wrong type '$cur->[0]' of arguments sequence";
    if ($cur->[4]){
    # array #
      unshift @{$self->{parsed}{args}{$cur->[1]}}, pop @args;
    }
    else{
      $self->{parsed}{args}{$cur->[1]} = pop @args;
    }
  }
  @args && throw InternalError => 'parsed arguments mismatch ['.scalar(@args).']';
}

# $bool = $self->m_group_contains($group_name, $opt_name);
sub m_group_contains
{
  #grep $atom->[1] eq $_, @{$self->{groups}{$cur->[1]}}
  for (@{$_[0]{groups}{$_[1]}}) {
    return 1 if $_ eq $_[2];
  }
  0
}

# $bool = m_check_required_opts($seq, $opt_state);
sub m_check_required_opts
{
  my ($seq, $opt_state) = @_;
  my $opts = $seq->[0][1];
  for (keys %$opts) {
    my $n = $opt_state->{$_} // 0;
    if ($n < $opts->{$_}) {
      dbg2 and dprint("required option $_ is messed ($n/$opts->{$_})");
      return 0;
    }
  }
  1
}

# $bool = m_eq_end_wrp_iters($wrp_iter1, $wrp_iter2);
# wrp_iter = [$use_case_name, [[], $parsed_arguments]]
# parsed_arguments = [] | [arg1, []] | [arg1, [arg2, []]] | ...
# arg = ['arg', $arg_name, $arg_type, $can_absent, $is_array]
sub m_eq_end_wrp_iters
{
  my ($it1, $it2) = @_;
  return 0 if $it1->[0] ne $it2->[0];
  my $p1 = $it1->[1][1];
  my $p2 = $it2->[1][1];
  #use Data::Dumper;
  #print STDERR Dumper([$it1, $it2]);

  while(!m_is_p_empty($p1)) {
    return 0 if m_is_p_empty($p2)
      || m_value_p($p1)->[1] ne m_value_p($p2)->[1]; #< $arg_name1 != $arg_name2
    m_move_next_p($p1);
    m_move_next_p($p2);
  }
  return 0 if !m_is_p_empty($p2);
  1
}


package Exceptions::CmdArgsInfo;
use base qw(Exceptions::Exception);

sub init { (my $self = shift)->SUPER::init(@_); chomp($self->{msg}); }

1;
__END__

=head1 DESCRIPTION

CmdArgs can be used in two ways: static and dynamic.
Dynamic usage means, that you create an object with C<declare> method and
then apply C<parse> method to prase the string or command line arguments. For example:

  my $args = CmdArgs->declare('v1.0', options => ...);
  $args->parse;

Next you can call any methods to obtain an option or argument or do whatever you want.

Another way ot use CmdArgs is compile-time parsing of command line arguments.
It has advantages in optimization, cause parsed options and arguments are
represented by constant functions. For example:

  use CmdArgs {
    version => 'v1.0',
    use_cases => [main => ['OPTIONS', '']],
    options => { debug => ['-D'] },
  };
  CmdArgs->throw_errors;
  print "debug option is on\n" if CmdArgs::OPT_debug;

Static use case creates those functions:

=over

=item C<CmdArgs::OPT_*>

Where * is for every option specified in parse declaration.
This function returns value of the corresponding option or C<undef> if option
is not provided to the script.

=item C<CmdArgs::ARG_*>

Where * is for every argument specified in parse declaration.
This function returns value of the corresponding argument or C<undef> if it
is not provided to the script.

=item C<CmdArgs::USE_CASE>

It returns current parsed use case name.

=item C<CmdArgs::throw_errors>

It dies with error message if any errors occurred during parse.

=back

=head1 METHODS

=head2 C<< declare($version, section => value, ...) >>

throws: string

C<$version> is a string, for example, C<'1.0.1'>.

B<SECTIONS:>

=over

=item options

  options => { opt_name => ['opt_declaration', 'option help message', \&action], ...}

I<opt_name> - is the user-defined name of the option.
I<opt_declaration> examples:

C<'key'> - switch option (no arguments) I<key>.

C<'key key_2 key_3'> - the same. I<key>, I<key_2>, I<key_3> are synonims.

C<'key:'> - option with an argument of any type.

C<< 'key:<ARG_NAME>' >> - the same, but use I<ARG_NAME> for argument
name in help message.

C<'key:type'> - option with an argument of I<type> type.

C<'key:type key_2 key_3'> - the same. I<key>, I<key_2>, I<key_3> are synonims.

C<< 'key:type<ARG_NAME> key_2 key_3' >> - the same, but use ARG_NAME
for argument name in help message.

Action-subroutine C<&action> will be executed on each occurance of the option.
Being within action-subroutine you can use given option's argument by accessing
C<$_[0]> or C<$_> variables. Their values are identical.

Options '--help' and '--version' are automatically generated.

You can hide an option from the help message,
by specifying explicit C<undef> value for its description, e.g.:

  options => { hiden_opt => ['--hiden', undef], }

=item groups

Named groups of options.

  groups => { group_name => [qw(opt_1 opt_2 ...)], }

If I<groups> section is missed, by default there is I<OPTIONS>
group contained all options.

=item use_cases

It declares use cases, that is alternate sequences of options and arguments.

  use_cases => { use_case_name => ['atoms_list', 'use case help message'], }

where:

C<atoms_list = list of space separated atoms>

C<atom = group_name | opt_name | arg_name>

C<group_name> - means that at this place an options from specified
group can appear.
C<~group_name> can be used to make options from the group to appear at any place after this position.

C<opt_name> - option I<opt_name> must be placed here.

C<opt_name?> - option I<opt_name> can appear at this position.

C<~opt_name> - option I<opt_name> must appear at any place after this position at least once.
If at the occurrence place should be mandatory option, this option must appears somewhere else.

C<~opt_name?> - option I<opt_name> can appear at any place after this position.

C<arg_name> - an argument named I<arg_name>.

C<arg_name:> - the same.

C<arg_name:type> - an argument with value of the specified type.

C<arg_name:type...> - a typed array of arguments. One or more arguments are permitted.

C<arg_name...?> - array of arguments. Zero or more arguments are permitted.

C<arg_name?> - optional argument

To preserve use-cases order you should use [] instead of {}:

  use_cases => [ use_case_name => [ ... ], ... ]

If I<use_cases> section is missed, by default there is I<main>
use case declared as C<['OPTIONS args...', '']>.

=item restrictions

  restrictions => ['opt_1|opt_2|opt_3', 'opt_4|opt_1', ... ]

That is, I<opt_1>, I<opt_2> and I<opt_3> can not appear simultaneously.
And I<opt_4> and I<opt_1> also can not appear simultaneously.

=back

=head2 C<parse($string)>

throws: C<Exceptions::List>

Parse C<$string> or C<@ARGV> array if C<$string> is not specified.

=head2 C<parse_begin>

Start the partial parsing.
It should be followed by calls of C<parse_part> and the final C<parse_end>.
For example,

  $args->parse_begin;
  $args->parse_part(\@ARGV);
  $args->parse_end;

That code is doing the same thing as the single call C<$args-E<gt>parse>.

=head2 C<parse_part(\@args)>

throws: C<Exceptions::List>

Parse the specified portion of arguments.
Before the first call, the state of the parser should be cleared with
C<parse_begin>.
This method allows to parse the part of arguments and make a decision to parse
the next or not.
Use C<parse_end> to finish arguments parsing.

=head2 C<parse_end>

throws: C<Exceptions::List>

The method completes arguments partial parsing and throws any exceptions occurred.
See C<parse_begin> and C<parse_part> methods.

=head2 C<arg($name)>

Get argument with name C<$name>.
If argument is specified as C<name...> returns a reference to the array.

=head2 C<opt($name)>

Get value of the C<$name> option.

=head2 C<opt_or_default($name, $default_value)>

If option C<$name> is specified, this method returns option C<$name> value.
Otherwise, it returns C<$default_value>.

=head2 C<is_opt($name)>

Check whether the C<$name> option is appeared.

=head2 C<args> [deprecated]

It returns a hash contained all parsed arguments.

=head2 C<opts> [deprecated]

Return a hash contained all parsed options.

=head2 C<use_case>

Return name of parsed use case.

=head2 C<print_help> [deprecated]

It prints the version message and help text.

=head2 C<print_usage_and_exit> [deprecated]

It prints the usage message and exits with code -1.

=head2 C<print_version> [deprecated]

It prints the version message.

=head1 EXPORT

By default it exports nothing. You may explicitly import folowing:

=head2 C<ptext($text)>

It removes every single end of line from C<$text> and returns result.
So you can write something like that:

  use_cases => [ main => ['OPTIONS args...', ptext <<EOF] ],
  A long
   description
   with invisible line breaks.

  New paragraph.
  EOF

=head1 TYPES

To declare a new type, a corresponding package should be defined.
To define C<MyType> there should be package named C<CmdArgs::Types::MyType>,
that contains subroutine C<check>.
Subroutine C<check> must validate argument by returning positive boolean value.
For example:

  {
    package CmdArgs::Types::MyTypeName;
    sub check
    {
      my ($class, $arg) = @_;
      -f $arg or die "'$arg' is not a file\n"
    }
  }

The lazy way to define a C<Foo> type:

  *CmdArgs::Types::Foo::check = sub { $_[1] eq 'foo' };

=head1 CUSTOMIZATION OF HELP

Generation of help is the one of main reasons this package exist.
The engine smartly adopts to terminal width to avoid the text look like a mess.
There is a number of methods that controls the help text generation.
You can redefine some of them to reach the desired result.
A method could be changed with inheritance or by the direct replacing in current scope.

=head2 Methods of help customization.

=head3 set_help_params($self, %params)

  $args->set_help_params(
    key_indent => 2,
    line_indent => 0,
    opt_descr_indent => 17,
    kd_min_space => 4,
    max_gap => 15
  );

It sets the specified parameters.

=over 12

=item key_indent

The indent from the left to the first key of option.

=item line_indent

The indent of the first line of an option description.

=item opt_descr_indent

The indent from the left to an option description.

=item kd_min_space

The minimal space between the options keys and its description.

=item max_gap

Formatter tries to avoid break words, but does it to avoid to much empty space on the right.
The parameter specifies the maximum right empty space before formatter decides to break the word.

=back

=head3 get_help_params($self)

  my %params = $args->get_help_params;

Returns all current parameters.

=head2 Methods of help customization by redefinition.

=head3 usage_custom_usecases($self, [$uc_name, $uc_scheme, $uc_description],...)

  $usage_message = $args->usage_custom_usecases(
    ['main', 'OPTIONS args...', 'Description of the main use case.'],
    ['second', '', 'Description of the second use case.'],
  );

It generates usage text.

=head3 help_custom_usecases(['usecase', 'scheme', 'descr'],...)

  $help_message = $args->help_custom_usecases(
    ['main', 'OPTIONS args...', 'Description of the main use case.'],
    ['second', '', 'Description of the second use case.'],
  );

It generates the use cases section of help text.

=head3 help_custom_groups_filter(@group_names)

  @group_names = $args->help_custom_groups_filter(@all_group_names);

It is invoked with all existing group names as arguments.
The method returns a list of group names that will appear in help text in the specified order.

For example if you want to remove group I<ABOUT> from the text, use this:

  *CmdArgs::help_custom_groups_filter = sub {
    shift; #< remove $self from @_
    sort grep $_ ne 'ABOUT', @_
  };

=head3 help_custom_group($self, $group_name)

  $help_message .= $args->help_custom_group('ABOUT');

It generates the cap of options group.
By default the method returns the string containing the group name.
You can redefine it to add groups description just before its options:

  {package MyCmdArgs; use parent 'CmdArgs';
    my %groups_descr = (
      ABOUT => "These options can appear anywhere.",
      OPTIONS => "The handy script options.",
    );
    sub help_custom_group_name {
      "$_[1]:\n$groups_descr{$_[1]}\n\n"
    };
  }
  my $args = MyCmdArgs->declare(...);

=head3 help_custom_options_filter($self, $group_name, @opt_names)

  @opt_names = $args->help_custom_options_filter(ABOUT => qw(help version));

It is invoked with the group name and all its options names.
The method returns a list of option names that will appear in help text in the specified order.
You can redefine it to change the order or remove some options.

=head3 help_custom_option($self, $opt_name, [@keys], $arg_type, $arg_name, $descr)

  # opt_1  => ['-f:Filename<FILE> --filename', 'Read the FILE.'],
  $help_message .= $args->help_custom_option(
     'opt_1', [qw(-f --filename)], 'Filename', 'FILE', 'Read the FILE.');

This method generates text string for the option.

=head1 EXAMPLE

  #!/usr/bin/perl -w
  use strict;
  use CmdArgs;
  use CmdArgs::BasicTypes;

  # Declare type to fail, when not existing files are specified as source files.
  {
    package CmdArgs::Types::EPath;
    sub check { -e $_[1] or die "file '$_[1]' does not exist\n" }
  }

  my $verb = 0; #< used as verbose level

  my $args = CmdArgs->declare(
    '1.0',
    use_cases => [
      single => ['~OPTIONS file1:EPath file2:NotDir', 'Copy one file to another.'],
      multi  => ['~OPTIONS files:EPath... dest_dir:Dir', 'Copy files to directory.'],
    ],
    options => {
      recursive => ['-r --recursive', 'Copy directories recursively.'],
      force => ['-f --force', 'Force copying.'],
      log_level => ['--log_level:Int<<level>>', 'Set log_level to <level>.'],
      verbose => ['-v --verbose', 'More verbose. -vv even more.', sub { $verb++ } ],
    },
  );

  # Set parameters to customize help message.
  $args->set_help_params(key_indent => 4, opt_descr_indent => 25, kd_min_space => 2);

  # When $args->parse fails, it will die with help message.
  $args->parse;

  ## print information on verbose level 2 ##
  if ($verb > 1){
    printf "log_level = %i\n", $args->opt_or_default('log_level', 3);
    $args->is_opt('force')     && print "Force copy.\n";
    $args->is_opt('recursive') && print "Copy directories recursively.\n";
  }

  # This script actually does nothing, just prints messages instead of real copying.
  if ($args->use_case eq 'single'){
    ## copy one file to another ##
    my $file1 = $args->arg('file1');
    my $file2 = $args->arg('file2');
    print "copy '$file1' to '$file2'\n" if $verb > 0;
  }
  else {
    ## copy files to directory ##
    my @files = @{ $args->arg('files') };
    my $dir = $args->arg('dest_dir');
    print "copy:\n", map("  $_\n", @files), "to directory '$dir'\n" if $verb >0;
  }
  print "done\n";


=head1 AUTHOR

  Alexander Smirnov <zoocide@gmail.com>

=cut

