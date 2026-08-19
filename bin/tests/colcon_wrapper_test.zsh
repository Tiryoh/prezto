#!/usr/bin/env zsh
#
# Tests the colcon wrapper in runcoms/zshrc: it must run colcon in
# $ROS2_WORKSPACE without moving the caller anywhere.
#
# The wrapper used pushd/popd, which is not a no-op under the directory-stack
# options prezto sets: with PUSHD_IGNORE_DUPS, pushing $ROS2_WORKSPACE while
# already standing in it is dropped as a duplicate, so the following popd pops
# whatever came before and teleports the caller there. Those options are read
# out of modules/directory/init.zsh rather than copied here, so the test follows
# prezto if the module changes.
#
# colcon itself is replaced by a stub that records the directory it ran in, so
# no build happens and neither colcon nor ROS needs to be installed.
#
# Usage: bin/tests/colcon_wrapper_test.zsh [path/to/zshrc]

emulate -L zsh
# NO_UNSET is deliberately not set: the wrapper is exercised under the options an
# interactive prezto shell has, and that is not one of them.

REPO=${0:A:h}/../..
ZSHRC=${1:-$REPO/runcoms/zshrc}
DIRMOD=$REPO/modules/directory/init.zsh
TMP=${TMPDIR:-/tmp}/colcon_wrapper_test.$$
typeset -i pass=0 fail=0

src=$(sed -n '/^function colcon()/,/^}/p' $ZSHRC)
if [[ -z $src ]]; then
    print -u2 "FATAL: colcon() not found in $ZSHRC"
    exit 1
fi
# Only the directory-stack options matter here; pulling in the rest of the
# module (NO_CLOBBER in particular) would change how this script itself behaves.
diropts=$(sed -n 's/#.*$//; /^setopt .*\(PUSHD\|AUTO_CD\)/p' $DIRMOD)
if [[ -z $diropts ]]; then
    print -u2 "FATAL: no directory-stack options found in $DIRMOD"
    exit 1
fi
eval $diropts
eval $src

rm -rf $TMP && mkdir -p $TMP/ws/src/pkg $TMP/ws/install $TMP/elsewhere $TMP/bin
: > $TMP/ws/install/setup.zsh

# Stub colcon: record where it was run, so "did it run, and where" is testable.
cat > $TMP/bin/colcon <<'STUB'
#!/bin/sh
pwd > "$COLCON_STUB_LOG"
STUB
chmod +x $TMP/bin/colcon
PATH=$TMP/bin:$PATH
export COLCON_STUB_LOG=$TMP/ran

short() { print -r -- ${1/#$TMP/\$TMP} }

# want_cwd: where the caller must stand afterwards.
# want_ran: the directory colcon must have run in, or "" for "must not run".
# want_err: pattern stderr must match; omitted means stderr must be silent.
case_() {
    local desc=$1 want_cwd=$2 want_ran=$3 want_err=${4-} got_ran err
    err=$TMP/stderr
    rm -f $COLCON_STUB_LOG
    colcon build --packages-select foo >/dev/null 2>$err
    got_ran=$([[ -f $COLCON_STUB_LOG ]] && cat $COLCON_STUB_LOG)
    local ok=1 why=()
    [[ $PWD == $want_cwd ]] || { ok=0; why+=("cwd: want $(short $want_cwd), got $(short $PWD)") }
    [[ $got_ran == $want_ran ]] || {
        ok=0
        why+=("colcon ran in: want ${want_ran:-<not at all>}, got ${got_ran:-<not at all>}")
    }
    # A stray "directory stack empty" from popd is a failure in its own right,
    # so anything unexpected on stderr fails the case.
    if [[ -n $want_err ]]; then
        [[ $(<$err) == *${~want_err}* ]] || {
            ok=0; why+=("stderr: want *$want_err*, got $(tr '\n' ' ' < $err)")
        }
    else
        [[ ! -s $err ]] || { ok=0; why+=("stderr: $(tr '\n' ' ' < $err)") }
    fi
    if (( ok )); then
        print -r -- "  ok   $desc"
        (( pass++ ))
    else
        print -r -- "  FAIL $desc"
        for w in $why; do print -r -- "         $w"; done
        (( fail++ ))
    fi
}

print -r -- "colcon wrapper ($ZSHRC):"
export ROS2_WORKSPACE=$TMP/ws

# The reported bug: standing in the workspace itself, with somewhere else on the
# directory stack.
dirstack=(); cd $TMP/elsewhere; cd $ROS2_WORKSPACE
case_ "called from the workspace itself"      $TMP/ws          $TMP/ws

# Same spot but nothing on the stack: popd has nothing to pop and complains.
cd $ROS2_WORKSPACE; dirstack=()
case_ "called from the workspace, empty stack" $TMP/ws         $TMP/ws

dirstack=(); cd $ROS2_WORKSPACE/src/pkg
case_ "called from a package subdirectory"    $TMP/ws/src/pkg  $TMP/ws

dirstack=(); cd $TMP/elsewhere
case_ "called from outside the workspace"     $TMP/elsewhere   $TMP/ws

# A missing workspace must stop the build rather than build in the current
# directory, and must say why.
ROS2_WORKSPACE=$TMP/nonexistent
dirstack=(); cd $TMP/elsewhere
case_ "workspace does not exist"              $TMP/elsewhere   "" "no such file or directory"
ROS2_WORKSPACE=$TMP/ws

# No workspace configured: behave like plain colcon, right here.
ROS2_WORKSPACE=
dirstack=(); cd $TMP/elsewhere
case_ "no workspace configured"               $TMP/elsewhere   $TMP/elsewhere
ROS2_WORKSPACE=$TMP/ws

# Inside a worktree outside the workspace the wrapper refuses and points at cbw.
git init -q $TMP/repo && git -C $TMP/repo commit -q --allow-empty -m init
dirstack=(); cd $TMP/repo
case_ "inside a git worktree"                 $TMP/repo        "" "use cbw instead"

cd /; rm -rf $TMP
print -r -- ""
print -r -- "pass=$pass fail=$fail"
(( fail == 0 ))
