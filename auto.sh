#!/bin/sh
echo -e "\n\e[32;7m【 检查HOSTNAME 】\e[0m"
echo $HOSTNAME | egrep -q '^[a-z]{2}\.[bopt]{4}\.[bopt]{3}$'
if [ $? -eq 0 ]
  then
    echo -e ' \e[36;7m '$HOSTNAME' \e[0m'
else
  echo -e -n '\e[33;1m请输入hostname:\e[0m '
  read input
  echo -e ''$input'' | egrep -q '^[a-z]{2}\.[bopt]{4}\.[bopt]{3}$'
  if [ $? -eq 0 ]
    then
      hostnamectl set-hostname $input
      echo -e ' \e[36;7m '$input' \e[0m  \e[31;5m须重启生效！请重启后再次运行本脚本。 \e[0m'
      exit 1
  else
    echo -e '\e[31;5m 输入有误，请重新运行本脚本！ \e[0m'
    exit 1
  fi
fi
echo -e "\n\e[32;7m【 安装caddy 】\e[0m"
wget -t 5 -O /usr/bin/caddy https://caddyserver.com/api/download
chmod 755 /usr/bin/caddy
groupadd --system caddy
wget -t 5 -P /etc/systemd/system https://github.com/grhooo/private/raw/main/caddy.service
echo -e "\e[32;7m【 安装xray 】\e[0m"
wget -t 5 -O /root/install.sh https://github.com/XTLS/Xray-install/raw/main/install-release.sh
wget -t 5 -O /root/install.sh https://github.com/grhooo/private/raw/main/rules.sh
chmod +x /root/*.sh
bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata
sed -i -e 's/User=nobody/User=root/g' -e 's/CapabilityBoundingSet=/#CapabilityBoundingSet=/g' -e 's/AmbientCapabilities=/#AmbientCapabilities=/g' /etc/systemd/system/xray.service
echo -e "\n\e[32;7m【 设置定时任务 】\e[0m"
timedatectl set-timezone Asia/Shanghai
touch /root/cron.log
echo -e '0 4,16 * * * /bin/bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata\n0 */3 * * * /bin/bash /root/rules.sh\n0 7 * * * /bin/wget -t 5 -O /usr/share/caddy/rules.zip https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/rules.zip' > /var/spool/cron/crontabs/root
sed -i 's#$# >> /root/cron.log 2>\&1#g' /var/spool/cron/crontabs/root
echo -e "\e[33;1m【 crontab 】\e[0m"
crontab -l
echo -e "\n\e[32;7m【 配置caddy/xray 】\e[0m"
mkdir /etc/caddy
mkdir /usr/share/caddy
echo -e ':8080 {\n  root * /usr/share/caddy\n  file_server\n}\n'$HOSTNAME':80 {\n  redir https://'$HOSTNAME'{uri}\n}' > /etc/caddy/Caddyfile
echo -e "\e[33;1m【 下载证书 】\e[0m"
if echo $HOSTNAME | grep -q us
  then
    wget -t 5 -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/us/ptbt.crt https://github.com/grhooo/private/raw/main/cer/us/ptbt.key
elif echo $HOSTNAME | grep -q jp
  then
    wget -t 5 -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/jp/ptbt.crt https://github.com/grhooo/private/raw/main/cer/jp/ptbt.key
elif echo $HOSTNAME | grep -q hk
  then
    wget -t 5 -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/hk/ptbt.crt https://github.com/grhooo/private/raw/main/cer/hk/ptbt.key
  else 
    echo -e '\e[31;5m 请手动下载证书至/usr/local/etc/xray！\e[0m'
fi
echo -e '{\n  "log": {\n    "access": "none",\n    "error": "none"\n  },\n  "inbounds": [\n    {\n      "port": 443,\n      "protocol": "vless",\n      "settings": {\n        "clients": [\n          {\n            "id": "xray@ptbt.top",\n            "flow": "xtls-rprx-direct"\n          }\n        ],\n        "decryption": "none",\n        "fallbacks": [\n          {\n            "dest": 8080\n          }\n        ]\n      },\n      "streamSettings": {\n        "network": "tcp",\n        "security": "xtls",\n        "xtlsSettings": {\n          "alpn": [\n            "http/1.1"\n          ],\n          "certificates": [\n            {\n              "certificateFile": "/usr/local/etc/xray/ptbt.crt",\n              "keyFile": "/usr/local/etc/xray/ptbt.key"\n            }\n          ]\n        }\n      }\n    }\n  ],\n  "outbounds": [\n    {\n      "protocol": "freedom"\n    }\n  ]\n}' > /usr/local/etc/xray/config.json
systemctl daemon-reload
systemctl enable --now caddy
systemctl restart xray
rm -rf /var/log/xray
echo -e "\n\e[32;7m【 安装dnsmasq 】\e[0m"
apt -y install dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
echo -e 'no-resolv\nno-poll\ninterface=eth0\nbind-interfaces\nlisten-address=127.0.0.1\nserver=8.8.8.8\nserver=156.154.70.22\ncache-size=1000' > /etc/dnsmasq.conf
cat /etc/dnsmasq.conf
echo -e "\n\e[32;7m【 修改ssh端口 】\e[0m"
if grep -q '^Port\s.*' /etc/ssh/sshd_config
then
  sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
  echo 'Port 27184' >> /etc/ssh/sshd_config
fi
echo -en ' \e[36;7mSSH ' && cat /etc/ssh/sshd_config | grep '^Port\s.*' && echo -en '\e[0m'
echo -e "\n\e[32;7m【 caddy/xray运行情况 】\e[0m"
systemctl | grep -E 'caddy|xray' --color=auto
echo -e "\n\e[32;7m【 /etc/caddy/Caddyfile 】\e[0m"
cat /etc/caddy/Caddyfile
echo -en "\n\e[41;5m  服务器必须重启！ \e[0m"
