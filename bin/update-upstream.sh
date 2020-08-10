#!/usr/bin/env bash
set -eu

git clone -b upstream-master git@github.com:Tiryoh/prezto.git /tmp/prezto
pushd /tmp/prezto
  git remote add upstream https://github.com/sorin-ionescu/prezto.git
  git fetch upstream
  git merge upstream/master --no-edit
  git push origin HEAD:upstream-master > /dev/null 2>&1
popd
