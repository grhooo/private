#!/bin/sh
echo -e 'set linenumbers\nset mouse\nset softwrap' >> /etc/nanorc
cat >> /root/.bashrc << EOF

alias up='apt update && apt upgrade -y'
alias cl='apt autoremove && apt autoclean && apt clean'
alias ain='apt install'
alias arm='apt purge'
alias cls='clear'

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOF

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
wget -t3 -O /usr/bin/caddy https://caddyserver.com/api/download
chmod 755 /usr/bin/caddy
groupadd --system caddy
cat > /etc/systemd/system/caddy.service << EOF
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
PrivateTmp=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF
mkdir /etc/caddy
mkdir /usr/share/caddy
wget -t3 -P /usr/share/caddy https://github.com/grhooo/private/raw/main/index.html
echo -e ':8080 {\n  root * /usr/share/caddy\n  file_server\n}\n'$HOSTNAME':80 {\n  redir https://'$HOSTNAME'{uri}\n}' > /etc/caddy/Caddyfile

echo -e "\e[32;7m【 安装xray/hysteria 】\e[0m"
wget -t3 -O /root/inst_x.sh https://github.com/XTLS/Xray-install/raw/main/install-release.sh
wget -t3 -O /root/inst_h.sh https://raw.githubusercontent.com/HyNetwork/hysteria/master/install_server.sh
chmod +x /root/*.sh
bash -c "$(cat /root/inst_x.sh)" @ install --beta --without-geodata
bash -c "$(cat /root/inst_h.sh)"
sed -i -e 's/User=nobody/User=root/g' -e 's/CapabilityBoundingSet=/#CapabilityBoundingSet=/g' -e 's/AmbientCapabilities=/#AmbientCapabilities=/g' /etc/systemd/system/xray.service
cat >> /etc/sysctl.conf << EOF

net.core.netdev_max_backlog = 30000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_wmem = 4096 12582912 33554432
net.ipv4.tcp_rmem = 4096 12582912 33554432
net.ipv4.tcp_max_syn_backlog = 80960
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535
net.ipv4.tcp_abort_on_overflow = 1
EOF
sysctl -p

echo -e "\n\e[32;7m【 下载证书 】\e[0m"
if echo $HOSTNAME | grep -q us
  then
    wget -t3 -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/us/ptbt.{crt,key}
elif echo $HOSTNAME | grep -q jp
  then
    wget -t3 -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/jp/ptbt.{crt,key}
elif echo $HOSTNAME | grep -q hk
  then
    wget -t3 -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/hk/ptbt.{crt,key}
  else 
    echo -e '\e[31;5m 请手动下载证书至/usr/local/etc/xray！\e[0m'
fi
echo -e '{\n  "log": {\n    "access": "none",\n    "error": "none"\n  },\n  "inbounds": [\n    {\n      "port": 443,\n      "protocol": "vless",\n      "settings": {\n        "clients": [\n          {\n            "id": "xray@ptbt.top",\n            "flow": "xtls-rprx-direct"\n          }\n        ],\n        "decryption": "none",\n        "fallbacks": [\n          {\n            "dest": 8080\n          }\n        ]\n      },\n      "streamSettings": {\n        "network": "tcp",\n        "security": "xtls",\n        "xtlsSettings": {\n          "alpn": ["http/1.1"],\n          "certificates": [\n            {\n              "certificateFile": "/usr/local/etc/xray/ptbt.crt",\n              "keyFile": "/usr/local/etc/xray/ptbt.key"\n            }\n          ]\n        }\n      }\n    }\n  ],\n  "outbounds": [\n    {\n      "protocol": "freedom"\n    }\n  ]\n}' > /usr/local/etc/xray/config.json
echo -e '{\n  "listen": ":33445",\n  "protocol": "wechat-video",\n  "cert": "/usr/local/etc/xray/ptbt.crt",\n  "key": "/usr/local/etc/xray/ptbt.key",\n  "alpn": "66668888",\n  "recv_window_conn": 104857600,\n  "recv_window_client": 104857600\n}' > /etc/hysteria/config.json
systemctl daemon-reload
systemctl enable --now caddy
systemctl restart xray
rm -rf /var/log/xray
systemctl enable hysteria-server && systemctl start hysteria-server

echo -e "\n\e[32;7m【 修改ssh端口 】\e[0m"
if grep -q '^Port\s.*' /etc/ssh/sshd_config
  then
    sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
  echo 'Port 27184' >> /etc/ssh/sshd_config
fi
echo -en ' \e[36;7mSSH ' && cat /etc/ssh/sshd_config | grep '^Port\s.*' && echo -en '\e[0m'

echo -e "\n\e[32;7m【 设置定时任务 】\e[0m"
timedatectl set-timezone Asia/Shanghai
echo '0 4,16 * * * /bin/bash -c "$(cat /root/inst_x.sh)" @ install --beta --without-geodata' > /var/spool/cron/crontabs/root
echo '0 5,17 * * * /bin/bash /root/inst_h.sh && systemctl restart hysteria-server.service' >> /var/spool/cron/crontabs/root
echo '30 0 * * 3,6 caddy upgrade && systemctl restart caddy.service' >> /var/spool/cron/crontabs/root
echo '0 7 * * * /bin/wget -t3 -O /usr/share/caddy/geo.zip https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/rules.zip' >> /var/spool/cron/crontabs/root

echo -e "\n\e[32;7m【 安装AdGuardHome 】\e[0m"
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -c beta
sed -i 's/domain-name-servers,//g' /etc/dhcp/dhclient.conf
echo nameserver 127.0.0.1 > /etc/resolv.conf

echo -e "\n\e[32;7m【 caddy/xray/hysteria运行情况 】\e[0m"
systemctl | grep -E 'caddy|xray|hysteria' --color=auto
echo -e "\n\e[32;7m【 /etc/caddy/Caddyfile 】\e[0m"
cat /etc/caddy/Caddyfile
wget -t3 -P /root https://github.com/grhooo/private/raw/main/AdH.yaml
IP=$(hostname -I) && echo -e "\n\e[34;1m AdGuardHome设置页面：http://${IP%% *}:3000\e[0m"
echo -e '\e[33;1m完 成设置后请参照\e[0m\e[32;1m/root/AdH.yaml\e[0m\e[33;1m修改\e[0m\e[32;1m/opt/AdGuardHome/AdGuardHome.yaml\e[0m'
