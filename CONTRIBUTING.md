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


# Reminder for the po4a maintainers

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
./Build postats
git commit -m "update po files"
git push 
wlc pull
wlc unlock
```

## Releasing po4a

Here is the checklist of things to remember when releasing po4a:

- Integrate all pending translations:
  - `wlc commit && wlc push`
- Bump the version number in lib/Locale/Po4a/TransTractor.pm and
  regenerate the building script: `perl Build.PL`
- Check that `./Build test` reports no error.
- Check NEWS
  - It documents all recent changes found in git logs.
  - It contains a release name and a release date.
- Build the archive:
  - `./Build dist`
  - Interrupt it if the MANIFEST is out of sync (by either adding the
    files to MANIFEST or MANIFEST.SKIP if they should not be released to
    the users)
- Tag the git and push it:
  - `git tag v0.XXX && git push tags`
- Edit the release on [GitHub](https://github.com/mquinson/po4a/releases).
  Reuse the release name and paste the changelog of this release.
- Announce the release on the Mailing List.

- Put a template in NEWS (using `figlet v0.XXX`)
