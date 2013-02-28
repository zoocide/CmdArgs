use 5.00008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CmdArgs',
    VERSION_FROM      => 'lib/CmdArgs.pm', # finds $VERSION
    PREREQ_PM         => {'Exceptions'        =>  '0.3.0',
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CmdArgs.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Smirnov <zoocide@gmail.com>') : ()),
);
