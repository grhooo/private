#! /bin/sh
echo -e "\n\033[32;1m【 修改DNS 】\033[0m"
sed -i 's/domain-name-servers, //' /etc/dhcp/dhclient.conf
echo -e 'nameserver 8.8.8.8\nnameserver 180.76.76.76' > /etc/resolv.conf
echo -e "\n\033[32;1m【 修改ssh端口 】\033[0m"
if grep -q '^Port\s.*' /etc/ssh/sshd_config
then
  sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
  echo 'Port 27184' >> /etc/ssh/sshd_config
fi
echo -e "\n\033[32;1m【 安装caddy 】\033[0m"
wget -O /usr/bin/caddy https://caddyserver.com/api/download
chmod 755 /usr/bin/caddy
groupadd --system caddy
wget -P /etc/systemd/system https://github.com/grhooo/private/raw/main/caddy.service
echo -e "\n\033[32;1m【 安装xray 】\033[0m"
wget -O /root/install.sh https://github.com/XTLS/Xray-install/raw/main/install-release.sh
chmod u+x install.sh
bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata
sed -i 's/User=nobody/User=root/g' /etc/systemd/system/xray.service
sed -i 's/CapabilityBoundingSet=/#CapabilityBoundingSet=/g' /etc/systemd/system/xray.service
sed -i 's/AmbientCapabilities=/#AmbientCapabilities=/g' /etc/systemd/system/xray.service
echo -e "\n\033[32;1m【 每日4,16时检查更新 】\033[0m"
timedatectl set-timezone Asia/Shanghai
echo -e '0 4,16 * * * bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata' > /var/spool/cron/crontabs/root
echo -e "\033[33;1m【 crontab 】\033[0m"
crontab -l
echo -e "\n\033[32;1m【 配置caddy/xray 】\033[0m"
mkdir /etc/caddy
mkdir /usr/share/caddy
echo -e ':8080 {\n  root * /usr/share/caddy\n  file_server\n}\nptbt.top:80 {\n  redir https://ptbt.top{uri}\n}' > /etc/caddy/Caddyfile
echo -e "\033[33;1m【 下载证书 】\033[0m"
if ifconfig | grep -q 173.242
  then
    sed -i 's/ptbt/us.ptbt/m' /etc/caddy/Caddyfile
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/us/ptbt.crt https://github.com/grhooo/private/raw/main/cer/us/ptbt.key
elif ifconfig | grep -q 45.78
  then
    sed -i 's/ptbt/jp.ptbt/m' /etc/caddy/Caddyfile
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/jp/ptbt.crt https://github.com/grhooo/private/raw/main/cer/jp/ptbt.key
else
  sed -i 's/ptbt/hk.ptbt/m' /etc/caddy/Caddyfile
  wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/hk/ptbt.crt https://github.com/grhooo/private/raw/main/cer/hk/ptbt.key
fi
echo -e '{"log":{"access":"none","error":"none"},"inbounds":[{"port":443,"protocol":"vless","settings":{"clients":[{"id":"666b04c6-f7ae-43ec-96e2-e4b46a44c507","flow":"xtls-rprx-direct"}],"decryption":"none","fallbacks":[{"dest":8080}]},"streamSettings":{"network":"tcp","security":"xtls","xtlsSettings":{"alpn":["http/1.1"],"certificates":[{"certificateFile":"/usr/local/etc/xray/ptbt.crt","keyFile":"/usr/local/etc/xray/ptbt.key"}]}}}],"outbounds":[{"protocol":"freedom"}]}' > /usr/local/etc/xray/config.json
systemctl daemon-reload
systemctl enable --now caddy
systemctl restart xray
rm -rf /var/log/xray
echo -e "\n\033[32;1m【 caddy/xray运行情况 】\033[0m"
systemctl | grep -E 'caddy|xray' --color=auto
echo -e "\n\033[32;1m【 /etc/caddy/Caddyfile 】\033[0m"
cat /etc/caddy/Caddyfile
echo -e -n "\n\033[32;1m 即将安装\033[0m \033[33;1mXanMod Kernel\033[0m [\033[31my\033[0mes|no]: "
read input
if [ "$input" = "yes" ] || [ "$input" = "y" ]
  then
    apt -y install gpg
    echo deb http://deb.xanmod.org releases main > /etc/apt/sources.list.d/xanmod-kernel.list
    curl -s https://dl.xanmod.org/gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/xanmod-kernel.gpg --import
    chown _apt /etc/apt/trusted.gpg.d/xanmod-kernel.gpg
    apt update && apt -y install linux-xanmod
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    echo net.core.default_qdisc=fq_pie >> /etc/sysctl.conf
    sysctl --system
  else
    exit 0
fi
