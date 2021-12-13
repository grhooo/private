## 修改DNS
sed -i 's/domain-name-servers, //' /etc/dhcp/dhclient.conf
rm /etc/resolv.conf && echo -e 'nameserver 8.8.8.8\nnameserver 180.76.76.76' >> /etc/resolv.conf
## 时区
timedatectl set-timezone Asia/Shanghai
## 创建自动更新sh文件，每天定时执行
echo -e 'rm /usr/local/share/v2ray/*\nwget -P /usr/local/share/v2ray https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat' >> geodata.sh && chmod u+x geodata.sh && bash geodata.sh
rm /var/spool/cron/crontabs/root && echo -e '30 6 * * * /root/geodata.sh' >> /var/spool/cron/crontabs/root
## 关闭ufw记录
ufw logging off && rm /var/log/ufw.log
## 修改ssh端口
if grep -q '^Port\s.*' /etc/ssh/sshd_config
then
    sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config
else
    echo 'Port 27184' >> /etc/ssh/sshd_config
fi
