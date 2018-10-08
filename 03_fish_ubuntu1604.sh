#!/bin/bash

set -eu

HOST_NAME='dev-hogehoge'
ALLOW_PORT_ARRAY=(
50010
80
8080
8000
)

set +e
sudo ls /root/ 1>/dev/null 2>&1
if [ $(echo $?) -ne 0 ]; then echo 'ローカルでsudoが実行できないため、中断しました' ; exit 1 ; fi

sepline=$(for i in $(seq 1 $(tput cols)) ; do echo -n '#' ; done ; echo ;)

# fishをインストール
# ===================================================================================================
echo -e "${sepline}\nfish をインストールします" ; sleep 2
echo -e "
if [ -z \"\$(sudo cat /etc/shells | grep -E 'fish$')\" ]; then
    sudo apt-add-repository ppa:fish-shell/release-2
    sudo apt-get update
    sudo apt-get install fish
fi
" | sudo /usr/bin/ssh -t ${HOST_NAME}
echo -e "
SHELL_PATH=\$(sudo cat /etc/shells | grep -E 'fish$')
if [ -n \"\$SHELL_PATH\" ]; then
    chsh -s \$SHELL_PATH
    mkdir -p ~/.config/fish
    echo 'set -g -x PATH /usr/local/bin \$PATH' > ~/.config/fish/config.fish
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
fi
" | sudo /usr/bin/ssh -t ${HOST_NAME}
# ===================================================================================================

echo -e "${sepline}\n全ての設定が完了しました。"

exit 0
