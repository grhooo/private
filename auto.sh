bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta && sed -i '3a\    "error": "none",' /usr/local/etc/xray/config.json
sed -i 's/^Port\s.*/Port 27184/m' /etc/ssh/sshd_config || echo 'Port 27184' >> /etc/ssh/sshd_config
sed -i 's/domain-name-servers, //' /etc/dhcp/dhclient.conf
rm /etc/resolv.conf && echo -e 'nameserver 8.8.8.8\nnameserver 180.76.76.76' >> /etc/resolv.conf
timedatectl set-timezone Asia/Shanghai
echo -e 'rm /usr/local/share/xray/*\nwget -P /usr/local/share/xray https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat' >> geodata.sh && chmod u+x geodata.sh && bash geodata.sh
rm /var/spool/cron/crontabs/root && echo -e '00 6 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null\n30 6 * * * /root/geodata.sh' >> /var/spool/cron/crontabs/root
mkdir /root/.ssh && echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIfFJ0yk0gc4HPYwyxkEHVQ8THnap6OxEklb6dt5vBfce2QOSiPVQdMEM5ExGWbx7P8HwKejKmxBMYOZq07DBNvGW+qNCgkzmRd0fPBCQtpW2ryt8kBFrjYwT7ttFQqqRUQQSPlRrsxArNnfJJKlupgyCpef2YQMDB1vLeBqXjR3hcBSSOvSULMFYclhj4JNJbxN+lmzEaeoWyNXOSyOovv0cIiQcV2MTZ5V87ggw6dAVVOczxfPai5ddrJoehxwalwqT9roS3ety6bNpsyVlrwXtNzvXIwt8D+Et7+jU/gE0F8gcb8315CVp5knieDU+FnIj0R4u7tnZu67n0YAj9ven39XlxNv1oggJjWU3cMfHx8oU0qwZt4VEdk4ELiF78fEwwzcflyTshEgdoBZg3ZX8K+artubPZPS88wMbOyqVNxp9N+K08QaMgI+pUCOK/09ah3MueNcjwtbFnl2G2nmOghW44FOFalR0Sz82m8hFox7SYIl0ATzBMzj9WJxE= admin@Admin-PC' >> /root/.ssh/id_rsa.pub && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
ufw logging off && rm /var/log/ufw.log
