# po4a welcomes contributions! 

Even if you have never contributed to any Open Source project in the past,
you are welcome: we are willing to help and mentor you here. Check on 
[First Timer](https://www.firsttimersonly.com/) to get started with 
the basics of Open Source development and Social Coding.

# Software Architecture

po4a is architectured around the idea of TransTractors, that are
specific parsers in charge of separating the document structure from
the translatable content, and to reinject the translated content back
into the structure.

You can learn more on TransTractors in
[their documentation](https://po4a.org/man/man3/Locale::Po4a::TransTractor.3pm.php),
or by browsing the code of
[all existing ones](https://github.com/mquinson/po4a/tree/master/lib/Locale/Po4a).
Also don't miss the [project overview](https://po4a.org/man/man7/po4a.7.php)
if you did not read it yet.

Several binaries are built around these TransTractors, each of them
are dedicated to one step of the [translation workflow](https://po4a.org/man/man7/po4a.7.php#lbAJ)
([po4a-translate](https://po4a.org/man/man1/po4a-translate.1.php),
[po4a-updatepo](https://po4a.org/man/man1/po4a-updatepo.1.php), and
also
[po4a-gettextize](https://po4a.org/man/man1/po4a-gettextize.1.php)).
Some [other tools](https://po4a.org/man/) and are built on top of the
transtractors.

Finally, the [po4a command](https://po4a.org/man/man1/po4a.1.php) tool
takes automatically care of the translation workflow, updating the po
files and translations when needed.

# Finding something to hack

- Check the [GitHub issues](https://github.com/mquinson/po4a/issues).
  Search in particular for the tasks are marked [beginner
  friendly](https://github.com/mquinson/po4a/issues?q=is%3Aissue+is%3Aopen+label%3A%22beginner+friendly%22),
  as they should be accessible even if you're just starting with the
  po4a development.
- Check the [Debian bug reports](https://bugs.debian.org/cgi-bin/pkgreport.cgi?src=po4a),
  since most of these reports are not related to Debian in any way.
  Actually, they should be forwarded to the GitHub issue tracker, but
  it's easier to read them on Debian directly.
  [Some of them](https://bugs.debian.org/cgi-bin/pkgreport.cgi?src=po4a;tag=newcomer)
  are tagged as "new comer" (this list may be currently empty when you
  click it, though).
- Check the [TODO](https://github.com/mquinson/po4a/blob/master/TODO)
  file in the archive. This file often gets outdated, but you may find
  some inspiring notes. 
- Add support for a new format. The best is to add support for a
  format that you need yourself, or to convince some prospective users.
  There is no better testing to a new TransTractor than the
  translation of a large document used in production somewhere. Don't
  forget to add all relevant tests to your format.
- po4a comes with a fairly large amount of documentation. You are
  welcome to fix or report any typo or errors. It would be good to improve
  this documentation to follow the [Best Practices](http://www.writethedocs.org/guide/) 
  from WriteTheDocs, and many sections would need a full rewriting to
  be in proper english. We should however refrain from superfluous
  changes when possible to reduce the burden on our translators (hint:
  rephrasing globish to english is NOT a superfluous change).


# Testing your changes

Of course you should make sure that your PR does not break any test to
get accepted. If you fix an issue or add a feature, we may be
reluctant to integrate your change without a new dedicated test, to
ensure that bugs won't resurface in the future.


```sh
  perl Build.PL
  ./Build test
```

*Test dependencies:*

- On Debian: check the .travis.yml file in the root directory for a full list.
- On Fedora 24 (if you installed from the rpm po4a package):
  `perl-SGMLSpm perl-TermReadKey perl-Text-WrapI18N perl-Module-Build
  perl-Test-Simple perl-Unicode-LineBreak perl-HTML-TokeParser-Simple
  docbook-dtds`
- On openSUSE Leap 15.2:
  `perl-SGML-Parser-OpenSP perl-TermReadKey perl-Text-WrapI18N perl-Module-Build
  perl-Test-Simple perl-Unicode-LineBreak perl-HTML-TokeParser-Simple
  docbook-dtds`

When writing or improving a test, you probably want to select the test
to run, and make it verbose. The tests are executed from the "_t_"
directory.

```
  ./Build test --test_files t/25-yaml.t verbose=1
```

The PERL5LIB variable can be used to run your modified modules without
reinstalling everything:

```
  PERL5LIB=../lib/ perl ../po4a-normalize -f text -o markdown t-20-text/PandocYamlFrontMatter.md
```

To the opposite, if you want to test the installed binaries instead of
the local ones, simply set the AUTOPKGTEST_TMP variable:

```
  AUTOPKGTEST_TMP=1 ./Build test
```

## Writing a test

In order to define a new test, you can use some convenience
helpers. If you follow some conventions, you don't have to
write much boilerplate code.

Each test is defined using a perl hash with several keys.
Every test needs to have the key "_doc_", which contains
a short description of the test.

If you need to test the output of a module, it should suffice
to define a second key in the hash, named "_normalize_".
This key points to a string which can be used for the
script `po4a-normalize`. See for example the YAML tests
for some easy test definitions.

The "_normalize_" tests expect to find at least four files
in the corresponding test directory:

1. The master file used as input for po4a.
2. The expected .pot file, using the same name as the master
   file. The extension is changed to "_.pot_".
3. The expected translated file, again using the same name
   as the master file. The extension is changed to "_.out_".
4. The expected messages on stderr, again using the same name
   as the master file. The extension is changed to "_.err_".

Here's an example. If you define the following hash:

```
push @tests,
  {
    'doc'       => "YAML UTF-8 test",
    'normalize' => "-f yaml -M UTF-8 t-25-yaml/yamlutf8.yaml",
  };
```

... you need to have at least the following four files:

```
t-25-yaml/yamlutf8.yaml
t-25-yaml/yamlutf8.pot
t-25-yaml/yamlutf8.out
t-25-yaml/yamlutf8.err
```

You can also check that the translation works, using the file
name of the master file, with the extension changed to
"_.trans.po_". The actual language does not matter, the
extension is always the same. Similarly to the above files,
you also need to add the expected translated output and
the expected messages from stderr:

```
t-25-yaml/yamlutf8.trans.po
t-25-yaml/yamlutf8.trans.out
t-25-yaml/yamlutf8.trans.err
```

If you need to have more control over your tests, you can
use the "_run_" and "_test_" keys in the hash. The "_run_"
key defines the commands to run; the "_test_" key has
the commands to check the generated output.

Last, not least, you can mark a test as TODO with the
hash key "_todo_". Usually, it's best to write a short
description or to add a link to the online bug report.

Example:

```
push @tests,
  {
    'doc'       => 'WML normalisation test',
    'normalize' => "-f wml t-22-wml/general.wml",
    'todo'      => "https://github.com/mquinson/po4a/issues/138",
  };
```

# Submitting Your Patch

Before all, please run ``tidyall -git`` to ensure that your changes
stick to the project quality standards. You should also consider using
a [git pre-commit hook](https://metacpan.org/pod/Code::TidyAll::Git::Precommit) 
to that extend.

When submitting a patch, please either fill a Pull Request on 
[mquinson/po4a](https://github.com/mquinson/po4a) on GitHub or a Merge
Request on [mquinson/po4a](https://salsa.debian.org/mquinson/po4a)
salsa instance of GitLab. If you go for the salsa server, please do
not fill your MR against the debian/po4a repository that is dedicated
to the packaging of the software (unless, of course, your change is
against the packaging). Your request should be based on the latest
code in the master branch. Please rebase your work as needed.

Finally, all PRs should include an update the the NEWS file. Please follow
the format and briefly describe the change and provide a reference to
the PR or issue. Please place your update at the bottom of the list
in the appropriate section for the next, as yet unreleased, version.
Please add sections as needed for various formats.

# Translating

You can translate the runtime messages, the documentation and the
website. Please prefer the weblate interface at
https://hosted.weblate.org/projects/po4a/ even if we also accept pull
requests for that.

On need, you can manually refresh the translation files as follows:
```sh
 perl Build.PL
 ./Build postats # Refresh the pot and po files (both doc and bin)
```

The documentation is written using the PerlDoc format (pod), as
described here: http://perldoc.perl.org/perlpod.html

# Reminder for the po4a maintainers

This is mostly a note to ourselves. But who knows? Maybe you are (or
soon will be) one of us? You're welcome here.

## Interacting with weblate

It's easy to get a conflict when changing the po files while the
translators are working. To avoid this, you should use the [weblate
client](https://docs.weblate.org/en/latest/wlc.html#wlc). Add the
following content to `~/.config/weblate`:
```
[keys]
https://hosted.weblate.org/api/ = APIKEY (find it on https://hosted.weblate.org/accounts/profile/#api)
```

Then, when you have to change the po files, lock weblate, flush
weblate, integrate the changes locally, push your changes to the git,
pull them on weblate, and unlock it. You need to be a maintainer of
the project on weblate for that.
```sh
git pull salsa master ; git push # Get the German and Italian translations
wlc lock
wlc commit
wlc push
# Merge the pull request on github
git pull
# Do and commit your local changes
perl Build.PL
./Build
git commit -m "update POT files" po/*/*.pot # don't commit PO files to reduce conflicts; weblate update them
git push
git push salsa
wlc pull
wlc unlock
```

Here is how to integrate a PR that fixes typos in english without
fuzzying the translations (using msguntypot):
```sh
wlc lock && wlc commit && wlc push
# Merge the weblate PR on github
git pull
# Merge the other PR on github
git pull
rm -rf po_orig ; cp -r po po_orig # Copy existing po files
# Fix the typo in the doc
./Build postats # Refresh the pot and po files (both doc and bin)
cp po_orig/bin/*.po po/bin # Restore po files; msguntypot will handle typos in msgids
cp po_orig/pod/*.po po/pod
msguntypot -o po_orig/bin/po4a.pot     -n po/bin/po4a.pot     po/bin/*.po
msguntypot -o po_orig/pod/po4a-pod.pot -n po/pod/po4a-pod.pot po/pod/*.po
rm -rf po_orig
git commit -m "unfuzzy translations after the typo fixes in english" po
git push
wlc pull && wlc unlock
```

## Releasing po4a

Here is the checklist of things to remember when releasing po4a:

- Integrate all pending translations:
  - `wlc commit && wlc push`
  - merge the pull request
  - `git pull && git pull salsa master`
- Bump the version number in lib/Locale/Po4a/TransTractor.pm and
  regenerate the building script: `perl Build.PL`
- Check that `./Build test` reports no error.
- Generate translation statistics: `./Build postats`
- Check NEWS
  - It documents all recent changes found in git logs.
  - It contains a release name and a release date.
  - It contains the translation statistics. Paste here the output from the command above.
- Build the archive: `./Build dist`
  - Interrupt it if the MANIFEST is out of sync, and then fix it by
    adding the missing files to MANIFEST (or MANIFEST.SKIP if they
    should not be released to the users)
- Commit your changes, eg with commit log like "Releasing v0.XXX"
- Tag the git and push it: `git tag v0.XXX && git push --tags`
- Edit the release on [GitHub](https://github.com/mquinson/po4a/releases ).
  - Reuse the release name and paste the changelog of this release.
  - Also upload the tarball to the github release: the file META.yml
    is missing from the tarball generated automatically (see #115).
- Announce the release on the Mailing List.
- Add a News entry to the website, update VERSION, rebuild it, and re-push it

- Put a template in NEWS (using `figlet v0.XXX`)
- Change the version in lib/Locale/Po4a/TransTractor.pm to 0.XX-alpha
