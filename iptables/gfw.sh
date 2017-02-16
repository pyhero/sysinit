#!/bin/bash
#
# Author: Xu Panda
# Update: 2015-06-05

iptables -t filter -F
iptables -t filter -N GFW
iptables -t filter -A INPUT -j GFW
iptables -t filter -A FORWARD -j GFW
iptables -t filter -A GFW -i lo -j ACCEPT
iptables -t filter -A GFW -p icmp -m icmp --icmp-type any -j ACCEPT
iptables -t filter -A GFW -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t filter -A GFW -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables -t filter -A GFW -s 10.0.0.0/8 -j ACCEPT
iptables -t filter -A GFW -s 172.16.0.0/12 -j ACCEPT
iptables -t filter -A GFW -s 192.168.0.0/16 -j ACCEPT
iptables -t filter -A GFW -j REJECT --reject-with icmp-host-prohibited

/etc/init.d/iptables save
chkconfig iptables on
