use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'po4a',
    'VERSION_FROM'	=> 'lib/Locale/Po4a/TransTractor.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Locale::gettext' => '1.01',
                            'SGMLS' => ''}, # e.g., Module::Name => 1.1
    'EXE_FILES'         => ['po4a-gettextize', 'po4a-updatepo',
                            'po4a-translate', 'po4a-normalize'],
    'PMLIBDIRS'          => ['lib/Locale/Po4a'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Tools for helping translation of documentation',
       AUTHOR     => 'Martin Quinson <martin.quinson@tuxfamily.org>\n'.
                     'Denis Barbier <barbier@linuxfr.org>') : ()),
);
