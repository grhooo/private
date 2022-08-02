#!/bin/sh
rm /etc/motd
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
update-grub
echo -e 'set linenumbers\nset mouse\nset softwrap' >> /etc/nanorc
cat >> /root/.bashrc << EOF

alias up='apt update && apt upgrade -y'
alias cl='apt autoremove && apt autoclean'
alias cls='clear'

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOF

echo -e "\n\e[32;7m【 检查HOSTNAME 】\e[0m"
echo $HOSTNAME | egrep -q '^[a-z]{2,3}\.[bopt]{4}\.[bopt]{3}$'
if [ $? -eq 0 ]
  then
    echo -e ' \e[36;7m '$HOSTNAME' \e[0m'
else
  echo -e -n '\e[33;1m请输入hostname:\e[0m '
  read input
  echo -e ''$input'' | egrep -q '^[a-z]{2,3}\.[bopt]{4}\.[bopt]{3}$'
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

echo -e "\n\e[32;7m【 下载证书 】\e[0m"
if echo $HOSTNAME | egrep -q '^[o-z]{2}'; then
  wget -t3 -P /usr/local/etc https://github.com/grhooo/private/raw/main/cer/1/ptbt.{crt,key}
elif echo $HOSTNAME | egrep -q '^[i-t]{2}'; then
  wget -t3 -P /usr/local/etc https://github.com/grhooo/private/raw/main/cer/2/ptbt.{crt,key}
elif echo $HOSTNAME | egrep -q '^[a-o]{2}'; then
  wget -t3 -P /usr/local/etc https://github.com/grhooo/private/raw/main/cer/3/ptbt.{crt,key}
else
  echo -e '\e[31;5m 请手动下载证书至/usr/local/etc \e[0m'
fi

echo -e "\n\e[32;7m【 安装caddy 】\e[0m"
apt install -y debian-keyring debian-archive-keyring apt-transport-https zip xz-utils
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install caddy
## wget -t3 -O /usr/share/caddy/index.html https://github.com/grhooo/private/raw/main/index.html
ln -s /usr/share/caddy /root/_caddyshare
echo -e "$HOSTNAME\ntls /usr/local/etc/ptbt.crt /usr/local/etc/ptbt.key\nroot * /usr/share/caddy\nfile_server" > /etc/caddy/Caddyfile

echo -e "\e[32;7m【 安装verysimple 】\e[0m"
mkdir -p /usr/local/etc/verysimple
ln -s /usr/local/etc/verysimple /root/_verysimple
wget -t3 https://github.com/e1732a364fed/v2ray_simple/releases/latest/download/verysimple_linux_amd64.tar.xz
tar -xJf verysimple_linux_amd64.tar.xz -C /usr/local/etc/verysimple
rm verysimple_linux_amd64.tar.xz
echo -e '[Unit]\nAfter=network.service\n\n[Service]\nExecStart=/usr/local/etc/verysimple/verysimple -c /usr/local/etc/verysimple/server.toml\n\n[Install]\nWantedBy=default.target' > /etc/systemd/system/verysimple.service
chmod 664 /etc/systemd/system/verysimple.service
echo -e '[[listen]]\nprotocol = "vlesss"\nuuid = "1587875e-bf9a-40f6-b19b-42b7104ead4e"\nhost = "0.0.0.0"\nport = 33445\nversion = -1\ninsecure = false\nfallback = ":80"\ncert = "/usr/local/etc/ptbt.crt"\nkey = "/usr/local/etc/ptbt.key"\n\n[[dial]]\nprotocol = "direct"' > /usr/local/etc/verysimple/server.toml
systemctl daemon-reload
systemctl enable verysimple
systemctl start verysimple
systemctl restart caddy

echo -e "\n\e[32;7m【 修改ssh端口 】\e[0m"
sed -i -e 's/X11Forwarding yes/X11Forwarding no/m' -e 's/UsePAM yes/UsePAM no/m' -e 's/#AddressFamily any/AddressFamily inet/m' /etc/ssh/sshd_config
if grep -q '^Port\s.*' /etc/ssh/sshd_config; then
  sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
  sed -i 's/#Port 22/Port 27184/m' /etc/ssh/sshd_config
fi

echo -e "\n\e[32;7m【 设置定时任务 】\e[0m"
timedatectl set-timezone Asia/Shanghai
if echo $HOSTNAME | egrep -q '^[i-t]{2}'; then
  echo '0 7 * * * cd `mktemp -d` && /bin/wget -t3 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/rules.zip && /bin/unzip rules.zip && /bin/zip -j9 geo.zip *.dat && /bin/mv geo.zip /usr/share/caddy && /bin/rm -rf /tmp/tmp.*' > /var/spool/cron/crontabs/root
else
  echo -n
fi

echo -e "\n\e[32;7m【 安装AdGuardHome 】\e[0m"
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -c beta
sed -i 's/domain-name-servers,//g' /etc/dhcp/dhclient.conf
echo nameserver 127.0.0.1 > /etc/resolv.conf

echo -e "\n\e[32;7m【 caddy/verysimple运行情况 】\e[0m"
systemctl list-unit-files | egrep '^UNIT|caddy.s|verysimple'

IP=$(hostname -I) && echo -e "\n\e[34;1m AdGuardHome设置页面：http://${IP%% *}:3000\e[0m"
echo -e '\e[33;1mAdGuardHome配置文件：\e[0m\e[32;1m/opt/AdGuardHome/AdGuardHome.yaml\e[0m'
