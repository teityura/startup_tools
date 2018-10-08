#!/bin/bash

set -eu

HOST_NAME='dev-hogehoge'
SEC_NAME="${HOST_NAME}-rsa"
HOST_IP='111.111.111.111'
PORT=50010
USER_NAME='user'

set +e
sudo ls /root/ 1>/dev/null 2>&1
if [ $(echo $?) -ne 0 ]; then echo 'ローカルでsudoが実行できないため、中断しました' ; exit 1 ; fi

# TODO オプションでホスト名変更を実施するか選択できるようにする
echo -e "hostname $HOST_NAME" | sudo /usr/bin/ssh -t ${USER_NAME}@${HOST_IP} 1>/dev/null
set -e

sepline=$(for i in $(seq 1 $(tput cols)) ; do echo -n '#' ; done ; echo ;)

# RSAキーペアを作成
# ===================================================================================================
echo -e "${sepline}\nRSAキーペアを作成します" ; sleep 2
sudo mkdir -p ~/.ssh
sudo chmod 700 ~/.ssh/
cd ~/.ssh/
sudo ssh-keygen -t rsa -b 4096 -C "teityura@teityura.com" -N "" -f $SEC_NAME
sudo ssh-keygen -l -f $SEC_NAME
PUB_RAW=$(sudo cat ${SEC_NAME}.pub)
grep $HOST_IP known_hosts && sed -i.bak -E "/.*($HOST_IP).*/d" known_hosts
# ===================================================================================================

# 接続先に公開鍵を設置
# ===================================================================================================
echo -e "${sepline}\n公開鍵を設置し、SSHDの設定を変更します" ; sleep 2
echo -e"
# ---------------------------------------------------------------------------------------------------
# authorized_keysを追加
# ---------------------------------------------------------------------------------------------------
sudo mkdir -p ~/.ssh
sudo chmod 700 ~/.ssh
sudo echo '$PUB_RAW' > ~/.ssh/${SEC_NAME}.pub
sudo echo '$PUB_RAW' >> ~/.ssh/authorized_keys
sudo chmod 600 ~/.ssh/authorized_keys
# ---------------------------------------------------------------------------------------------------
# iptablesの設定追加
# ---------------------------------------------------------------------------------------------------
sudo iptables -A INPUT -p tcp --dport 50010 -j ACCEPT
# ---------------------------------------------------------------------------------------------------
# SSHDの設定変更
# ---------------------------------------------------------------------------------------------------
sudo sed -i.bak -E \\
    -e 's/^#?Port.*/Port $PORT/g' \\
    -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' \\
    -e 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' \\
    -e 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' \\
    -e 's@^#?AuthorizedKeysFile.*@AuthorizedKeysFile %h/.ssh/authorized_keys@g' \\
sudo /etc/ssh/sshd_config
diff -u /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo /etc/init.d/ssh restart
" | sudo /usr/bin/ssh -t ${USER_NAME}@${HOST_IP}
# ===================================================================================================

# ~/.ssh/config に設定を追記
# ===================================================================================================
echo -e "${sepline}\n~/.ssh/configに設定を追記します" ; sleep 2
echo -e "
# $HOST_NAME
Host $HOST_NAME
 Hostname $HOST_IP
 Port $PORT
 User $USER_NAME
 IdentityFile ~/.ssh/$SEC_NAME
" | tee -a ~/.ssh/config
# ===================================================================================================

# 接続テスト
# ===================================================================================================
echo -e "${sepline}\n接続テストを開始します" ; sleep 2
echo "echo 'Hello ${HOST_NAME} !'" | sudo /usr/bin/ssh -t $HOST_NAME -v
if [ $(echo $?) -ne 0 ]; then
    echo '接続に失敗しました'
    exit 1
else
    echo '接続に成功しました'
    exit 1
fi
# ===================================================================================================

echo -e "${sepline}\n全ての設定が完了しました"

exit 0
