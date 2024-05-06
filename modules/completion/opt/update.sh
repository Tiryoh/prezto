#!/usr/bin/env zsh


if [ "$1" = "git" ]; then
	curl -sL https://github.com/git/git/raw/master/contrib/completion/git-completion.zsh > _git
	curl -sL https://github.com/git/git/raw/master/contrib/completion/git-completion.bash > git-completion.bash
elif [ "$1" = "nodebrew" ]; then
	curl -sL https://github.com/hokaccha/nodebrew/raw/master/completions/zsh/_nodebrew > _nodebrew
elif [ "$1" = "catkin" ]; then
	curl -sL https://raw.githubusercontent.com/catkin/catkin_tools/main/completion/_catkin >| _catkin
elif [ "$1" = "docker-compose" ]; then
	curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
elif [ "$1" = "gh" ]; then
	gh completion -s zsh >| _gh
elif [ "$1" = "yq" ]; then
	yq shell-completion zsh >| _yq
else
	echo "Nothing to do..."
fi

echo File checking...
grep "</html" -rl . --exclude=update.sh && { echo error found!; exit 1; } || echo OK.
