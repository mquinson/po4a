FROM ubuntu:latest

ENV COLUMNS 120
ENV LANG C.UTF-8

COPY . /srv/po4a
WORKDIR /srv/po4a

# Install Debian dependencies.
# The libxml2-utils package provides the xmlcatalog program.
RUN apt update && apt install -y \
    liblocale-gettext-perl libtext-wrapi18n-perl libunicode-linebreak-perl \
    libpod-parser-perl libtest-pod-perl libyaml-tiny-perl libsyntax-keyword-try-perl \
    libsgmls-perl libdevel-checklib-perl libcommonmark-perl libmodule-build-perl \
    gettext docbook-xml docbook-xsl docbook xsltproc libxml2-utils \
    texlive-binaries texlive-latex-base opensp \
    gcc libcmark-dev

# Build
RUN perl Build.PL
RUN ./Build verbose=1

# Test
RUN adduser --disabled-password --gecos 'User for tests' nonroot
RUN mkdir -p tmp
# t/00-perms.t rejects tests running as root but then wants to change permisison inside t/
RUN chown -R nonroot: t tmp
USER nonroot
RUN ./Build test verbose=1
USER root

# Install
RUN ./Build install

