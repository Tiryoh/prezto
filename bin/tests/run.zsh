#!/usr/bin/env zsh
#
# Runs every *_test.zsh beside this script and reports which files failed.
# Each test file is self-contained and can also be run on its own.
#
# Usage: bin/tests/run.zsh [path/to/zshrc]

emulate -L zsh
here=${0:A:h}
typeset -i failed=0 total=0

for t in $here/*_test.zsh(N); do
    (( total++ ))
    $t "$@" || (( failed++ ))
    print -r -- ""
done

if (( total == 0 )); then
    print -u2 "FATAL: no *_test.zsh found in $here"
    exit 1
fi
if (( failed )); then
    print -r -- "$failed of $total test files FAILED"
    exit 1
fi
print -r -- "all $total test files passed"
