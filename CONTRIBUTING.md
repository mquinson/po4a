This project welcomes contributions! And this file intend to get you
at full speed as quickly as possible.

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
being dedicated to one step of the [translation workflow](https://po4a.org/man/man7/po4a.7.php#lbAJ)
([po4a-translate](https://po4a.org/man/man1/po4a-translate.1.php),
[po4a-updatepo](https://po4a.org/man/man1/po4a-updatepo.1.php), and
also
[po4a-gettextize](https://po4a.org/man/man1/po4a-gettextize.1.php)).
Some [other tools](https://po4a.org/man/) are built on top of the
transtractors.

Finally, the [po4a command](https://po4a.org/man/man1/po4a.1.php) tool
takes automatically care of the translation workflow, updating the po
files and translations on need.

# Finding something to hack

- Check the [GitHub issues](https://github.com/mquinson/po4a/issues).
  Search in particular for the tasks are marked "new comer", as they
  should be accessible even if you're just starting with the po4a
  development.
- Check the [Debian bug reports](https://bugs.debian.org/cgi-bin/pkgreport.cgi?src=po4a),
  since most of these reports are not related to Debian in any way.
  Actually, they should be forwarded to the GitHub issue tracker, but
  it's easier to read them on Debian directly. 
  [Some of them](https://bugs.debian.org/cgi-bin/pkgreport.cgi?src=po4a;tag=newcomer)
  are tagged as "new comer".
- Check the [TODO] file in the archive. This file often gets outdated,
  but you may find some inspiring notes.
- Add support for a new format. The best is to add support for a
  format that you need yourself, or to convince some prospective users.
  There is no better testing to a new TransTractor than the
  translation of a large document used in production somewhere. Don't
  forget to add all relevant tests to your format.
- po4a comes with a fairly large amount of documentation. You are
  welcome to fix or report any typo or errors. It would be good to improve
  this documentation, for example with the [Google documentation style
  guide](https://developers.googleblog.com/2017/09/making-google-developers-documentation.html)
  but remember that our documentation is translated is a dozen of
  languages. Improve it as much as possible, but avoid superfluous
  changes when possible.

Finally, we are playing with the idea of reimplementing po4a in Python
to increase the amount of potential contributors. A proof of concept
of the TransTractor design in Python would be welcome.

# Testing your changes

You should of course make sure that your PR does not break any test to
get accepted. If you fix an issue or add a feature, we may be
reluctant to integrate your change without a new dedicated test, to
ensure that bugs won't resurface in the future.


```sh
  perl Build.PL
  ./Build test
```

*Test dependencies:*

- On Debian:
  `docbook-xml texlive-binaries libhtml-parser-perl libmodule-build-perl opensp docbook`
- On Fedora 24 (if you installed from the rpm po4a package):
  `perl-SGMLSpm perl-TermReadKey perl-Text-WrapI18N perl-Module-Build
  perl-Test-Simple perl-Unicode-LineBreak perl-HTML-TokeParser-Simple
  docbook-dtds`

When writing or improving a test, you probably want to select the test
to run, and make it verbose. The tests are executed from the t/tmp
directory.

```
  ./Build test --test_files t/32-yaml.t verbose=1
```


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
wlc lock
wlc commit
wlc push
# Merge the pull request on github
# Do and commit your local changes
perl Build.PL
./Build 
git commit -m "update po files" po
git push 
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
  - `git pull`
- Bump the version number in lib/Locale/Po4a/TransTractor.pm and
  regenerate the building script: `perl Build.PL`
- Check that `./Build test` reports no error.
- Check NEWS
  - It documents all recent changes found in git logs.
  - It contains a release name and a release date.
- Build the archive: `./Build dist`
  - Interrupt it if the MANIFEST is out of sync, and then fix it by
    adding the missing files to MANIFEST (or MANIFEST.SKIP if they
    should not be released to the users)
- Commit your changes, eg with commit log like "Releasing v0.XXX"
- Tag the git and push it: `git tag v0.XXX && git push tags`
- Edit the release on [GitHub](https://github.com/mquinson/po4a/releases).
  - Reuse the release name and paste the changelog of this release.
  - Also upload the tarball to the github release: the file META.yml
    is missing from the tarball generated automatically (see #115).
- Announce the release on the Mailing List.

- Put a template in NEWS (using `figlet v0.XXX`)
