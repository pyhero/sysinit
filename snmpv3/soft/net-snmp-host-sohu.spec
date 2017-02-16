Name: net-snmp-host-sohu
Version: 0.0.1
Release: 2
Group: System Environment/Base
Vendor: sysadmin Team, Tech-NO Dept., SOHU.com Inc. <sysadmin@sohu-inc.com>
URL: http://code.no.sohu.com/trac/mm
Packager: Huaping Huang <huapinghuang@sohu-inc.com>
License: GNOL
Summary: SOHU Host Statistics Agent Deploy Tool
Buildroot: %{_builddir}/%{name}-%{version}-root
BuildArch: noarch
Source0: %{name}-%{version}.tar.gz

PreReq: net-snmp-snmpv3-sohu
Conflicts: itcsnmpagentdeploy

%description
   This is the Host Statistics agent deploy tool of MM (SOHU System & Service
Monitor and Management System), which adds disk monitoring configurations for
MM.

%prep
mkdir -p $RPM_BUILD_ROOT
#%setup -q

%build

%install
#mkdir -p $RPM_BUILD_ROOT/usr/local/sohu/snmp/mibscript

#install -m755 mibscript/hostStatic $RPM_BUILD_ROOT/usr/local/sohu/snmp/mibscript

%clean
rm -rf $RPM_BUILD_ROOT

%pre
# set necessary environment variables
PATH=/bin:/usr/bin:/sbin:/usr/sbin

# remove /etc/snmp/snmpd.conf modifications by previous itcsnmpagentdeploy package
if grep -q "^pass.*52312.*hostStatic$" /etc/snmp/snmpd.conf; then
    perl -pi -e "s/^pass.*52312.*hostStatic\n$//g" /etc/snmp/snmpd.conf
    perl -pi -e "s/^pass.*52312.*csyncStatic\n$//g" /etc/snmp/snmpd.conf
    perl -pi -e "s/^# \d{8}.\d{6}.*\n$//g" /etc/snmp/snmpd.conf
fi

echo -e "\033[1;37mGenerating disk configurations ...\033[m"
# add disk configurations
if [ -e /etc/snmp/snmpd.local.conf ]; then
    perl -pi -e "s/^disk \/.*\n$//g" /etc/snmp/snmpd.local.conf
fi

# make a run-once script for RHEL5 installation, while /dev/root is mounted
if mount | awk '{print $1;}' | grep -q "^/dev/root$"; then
    echo -e "\033[1;37m/dev/root mounted, generating run-once script ...\033[m"
    cat > /etc/snmp/runonce.sh << EOF
#!/bin/sh
perl -pi -e "s/^disk \/.*\n$//g" /etc/snmp/snmpd.local.conf
for i in \`mount | awk '\$3 !~ /^(\/dev|\/proc|\/sys)/ && \$NF !~ /loop=/ {print \$3;}'\`; do
    echo "disk \$i" >> /etc/snmp/snmpd.local.conf
done
perl -pi -e "s/^\/bin\/sh\s+\/etc\/snmp\/runonce.sh\n$//g" /etc/rc.local
if service snmpd status &> /dev/null; then
    service snmpd restart
else
    service snmpd start
fi
rm -f /etc/snmp/runonce.sh
EOF
    cat >> /etc/rc.local << EOF
/bin/sh /etc/snmp/runonce.sh
EOF
else
    # regular installtion process for RHEL4
#    for i in `mount | awk '$3 !~ /^(\/dev|\/proc|\/sys)/ && $NF !~ /loop=/ {print $3;}'`; do
    for i in `mount | awk '$3 !~ /^(\/dev|\/proc|\/sys)/ && $NF !~ /loop=/ && $1 !~ /sunrpc/ {print $3;}'`; do
        echo "disk $i" >> /etc/snmp/snmpd.local.conf
    done
fi

# temporarily support enterprises.52312.1 mib tree
# for a smooth update
#perl -pi -e "s/^pass.*52312.*hostStatic\n$//g" /etc/snmp/snmpd.local.conf
#cat >> /etc/snmp/snmpd.local.conf << EOF
#pass .1.3.6.1.4.1.52312.1 /usr/bin/perl /usr/local/sohu/snmp/mibscript/hostStatic
#EOF

# remove this deprecated MIB
#if [ -e /usr/share/snmp/mibs/ITC-MIB.txt ]; then
#    rm -f /usr/share/snmp/mibs/ITC-MIB.txt
#fi

%post
PATH=/bin:/usr/bin:/sbin:/usr/sbin
if service snmpd status &> /dev/null; then
    service snmpd restart
else
    service snmpd start
fi

%preun
PATH=/bin:/usr/bin:/sbin:/usr/sbin
if [ $1 -eq 0 ]; then
    echo -e "\033[1;37mRestoring configurations ...\033[m"
    if [ -e /etc/snmp/snmpd.local.conf ]; then
        perl -pi -e "s/^disk \/.*\n$//g" /etc/snmp/snmpd.local.conf
        perl -pi -e "s/^pass.*52312.*hostStatic\n$//g" /etc/snmp/snmpd.local.conf
    fi
fi

%postun
PATH=/bin:/usr/bin:/sbin:/usr/sbin
if [ $1 -eq 0 ]; then
    if service snmpd status &> /dev/null; then
        service snmpd restart
    fi
fi

%files
#%defattr(0755,root,root)
#%dir /usr/local/sohu/snmp
#%dir /usr/local/sohu/snmp/mibscript
#/usr/local/sohu/snmp/mibscript/hostStatic

%changelog
* Thu Jan 15 2009 Huaping Huang <huapinghuang@sohu-inc.com>
- fix: during RHEL5 installation, only / can be written to snmpd.local.conf
- because the result of `mount` is like:
- /dev/root on / type ext3 (ro)
- in this case, make a run-once script which generates the correct configurations during next boot.
* Tue Dec 9 2008 Huaping Huang <huapinghuang@sohu-inc.com>
- initial version

