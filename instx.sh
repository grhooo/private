#!/bin/sh

# 虚拟机安装xray客户端
apt install unzip -y
wget -t3 https://jp.ptbt.top/xray.zip
wget -t3 https://jp.ptbt.top/geo.zip
unzip xray -d temp
unzip geo -d temp
install -D temp/xray /usr/local/bin/xray
install -D temp/config.json /usr/local/etc/xray/config.json
install -D temp/geoip.dat /usr/local/bin/geoip.dat
install -D temp/geosite.dat /usr/local/bin/geosite.dat
rm *.zip
rm -r temp

mkdir -p /etc/systemd/system/xray.service.d
mkdir -p /etc/systemd/system/xray@.service.d
cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/xray@.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/systemd/system/xray.service /etc/systemd/system/xray@.service

echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json" > /etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf
echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json" > /etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf

systemctl daemon-reload
systemctl start xray
systemctl status xray