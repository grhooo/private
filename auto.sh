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
## caddy
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install caddy
rm /etc/caddy/Caddyfile
echo -e 'ptbt.top {\n  tls /usr/local/share/ca-certificates/ptbt.crt /usr/local/share/ca-certificates/ptbt.key\n  redir https://ptbt.top{uri}\n:8080 {\n  root * /usr/share/caddy\n  file_server\n}' >> /etc/caddy/Caddyfile
if ifconfig | grep -q 173.242.127.61
  then
    sed -i 's/ptbt.top/us.ptbt.top/m' /etc/caddy/Caddyfile
    wget -P /usr/local/share/ca-certificates https://github.com/grhooo/private/raw/main/cer/us/ptbt.crt
    wget -P /usr/local/share/ca-certificates https://github.com/grhooo/private/raw/main/cer/us/ptbt.key
elif ifconfig | grep -q 45.78.51.36
  then
    sed -i 's/ptbt.top/jp.ptbt.top/m' /etc/caddy/Caddyfile
    wget -P /usr/local/share/ca-certificates https://github.com/grhooo/private/raw/main/cer/jp/ptbt.crt
    wget -P /usr/local/share/ca-certificates https://github.com/grhooo/private/raw/main/cer/jp/ptbt.key
else
  sed -i 's/ptbt.top/hk.ptbt.top/m' /etc/caddy/Caddyfile
  wget -P /usr/local/share/ca-certificates https://github.com/grhooo/private/raw/main/cer/hk/ptbt.crt
  wget -P /usr/local/share/ca-certificates https://github.com/grhooo/private/raw/main/cer/hk/ptbt.key
fi
## xray
curl -L https://github.com/grhooo/private/raw/main/xinstall.sh >> install.sh
chmod u+x install.sh
bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata
## xray权限
sed -i 's/User=nobody/User=root/g' /etc/systemd/system/xray.service
sed -i 's/CapabilityBoundingSet=/#CapabilityBoundingSet=/g' /etc/systemd/system/xray.service
sed -i 's/AmbientCapabilities=/#AmbientCapabilities=/g' /etc/systemd/system/xray.service
## 每天6:00更新版本
timedatectl set-timezone Asia/Shanghai
echo -e '00 6 * * * bash -c "$(cat /root/install.sh)" @ install --beta --without-geodata' >> /var/spool/cron/crontabs/root
## 重启服务
systemctl restart caddy
systemctl restart xray
