#!/usr/bin/env zsh
#
# Tests the cache-key computation behind cbw/cbwa: _cbw_out_dir in
# runcoms/zshrc. That path decides which build tree a worktree gets, and getting
# it wrong makes two worktrees quietly share one build directory rather than
# fail, so it is worth pinning down.
#
# The function is extracted from runcoms/zshrc rather than reimplemented here, so
# the test cannot drift from the shell it is testing. The extraction relies on
# the `function name() {` ... `}` layout; if that changes the test aborts loudly
# instead of silently testing nothing.
#
# No colcon, no ROS and no network: only zsh and git. Nothing is written under
# ~/.cache/colcon -- the expected paths are compared as strings.
#
# Usage: bin/test-cbw.zsh [path/to/zshrc]

emulate -L zsh
setopt no_unset

ZSHRC=${1:-${0:A:h}/../runcoms/zshrc}
TMP=${TMPDIR:-/tmp}/cbw_out_dir_test.$$
typeset -i pass=0 fail=0

src=$(sed -n '/^function _cbw_out_dir()/,/^}/p' $ZSHRC)
if [[ -z $src ]]; then
    print -u2 "FATAL: _cbw_out_dir not found in $ZSHRC"
    exit 1
fi
eval $src

check() {
    local desc=$1 dir=$2 want=$3 got
    got=$(cd $dir && _cbw_out_dir)
    if [[ $got == $want ]]; then
        print -r -- "  ok   $desc"
        (( pass++ ))
    else
        print -r -- "  FAIL $desc"
        print -r -- "         want: $want"
        print -r -- "         got:  $got"
        (( fail++ ))
    fi
}

rm -rf $TMP && mkdir -p $TMP

# Two distinct repositories, each with a worktree whose directory name is
# literally the same -- the collision the repository-qualified cache key exists
# to prevent. The worktrees must share a basename for this to test anything, so
# they are kept in separate parent directories.
for r in alpha_repo beta_repo; do
    mkdir -p $TMP/${r:s/_repo//}
    git init -q $TMP/${r:s/_repo//}/$r
    git -C $TMP/${r:s/_repo//}/$r commit -q --allow-empty -m init
    git -C $TMP/${r:s/_repo//}/$r worktree add -q $TMP/${r:s/_repo//}/feature-x -b feature-x
done
mkdir -p $TMP/alpha/feature-x/src/pkg/nested $TMP/alpha/alpha_repo/src/pkg

# A bare clone with a worktree hanging off it: there is no .git directory to
# take the parent of, so the repository name comes from the bare directory.
git clone -q --bare $TMP/alpha/alpha_repo $TMP/bare_repo.git
git -C $TMP/bare_repo.git worktree add -q $TMP/bare-wt -b wt1

C=$HOME/.cache/colcon
print -r -- "_cbw_out_dir ($ZSHRC):"
# The two main-worktree cases are what guard --path-format=absolute: without it
# --git-common-dir answers `.git` there, or `../../.git` from a subdirectory, and
# the repository name degrades to `.` or `..`. A linked worktree is unaffected --
# it gets an absolute common dir either way -- so it cannot stand in for these.
check "main worktree"               $TMP/alpha/alpha_repo                    $C/alpha_repo/alpha_repo
check "subdir of main worktree"     $TMP/alpha/alpha_repo/src/pkg            $C/alpha_repo/alpha_repo
check "linked worktree"             $TMP/alpha/feature-x                     $C/alpha_repo/feature-x
# The cwd within a worktree must not change the answer.
check "subdir of linked worktree"   $TMP/alpha/feature-x/src/pkg/nested      $C/alpha_repo/feature-x
check "worktree of bare clone"      $TMP/bare-wt                             $C/bare_repo/bare-wt

a=$(cd $TMP/alpha/feature-x && _cbw_out_dir)
b=$(cd $TMP/beta/feature-x  && _cbw_out_dir)
if [[ $a != $b ]]; then
    print -r -- "  ok   same worktree name in two repos -> distinct dirs"
    (( pass++ ))
else
    print -r -- "  FAIL same worktree name in two repos collided at $a"
    (( fail++ ))
fi

# Outside a repository it must fail rather than invent a path.
if (cd $TMP/.. && _cbw_out_dir >/dev/null 2>&1); then
    print -r -- "  FAIL outside a git repo should return non-zero"
    (( fail++ ))
else
    print -r -- "  ok   outside a git repo returns non-zero"
    (( pass++ ))
fi

rm -rf $TMP
print -r -- ""
print -r -- "pass=$pass fail=$fail"
(( fail == 0 ))
