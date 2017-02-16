#!/bin/bash
#
remote_public_1="10.170.186.200"
remote_private_1="172.16.0.254"
local_sub="172.16.0"
remote_public_2="10.171.13.21"
remote_private_2="172.16.0.253"

output=/dev/null
cre_tun () {
pri_ip=$(ifconfig | egrep -A1 '(eth0 |em1 )' | grep 'inet addr' | grep -v inet6 | awk '{print $2}' | awk -F':' '{print $2}')
pub_ip=`ip a | grep inet | grep -v inet6 | grep -v "127\.0\.0\.1" | grep -v "10\.[0-9]*\.[0-9]*\.[0-9]*" | grep -v "172\.16\.[0-9]*\.[0-9]*" | grep -v "192\.168\.[0-9]*\.[0-9]*" | awk '{print $2}' | awk -F '/' '{print $1}'`
while read -p "Tell me this ser's IP Host Num (172.16.0.x) x=?: " host;do
        echo -e "Your IP will be 172.16.0.\e[32m$host\e[0m,Sure ? "
while read -p "(y|n) ? " inp;do
case $inp in
        y)
                rev=0
                break
                ;;
        n)
                rev=1
                break
                ;;
        *)
                continue
esac
done
if [ $rev == 0 ];then
        break
fi
done
local_private=${local_sub}.${host}
cat > tuninfo << EOF
gw01 $pri_ip $remote_public_1 $local_private $remote_private_1
gw02 $pri_ip $remote_public_2 $local_private $remote_private_2
EOF
rsync -az ../tunnel /ROOT/sh/
/ROOT/sh/tunnel/tunnel start
name=$(echo $HOSTNAME | awk -F'.' '{print $1}' )
ser="post.aiuv.cc"
if ! grep -q 'post.aiuv.cc' /etc/hosts;then
cat >> /etc/hosts << EOF
10.170.236.206	post.aiuv.cc
EOF
fi
curl -d name=$name -d lo_pub=$remote_public_1 -d re_pub=$pri_ip -d lo_pri=$remote_private_1 -d re_pri=$local_private http://$ser/post/tunnel.php
curl -d name=$name -d lo_pub=$remote_public_2 -d re_pub=$pri_ip -d lo_pri=$remote_private_2 -d re_pri=$local_private http://$ser/post/tunnel.php
cat > /ROOT/sh/tun.push << EOF
curl -d name=$name -d lo_pub=$remote_public_1 -d re_pub=$pri_ip -d lo_pri=$remote_private_1 -d re_pri=$local_private http://$ser/post/tunnel.php
curl -d name=$name -d lo_pub=$remote_public_2 -d re_pub=$pri_ip -d lo_pri=$remote_private_2 -d re_pri=$local_private http://$ser/post/tunnel.php
EOF
}
while read -p "Create tunnel ? (Default is BJ ALY GW) (y|n): " inp;do
case $inp in
        y)
                cre_tun
                break
                ;;
        n)
                break
                ;;
        *)
                continue
esac
done
