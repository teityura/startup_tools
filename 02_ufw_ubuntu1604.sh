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

# ファイアウォールの設定変更
# ===================================================================================================
echo -e "${sepline}\nファイアウォールの設定を変更します" ; sleep 2
echo -e "
# IPV6を無効
sed -i.bak -E 's/^IPV6=yes$/IPV6=no/g' /etc/default/ufw
# 一旦ufwを無効
if [ \"\$(sudo ufw status | sed -n -E 's/^Status: (.*)/\\1/p')\" = 'active' ]; then
    sudo ufw disable
fi
# ポート全拒否
sudo ufw default DENY
# 指定ポート許可
for port in ${ALLOW_PORT_ARRAY[@]}; do
    echo \"sudo ufw allow \$port\"
    sudo ufw allow \$port
done
# ufwを有効
sudo ufw --force enable
sudo ufw status
" | sudo /usr/bin/ssh -t ${HOST_NAME}
# ===================================================================================================

echo -e "${sepline}\n全ての設定が完了しました。"

exit 0
