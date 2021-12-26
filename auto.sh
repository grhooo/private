#! /bin/sh
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
echo -e "\n\e[32;7m【 修改DNS 】\e[0m"
sed -i 's/domain-name-servers, //' /etc/dhcp/dhclient.conf
echo -e 'nameserver 8.8.8.8\nnameserver 180.76.76.76' > /etc/resolv.conf
cat /etc/resolv.conf
echo -e "\n\e[32;7m【 修改ssh端口 】\e[0m"
if grep -q '^Port\s.*' /etc/ssh/sshd_config
then
  sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
  echo 'Port 27184' >> /etc/ssh/sshd_config
fi
echo -en ' \e[36;7mSSH ' && cat /etc/ssh/sshd_config | grep '^Port\s.*' && echo -en '\e[0m'
echo -e "\n\e[32;7m【 安装caddy 】\e[0m"
wget -O /usr/bin/caddy https://caddyserver.com/api/download
chmod 755 /usr/bin/caddy
groupadd --system caddy
wget -P /etc/systemd/system https://github.com/grhooo/private/raw/main/caddy.service
echo -e "\e[32;7m【 安装xray 】\e[0m"
wget -O /root/install.sh https://github.com/XTLS/Xray-install/raw/main/install-release.sh
chmod u+x install.sh
bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata
sed -i 's/User=nobody/User=root/g' /etc/systemd/system/xray.service
sed -i 's/CapabilityBoundingSet=/#CapabilityBoundingSet=/g' /etc/systemd/system/xray.service
sed -i 's/AmbientCapabilities=/#AmbientCapabilities=/g' /etc/systemd/system/xray.service
echo -e "\n\e[32;7m【 每日4,16时检查更新 】\e[0m"
timedatectl set-timezone Asia/Shanghai
echo -e '0 4,16 * * * bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata' > /var/spool/cron/crontabs/root
echo -e "\e[33;1m【 crontab 】\e[0m"
crontab -l
echo -e "\n\e[32;7m【 配置caddy/xray 】\e[0m"
mkdir /etc/caddy
mkdir /usr/share/caddy
echo -e ':8080 {\n  root * /usr/share/caddy\n  file_server\n}\n'$HOSTNAME':80 {\n  redir https://'$HOSTNAME'{uri}\n}' > /etc/caddy/Caddyfile
echo -e "\e[33;1m【 下载证书 】\e[0m"
if echo $HOSTNAME | grep -q us
  then
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/us/ptbt.crt https://github.com/grhooo/private/raw/main/cer/us/ptbt.key
elif echo $HOSTNAME | grep -q jp
  then
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/jp/ptbt.crt https://github.com/grhooo/private/raw/main/cer/jp/ptbt.key
elif echo $HOSTNAME | grep -q hk
  then
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/hk/ptbt.crt https://github.com/grhooo/private/raw/main/cer/hk/ptbt.key
  else 
    echo -e '\e[31;5m 请手动下载证书至/usr/local/etc/xray！\e[0m'
fi
echo -e '{"log":{"access":"none","error":"none"},"inbounds":[{"port":443,"protocol":"vless","settings":{"clients":[{"id":"666b04c6-f7ae-43ec-96e2-e4b46a44c507","flow":"xtls-rprx-direct"}],"decryption":"none","fallbacks":[{"dest":8080}]},"streamSettings":{"network":"tcp","security":"xtls","xtlsSettings":{"alpn":["http/1.1"],"certificates":[{"certificateFile":"/usr/local/etc/xray/ptbt.crt","keyFile":"/usr/local/etc/xray/ptbt.key"}]}}}],"outbounds":[{"protocol":"freedom"}]}' > /usr/local/etc/xray/config.json
systemctl daemon-reload
systemctl enable --now caddy
systemctl restart xray
rm -rf /var/log/xray
echo -e "\n\e[32;7m【 caddy/xray运行情况 】\e[0m"
systemctl | grep -E 'caddy|xray' --color=auto
echo -e "\n\e[32;7m【 /etc/caddy/Caddyfile 】\e[0m"
cat /etc/caddy/Caddyfile
