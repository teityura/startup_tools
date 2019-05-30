#!/bin/bash

set -eu

HOST_NAME='hoge-host' # ~/.ssh/configに登録したいホスト名
SEC_NAME="${HOST_NAME}-rsa"
HOST_IP='0.0.0.0' # 接続先IP
PORT=50010 # お好きなポート
USER_NAME='cloud'
SEP=$(for i in $(seq 1 $(tput cols)) ; do echo -n '#' ; done ; echo ;)


# ==============================================================================
# ローカルとリモートの権限周りを確認
# ==============================================================================
echo -e "${SEP}\nローカルとリモートの権限を確認します\n${SEP}" ; sleep 3
set +e
sudo ls /root/ 1>/dev/null 2>&1
if [ $(echo $?) -ne 0 ]; then
    echo 'ローカルでsudoが実行できないため、中断しました' ;
    exit 1 ;
fi
echo 'sudo ls /root/ 1>/dev/null 2>&1' | /usr/bin/ssh -t ${USER_NAME}@${HOST_IP}
if [ $(echo $?) -ne 0 ]; then
    echo 'リモートでsudoが実行できないため、中断しました' ;
    echo '参考情報 : http://teityura.wjg.jp/engineer/パスワード無しでsudo'
    exit 1 ;
fi
set -e


# ==============================================================================
# RSAキーペアを作成
# ==============================================================================
echo -e "${SEP}\nRSAキーペアを作成します\n${SEP}" ; sleep 3
sudo mkdir -p ~/.ssh
sudo chown -R ${USER}:${USER} ~/.ssh/
chmod 700 ~/.ssh/
cd ~/.ssh/
ssh-keygen -t rsa -b 4096 -C "teityura@teityura.com" -N "" -f $SEC_NAME
ssh-keygen -l -f $SEC_NAME
PUB_RAW=$(cat ${SEC_NAME}.pub)
grep $HOST_IP known_hosts 2>/dev/null && sed -i.bak -E "/.*($HOST_IP).*/d" known_hosts


# ===================================================================================================
# 接続先に公開鍵を設置
# ===================================================================================================
# 1.authorized_keysを追加
# 2.iptablesの設定追加
# 3.SSHDの設定変更
echo -e "${SEP}\n公開鍵を設置し、SSHDの設定を変更します\n${SEP}" ; sleep 3
echo -e "
sudo mkdir -p ~/.ssh
sudo chown -R ${USER_NAME}:${USER_NAME} ~/.ssh/
chmod 700 ~/.ssh
echo '$PUB_RAW' | tee -a ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
sudo iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
sudo sed -i.bak -E \\
 -e 's/^#?Port.*/Port $PORT/g' \\
 -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' \\
 -e 's/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/g' \\
 -e 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' \\
 -e 's@^#?AuthorizedKeysFile.*@AuthorizedKeysFile %h/.ssh/authorized_keys@g' \\
/etc/ssh/sshd_config
sudo diff -u /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
sudo /etc/init.d/ssh restart
" | /usr/bin/ssh -t ${USER_NAME}@${HOST_IP}


# ===================================================================================================
# ~/.ssh/config に設定を追記
# ===================================================================================================
echo -e "${SEP}\n~/.ssh/configに設定を追記します\n${SEP}" ; sleep 3
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
echo -e "${SEP}\n接続テストを開始します\n${SEP}" ; sleep 3
echo "echo 'Hello ${HOST_NAME} !'" | /usr/bin/ssh -t $HOST_NAME -v
if [ $(echo $?) -ne 0 ]; then
    echo '接続に失敗しました'
    exit 1
else
    echo '接続に成功しました'
    exit 1
fi
echo -e "${SEP}\n全ての設定が完了しました"

exit 0
