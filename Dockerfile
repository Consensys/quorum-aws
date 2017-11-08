FROM ubuntu:artful

RUN apt-get update

RUN apt-get install -y curl && \
    curl -sSL https://get.haskellstack.org/ | sh

RUN apt-get install -y libgmp-dev libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev pkg-config

ENV SRC /usr/local/src/quorum-aws
WORKDIR $SRC

# GHC
ADD stack.yaml $SRC/
RUN stack setup

# Dependencies
ADD LICENSE.md quorum-aws.cabal $SRC/
RUN stack build --dependencies-only

# Project
ADD Setup.hs $SRC/
COPY app/ $SRC/app/
COPY src/ $SRC/src/
RUN stack install --local-bin-path /usr/local/bin

RUN aws-spam --help
