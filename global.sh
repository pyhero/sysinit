#!/bin/bash

pub_ip=`ip a | grep inet | grep -v inet6 | \
	grep -v "127\.0\.0\.1" | \
	grep -v "10\.[0-9]*\.[0-9]*\.[0-9]*" | \
	grep -v "172\.16\.[0-9]*\.[0-9]*" | \
	grep -v "192\.168\.[0-9]*\.[0-9]*" | \
	awk '{print $2}' | awk -F '/' '{print $1}'`
pri_ip=$(ifconfig | egrep -A1 '(eth0 |em1 )' | grep 'inet addr' | \
	grep -v inet6 | awk '{print $2}' | awk -F':' '{print $2}')
