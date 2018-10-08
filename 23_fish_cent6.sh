#!/bin/bash

set -eu

sepline=$(for i in $(seq 1 $(tput cols)) ; do echo -n '#' ; done ; echo ;)

# fishをインストール
# ===================================================================================================
echo -e "${sepline}\nfish をインストールします" ; sleep 2
if [ -z "$(sudo cat /etc/shells | grep -E 'fish$')" ]; then
    cd /etc/yum.repos.d/
    wget https://download.opensuse.org/repositories/shells:fish:release:2/CentOS_6/shells:fish:release:2.repo
    yum install -y fish
fi
SHELL_PATH=$(sudo cat /etc/shells | grep -E 'fish$')
if [ -n "$SHELL_PATH" ]; then
    chsh -s $SHELL_PATH
    mkdir -p ~/.config/fish
    echo 'set -g -x PATH /usr/local/bin $PATH' > ~/.config/fish/config.fish
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
fi
# ===================================================================================================

exit 0
