use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Po4a',
    'VERSION_FROM'	=> 'Locale/Po4a/TransTractor.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Locale::gettext' => '1.01',
                            'SGMLS' => ''}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Tools for helping translation of documentation',
       AUTHOR     => 'Martin Quinson <martin.quinson@tuxfamily.org>\n'.
                     'Denis Barbier <barbier@linuxfr.org>') : ()),
);
