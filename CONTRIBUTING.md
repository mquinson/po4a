# Pull Requests

Your PR are really welcome to improve po4a and/or fix bugs. You should
however make sure that your PR does not break any test to get quickly
accepted.

If you fix an issue, the best is to add a new test to the suite to
ensure that it wont resurface in the future.

# Adding support for a new format

We are welcoming new modules for new formats, provided that you add a
decent amount of tests. 

# Translating

You can translate the runtime messages, the documentation and the
website. Please prefer the weblate interface at
https://hosted.weblate.org/projects/po4a/ even if we also accept pull
requests for that.

On need, you can manually refresh the translation files as follows:
```sh
 perl Build.PL
 ./Build postats
```

# Running tests

```sh
  perl Build.PL
  ./Build test
```

If the test suite reports errors, please report this as a bug, along
with the full output and any other relevant details.

## Test dependencies

Debian packages needed to run the testsuite:
  docbook-xml texlive-binaries libhtml-parser-perl libmodule-build-perl opensp docbook

Fedora 24 packages needed to run the testsuite (from the rpm po4a package):
  perl-SGMLSpm perl-TermReadKey perl-Text-WrapI18N perl-Module-Build
  perl-Test-Simple perl-Unicode-LineBreak perl-HTML-TokeParser-Simple
  docbook-dtds
