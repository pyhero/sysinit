Name: net-snmp-snmpv3-sohu
Version: 0.0.1
Release: 3
Group: System Environment/Base
Vendor: sysadmin Team, Tech-NO Dept., SOHU.com Inc. <sysadmin@sohu-inc.com>
URL: http://code.no.sohu.com/trac/mm
Packager: Huaping Huang <huapinghuang@sohu-inc.com>
License: GNOL
Summary: SOHU SNMPv3 Agent Deploy Tool
Buildroot: %{_builddir}/%{name}-%{version}-root
BuildArch: noarch
Source0: %{name}-%{version}.tar.gz

PreReq: curl net-snmp perl
Conflicts: itcsnmpagentdeploy

%description
   This is the SNMPv3 agent deploy tool of MM (SOHU System & Service Monitor
and Management System), which creates an SNMPv3 user, submits authentication
keys to database and does other SNMPv3-related tweakings.

%prep
mkdir -p $RPM_BUILD_ROOT
%build

%install

%clean
rm -rf $RPM_BUILD_ROOT

%pre
# set necessary environment variables
PATH=/bin:/usr/bin:/sbin:/usr/sbin
DATE=`date +%Y%m%d.%H%M%S`
# rpm --eval %S
# %SOURCE ... ft ...
DATE=${DATE%OURCE}

echo -e "\033[1;37mTweaking snmpd.conf ...\033[m"
# remove public community
if grep -q "^com2sec.*public$" /etc/snmp/snmpd.conf; then
    cp -a /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak.$DATE
    perl -pi -e "s/(^com2sec.*public$)/#\1/g" /etc/snmp/snmpd.conf
fi

# find correct directory
if [ -d /var/lib/net-snmp ]; then
    DIR=/var/lib/net-snmp
else
    DIR=/var/net-snmp
fi

# before finish taking place of itcsnmpagentdeploy, do not re-gen snmpv3 keys
DEPLOYED=0
if grep -q "^usmUser.*$" $DIR/snmpd.conf &> /dev/null; then
    DEPLOYED=1
fi

if service snmpd status &> /dev/null; then
    service snmpd stop
fi

if [ $DEPLOYED -eq 0 ]; then
    echo -e "\033[1;37mCreating SNMPv3 user ...\033[m"
    AUTHPWD=`dd if=/dev/urandom bs=6 count=1  2>/dev/null | hexdump -e '"%x"'`
    PRIVPWD=`dd if=/dev/urandom bs=6 count=1  2>/dev/null | hexdump -e '"%x"'`
    echo "AUTHPWD" $AUTHPWD
    echo "PRIVPWD" $PRIVPWD
    if [ -e $DIR/snmpd.conf ]; then
        perl -pi -e "s/^usmUser.*\n$//g" $DIR/snmpd.conf
        perl -pi -e "s/^createUser nomgmtuser.*\n$//g" $DIR/snmpd.conf
    else
        mkdir -p $DIR
    fi
    cat >> $DIR/snmpd.conf << EOF
createUser nomgmtuser MD5 "$AUTHPWD" DES "$PRIVPWD"
EOF
else
    echo -e "\033[1;31mYou've already deployed SNMPv3!\033[m"
fi

# remove /usr/share/snmp/snmpd.conf created by previous itcsnmpagentdeploy package
echo -e "\033[1;37mConfiguring user access ...\033[m"
if [ -e /usr/share/snmp/snmpd.conf ]; then
    rm -f /usr/share/snmp/snmpd.conf
fi

# add user access
if [ -e /etc/snmp/snmpd.local.conf ]; then
    perl -pi -e "s/^rouser nomgmtuser.*\n$//g" /etc/snmp/snmpd.local.conf
fi

cat >> /etc/snmp/snmpd.local.conf << EOF
rouser nomgmtuser priv
EOF

# add agentaddress line
perl -pi -e "s/^agentaddress.*\n//g" /etc/snmp/snmpd.local.conf

AGENTADD=`perl -e 'while (qx(ip ad ls) =~ /\s+inet\s((10|127|172|192)\.(\d+)\.\d+\.\d+)/g) {next if (grep(/$1/, @inet) || ($2 eq "192" && $3 ne "168") || ($2 eq "172" && ($3 < 16 || $3 > 31))); push (@inet, $1); } print join(",", @inet);'`
echo "agentaddress $AGENTADD" >> /etc/snmp/snmpd.local.conf

# selinux
chcon -R system_u:object_r:snmpd_var_lib_t:s0 $DIR/

service snmpd start
chkconfig --level 3 snmpd on

if [ $DEPLOYED -eq 0 ]; then
    COUNT=0
    while [ $COUNT -le 5 ] && ! grep -q "^usmUser.*$" $DIR/snmpd.conf; do
        sleep 2
        let "COUNT += 1"
    done
    if ! service snmpd status &> /dev/null; then
        echo -e "\033[1;31mERROR: snmpd not running after waiting for 12 seconds\033[m"
    fi

    if grep -q "^usmUser.*$" $DIR/snmpd.conf; then
        echo -e "\033[1;37mSNMPv3 authkey/privkey sucessfully generated!\033[m"
        EID=`awk '/^oldEngineID/ {print $2}' $DIR/snmpd.conf`
        AUTHKEY=`awk '/^usmUser/ {print $9}' $DIR/snmpd.conf`
        PRIVKEY=`awk '/^usmUser/ {print $11}' $DIR/snmpd.conf`
        echo "EID" $EID
        echo "AUTHKEY" $AUTHKEY
        echo "PRIVKEY" $PRIVKEY
    
        CLIENTIPS=`perl -e 'while (qx(ip ad ls) =~ /\s+inet\s((\d+)\.\d+\.\d+\.\d+)/g) {next if (grep(/$1/, @inet) || ($2 eq "127")); push (@inet, $1); } print join(" ", @inet);'`
        echo "CLIENTIPS=$CLIENTIPS"

        NAGIOSIP="post.aiuv.cc"
        echo "Submitting informations to $NAGIOSIP"
	pushfile=/ROOT/sh/snmp.push
	if [ -s $pushfile ];then
		echo > $pushfile
	fi
	for ip in $CLIENTIPS;do
        curl -d forceupdate=1 -d submit=submit -d versionflag=3 -d authkey=$AUTHKEY -d privkey=$PRIVKEY -d eid=$EID -d authpwd=$AUTHPWD -d privpwd=$PRIVPWD -d clientips=$ip http://$NAGIOSIP/post/snmp.php
	echo "curl -d forceupdate=1 -d submit=submit -d versionflag=3 -d authkey=$AUTHKEY -d privkey=$PRIVKEY -d eid=$EID -d authpwd=$AUTHPWD -d privpwd=$PRIVPWD -d clientips=$ip http://$NAGIOSIP/post/snmp.php" >> $pushfile
	done
        echo
        RETZERO=$?
        if [ $RETZERO -gt 0 ]; then
            echo -e "\033[1;31mError occured during submitting keys to database!!\033[m"
        fi
    else
        echo -e "\033[1;31mERROR: Failed to generate SNMPv3 keys!!\033[m"
    fi
fi

%post

%preun
PATH=/bin:/usr/bin:/sbin:/usr/sbin

# find correct directory
if [ -d /var/lib/net-snmp ]; then
    DIR=/var/lib/net-snmp
else
    DIR=/var/net-snmp
fi

if [ $1 -eq 0 ]; then
    echo -e "\033[1;37mDeleting SNMPv3 User ...\033[m"
    service snmpd stop
    if [ -e $DIR/snmpd.conf ]; then
        perl -pi -e 's/^usmUser.*\n$//g' $DIR/snmpd.conf
    fi
    echo -e "\033[1;37mRestoring configurations ...\033[m"
    if [ -e /etc/snmp/snmpd.local.conf ]; then
        perl -pi -e "s/^agentaddress.*\n$//g" /etc/snmp/snmpd.local.conf
        perl -pi -e "s/^rouser nomgmtuser.*\n$//g" /etc/snmp/snmpd.local.conf
    fi
#    if service snmpd status &> /dev/null; then
#        service snmpd restart
#    fi 
    service snmpd start
fi

%postun

%files

%changelog
* Tue Nov 8 2011 Li Kai <9@kai.li>
- 0.0.1 Release 3
- Improve: add find correct directory feature for RHEL/CentOS 6 compatibility
- Bugfix: cannot delete user on uninstall
* Sun Jan 4 2009 Huaping Huang <huapinghuang@sohu-inc.com>
- fixed duplicate IP bug
* Tue Dec 9 2008 Huaping Huang <huapinghuang@sohu-inc.com>
- initial version

