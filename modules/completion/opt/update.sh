#!/usr/bin/env zsh


if [ "$1" = "gibo" ]; then
	curl -sL https://github.com/simonwhitaker/gibo/raw/master/shell-completions/gibo-completion.zsh > _gibo
fi
if [ "$1" = "git" ]; then
	curl -sL https://github.com/git/git/raw/master/contrib/completion/git-completion.zsh > _git
	curl -sL https://github.com/git/git/raw/master/contrib/completion/git-completion.bash > git-completion.bash
fi
