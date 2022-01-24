#!/bin/sh
# 下载规则文件
wget -t 5 -O /usr/share/caddy/filters_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt
wget -t 5 -O /usr/share/caddy/badware_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt
wget -t 5 -O /usr/share/caddy/privacy_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt
wget -t 5 -O /usr/share/caddy/abuse_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt
wget -t 5 -O /usr/share/caddy/unbreak_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt
wget -t 5 -O /usr/share/caddy/f2020_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2020.txt
wget -t 5 -O /usr/share/caddy/f2021_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2021.txt
wget -t 5 -O /usr/share/caddy/f2022_ https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters-2022.txt
wget -t 5 -O /usr/share/caddy/eprivacy_ https://easylist.to/easylist/easyprivacy.txt
wget -t 5 -O /usr/share/caddy/echina_ https://raw.githubusercontent.com/easylist/easylistchina/master/easylistchina.txt
wget -t 5 -O /usr/share/caddy/cjx_ https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt
wget -t 5 -O /usr/share/caddy/xinggsf_ https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/rule.txt
# 新建规则合集,生成日期版本号
echo -e "! Title: 规则合集\n! Description: uBlock + EasylistChina + EasyPrivacy + CJX'sAnnoyanceList + 乘风规则\n! Version: `date +"%y.%m.%d.%H"`" > /usr/share/caddy/0.txt
# 删除规则文件中以!开头的行及空行
sed -i -e '/^!/d' -e '/^\s*$/d' /usr/share/caddy/*_
# 合并规则文件到规则合集中,并删除内容重复的行
cat /usr/share/caddy/*_ | sort | uniq >> /usr/share/caddy/0.txt

