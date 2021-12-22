## 修改DNS
sed -i 's/domain-name-servers, //' /etc/dhcp/dhclient.conf
rm /etc/resolv.conf && echo -e 'nameserver 8.8.8.8\nnameserver 180.76.76.76' >> /etc/resolv.conf
## 修改ssh端口
if grep -q '^Port\s.*' /etc/ssh/sshd_config
then
  sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
  echo 'Port 27184' >> /etc/ssh/sshd_config
fi
## 安装caddy
wget -O /usr/bin/caddy https://caddyserver.com/api/download
chmod 755 /usr/bin/caddy
groupadd --system caddy
wget -P /etc/systemd/system https://github.com/grhooo/private/raw/main/caddy.service
## 安装xray
wget -O /root/install.sh https://github.com/XTLS/Xray-install/raw/main/install-release.sh
chmod u+x install.sh
bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata
## xray权限
sed -i 's/User=nobody/User=root/g' /etc/systemd/system/xray.service
sed -i 's/CapabilityBoundingSet=/#CapabilityBoundingSet=/g' /etc/systemd/system/xray.service
sed -i 's/AmbientCapabilities=/#AmbientCapabilities=/g' /etc/systemd/system/xray.service
## 每天4:00,16:00更新版本
timedatectl set-timezone Asia/Shanghai
echo -e '0 4,16 * * * bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata' >> /var/spool/cron/crontabs/root
## 生成配置文件,下载证书
mkdir /etc/caddy
mkdir /usr/share/caddy
## chmod -R 777 /usr/share/caddy
echo -e ':8080 {\n  root * /usr/share/caddy\n  file_server\n}\nptbt.top:80 {\n  redir https://ptbt.top{uri}\n}' >> /etc/caddy/Caddyfile
if ifconfig | grep -q 3.2
  then
    sed -i 's/pt/us.pt/m' /etc/caddy/Caddyfile
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/us/ptbt.crt https://github.com/grhooo/private/raw/main/cer/us/ptbt.key
elif ifconfig | grep -q 5.7
  then
    sed -i 's/pt/jp.pt/m' /etc/caddy/Caddyfile
    wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/jp/ptbt.crt https://github.com/grhooo/private/raw/main/cer/jp/ptbt.key
else
  sed -i 's/pt/hk.pt/m' /etc/caddy/Caddyfile
  wget -P /usr/local/etc/xray https://github.com/grhooo/private/raw/main/cer/hk/ptbt.crt https://github.com/grhooo/private/raw/main/cer/hk/ptbt.key
fi
rm /usr/local/etc/xray/config.json
rm -rf /var/log/xray
echo -e '{"log":{"access":"none","error":"none"},"inbounds":[{"port":443,"protocol":"vless","settings":{"clients":[{"id":"666b04c6-f7ae-43ec-96e2-e4b46a44c507","flow":"xtls-rprx-direct"}],"decryption":"none","fallbacks":[{"dest":8080}]},"streamSettings":{"network":"tcp","security":"xtls","xtlsSettings":{"alpn":["http/1.1"],"certificates":[{"certificateFile":"/usr/local/etc/xray/ptbt.crt","keyFile":"/usr/local/etc/xray/ptbt.key"}]}}}],"outbounds":[{"protocol":"freedom"}]}' >> /usr/local/etc/xray/config.json
systemctl daemon-reload
systemctl enable --now caddy
systemctl restart xray
systemctl | grep -E 'caddy|xray'
