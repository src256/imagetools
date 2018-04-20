#!/bin/sh

export ANYENV_ROOT="$HOME/.anyenv"
if [ -d "$ANYENV_ROOT" ]; then
    export PATH="$HOME/.anyenv/bin:/usr/local/bin:$PATH"
    eval "$(anyenv init -)"    
fi

#export PATH="$HOME/.rbenv/bin:$PATH:/opt/local/bin"
#if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

cd `dirname $0`
#rbenv versions
#mogrify
bundle exec ruby exe/imagefilter "$@"


