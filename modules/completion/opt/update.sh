#!/usr/bin/env zsh


if [ "$1" = "gibo" ]; then
	curl -sL https://github.com/simonwhitaker/gibo/raw/master/shell-completions/gibo-completion.zsh > _gibo
fi
if [ "$1" = "git" ]; then
	curl -sL https://github.com/git/git/raw/master/contrib/completion/git-completion.zsh > _git
	curl -sL https://github.com/git/git/raw/master/contrib/completion/git-completion.bash > git-completion.bash
fi
if [ "$1" = "nodebrew" ]; then
	curl -sL https://github.com/hokaccha/nodebrew/raw/master/completions/zsh/_nodebrew > _nodebrew
fi
if [ "$1" = "catkin" ]; then
	curl -sL https://github.com/catkin/catkin_tools/raw/master/completion/_catkin > _catkin
fi
if [ "$1" = "docker-compose" ]; then
	curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
fi