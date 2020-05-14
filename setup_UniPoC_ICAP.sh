#! /bin/bash
#
#
#
###############################################################################################################
# George Georgakakos, BiG Data under Cloudera CDH 6.3.2			###############################################
###############################################################################################################
#
# Release 1.0, date 07.01.2020, George Georgakakos, georgakakosg@unisystems.gr
# Release 1.1, date 05.03.2020, George Georgakakos, georgakakosg@unisystems.gr // Changes to be more generic
# Release 1.2, date 09.05.2020, George Georgakakos, georgakakosg@unisystems.gr // Changes for RHEL
#
################################################################################################################
DomainName="icap.gr"
hostname="utilityMgmt"
OSRelease=`cat /etc/redhat-release`
#
mkdir -p /root/icap/
mkdir -p /root/icap/installation/ClouderaBinaries/
mkdir -p /root/icap/templates/
mkdir -p /root/icap/conf/
mkdir -p /root/icap/scripts/
mkdir -p /root/icap/archive/
#
#
BackInst="/root/icap/installation/ClouderaBinaries"
InsFolder="/root/icap"
utilityIP="$3"
#
#10.255.210.11		utilityMgmt.icap.gr
#10.255.210.12		gatehostMgmt.icap.gr
#10.255.210.13		master01Mgmt.icap.gr
#10.255.210.14		master02Mgmt.icap.gr
#10.255.210.15		master03Mgmt.icap.gr
#10.255.210.16		worker01Mgmt.icap.gr
#10.255.210.17		worker02Mgmt.icap.gr
#10.255.210.18		worker03Mgmt.icap.gr
#10.255.210.19		worker04Mgmt.icap.gr
#10.255.210.20		worker05Mgmt.icap.gr
#10.255.210.21		worker06Mgmt.icap.gr
#
#
###############################################################################################################
#hostsFile=/etc/hosts
#if [[ -f "$hostsFile" ]]; then
#    echo "$hostsFile exist and will be backup as $hostsFile_bkupOriginal"
#    mv /etc/hosts $hostsFile_bkupOriginal
#    cp -p /root/OneNodeCDHCluster/hosts	/etc/hosts
#    echo "Hosts file permissions should be -rw-r--r-- 1 root root"
#    echo "It is : `ls -ltr /etc/hosts`"
#else
#    echo "Problem Faced during Hosts file Creation, will exit"
#    exit 1
#fi
################################################################################################################
echo "==================================================================================="
echo "`date`"
echo ""
echo "BigData Lab for ICAP"
echo "You need to run this as  root: you are `id`"
echo "UniSystems Team"
echo "==================================================================================="
##################################################################################################################
#
if [ "$1" == "hardening" ]; then
  	echo "You are in Hardening mode"
	echo "Hosts in etc/hosts has already been set"  #						#
	echo "$OSRelease"
	if [ -z "`cat /etc/redhat-release | grep 7`" ]; then
		sudo rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
	else
		sudo rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7Server
	fi
	sleep 1
	echo "=================================================================================="
	echo "Step 1 - Operating System Optimization and Hardening"
	# https://access.redhat.com/solutions/1320153
	echo "Attention here check the transparent hugepage....perhaps you need to perform it from grub"
	cat /sys/kernel/mm/transparent_hugepage/enabled
	cat /sys/kernel/mm/transparent_hugepage/defrag
	systemctl stop tuned
	systemctl disable tuned
	sleep 10
	cat /proc/cmdline
	sleep 5
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo never > /sys/kernel/mm/transparent_hugepage/defrag
	echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
	cat /sys/kernel/mm/transparent_hugepage/defrag
	echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local

	sleep 2
	echo ""
	echo ""
	mkdir /etc/tuned/bigdata-nothp
        cp /root/icap/conf/tuned.conf /etc/tuned/bigdata-nothp/
	chmod +x /etc/tuned/bigdata-nothp/tuned.conf
	tuned-adm profile bigdata-nothp
	cat /sys/kernel/mm/transparent_hugepage/enabled
	cat /sys/kernel/mm/transparent_hugepage/defrag
	#
	#
	#
	echo "You need to reboot to take affect"
	# add tuned optimization https://www.cloudera.com/documentation/enterprise/6/6.2/topics/cdh_admin_performance.html
	echo "`cat /proc/sys/vm/swappiness`"
	cp /etc/sysctl.conf $BackInst/sysctl.conf_bkup
	#echo "vm.swappiness = 10" >> /etc/sysctl.conf      
        if [ -z "`cat /etc/sysctl.conf | grep vm.swappiness`" ]; then
		echo "vm.swappiness = 10" >> /etc/sysctl.conf                
        fi
	sysctl vm.swappiness=10
	echo "`cat /etc/sysctl.conf`"
	sleep 3
	sudo timedatectl set-timezone Europe/Athens
    	echo "hostname and SeLinux actions"
	cp /etc/sysconfig/network $BackInst/network_bkup
    	sed -i "s/HOSTNAME=.*/HOSTNAME=`hostname`/" /etc/sysconfig/network
	sudo systemctl disable firewalld
	sudo systemctl stop firewalld
	sudo setenforce 0
	cp /etc/selinux/config $BackInst/config_bkup
    	sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    	echo "=================================================================================="
    	echo "Adding the 6.3.2 Cloudera repo for RedHat 7"
    	sudo rpm --import https://archive.cloudera.com/cdh6/6.3.2/redhat7/yum/RPM-GPG-KEY-cloudera
    	echo "NTP Configuration"
    	echo "`chkconfig ntpd on`"
    	echo "`systemctl start ntpd`"
    	echo "`chkconfig ntpd on`"
    	echo "`timedatectl set-ntp true`"
    	echo "=================================================================================="	
    	echo ""
    	echo "Installation of Java - OpenJDk8"
    	echo "-- Install Java OpenJDK8 and other tools"
    	yum install -y java-1.8.0-openjdk-devel vim wget curl git bind-utils
	echo "-- Installing requirements for Stream Messaging Manager"
	yum install -y gcc-c++ make
	curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -
	yum install nodejs -y
	npm install forever -g
	echo "=================================================================================="	
	echo ""
	echo "=================================================================================="
	echo ""
	echo "-- Install JDBC connector"
	echo "JDBC Driver for MySQL (Connector/J), https://www.mysql.com/products/connector/" 
	#wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz -P ~
	cd $BackInst/
	wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.20.tar.gz -P $BackInst/
	tar zxf $BackInst/mysql-connector-java-8.0.20.tar.gz -C $BackInst/
	mkdir -p /usr/share/java/
	chmod 755 $BackInst/mysql-connector-java-8.0.20/mysql-connector-java-8.0.20.jar
	cp $BackInst/mysql-connector-java-8.0.20/mysql-connector-java-8.0.20.jar /usr/share/java/mysql-connector-java.jar	
	echo "=================================================================================="
	echo "Hardening Mode has finished!!!"
	echo "Will now reboot"
	init 6
fi
###################################################################################################################
###################################################################################################################
#Check input parameters
case "$1" in
        local)
            ;;
        *)            
	    echo "For Hardening on each node, and the utility for the 1st time use:"
	    echo $"example: ./setup_UniPoC_ICAP.sh hardening"
	    echo "######"
	    echo "For proper Setup after hardening use:"	
	    echo $"example: ./setup_UniPoC_ICAP.sh local templates/default_template.json"
            exit 1
esac
TEMPLATE=$2
echo "This is the conf to run $TEMPLATE"
###################################################################################################################
###################################################################################################################
echo "-- Install CM and MariaDB repo"
wget https://archive.cloudera.com/cm6/6.3.0/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
wget https://archive.cloudera.com/cm6/6.3.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
#
## MariaDB 10.1
cat - >/etc/yum.repos.d/MariaDB.repo <<EOF
[mariadb]
name = MariaDB
baseurl =http://yum.mariadb.org/10.5.2/rhel/7.7/x86_64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
#
yum clean all
rm -rf /var/cache/yum/
yum repolist
#

subscription-manager config --rhsm.manage_repos=0
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server
#
#
#
echo "--Install,Enable and start MariaDB"
#yum install -y MariaDB-server MariaDB-client
yum groupinstall -y mariadb
yum groupinstall -y mariadb-client

cat conf/mariadb.config > /etc/my.cnf
systemctl enable mariadb
systemctl start mariadb
#
#
echo "-- Create DBs required by CM"
mysql -u root < $InsFolder/scripts/create_db.sql
echo "-- Secure MariaDB"
mysql -u root < $InsFolder/scripts/secure_mariadb.sql
#
echo "-- Prepare CM database 'scm'"
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm cloudera
#
echo "-- Install CSDs"
# install local CSDs
cp ~/*.jar /opt/cloudera/csd/
cp $InsFolder/*.jar /opt/cloudera/csd/

#https://archive.cloudera.com/CFM/csd/1.0.1.0/
# Getting CFM/csd/1.0.1.0/
echo "Getting CFM/csd/1.0.1.0/"
#wget https://archive.cloudera.com/CFM/csd/1.0.1.0/NIFI-1.9.0.1.0.1.0-12.jar -P /opt/cloudera/csd/
#wget https://archive.cloudera.com/CFM/csd/1.0.1.0/NIFICA-1.9.0.1.0.1.0-12.jar -P /opt/cloudera/csd/
#wget https://archive.cloudera.com/CFM/csd/1.0.1.0/NIFIREGISTRY-0.3.0.1.0.1.0-12.jar -P /opt/cloudera/csd/
#wget https://archive.cloudera.com/cdsw1/1.6.0/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH6-1.6.0.jar -P /opt/cloudera/csd/
# CSD for C5
#wget https://archive.cloudera.com/cdsw1/1.6.0/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH5-1.6.0.jar -P /opt/cloudera/csd/
wget https://archive.cloudera.com/spark2/csd/SPARK2_ON_YARN-2.4.0.cloudera1.jar -P /opt/cloudera/csd/
wget https://archive.cloudera.com/spark2/csd/SPARK2_ON_YARN-2.4.0.cloudera2.jar -P /opt/cloudera/csd/
#
chown cloudera-scm:cloudera-scm /opt/cloudera/csd/*
chmod 644 /opt/cloudera/csd/*
#
echo "-- Install local parcels"
echo "Get the parcel from Cloudera and place them in : `pwd`"
echo "Main Link For StreamSets : https://archives.streamsets.com/index.html" 
echo "Main Link for Parcels: https://archive.cloudera.com/cdh6/"
echo "Cloudera Yum for RHE7-Centos: https://archive.cloudera.com/cdh6/6.3.2/redhat7/yum/ "
####
#
###
##### Download Parcels 
cd /opt/cloudera/parcel-repo/
echo "Ready to Download from https://archive.cloudera.com/cdh6/6.3.2/parcels/"
echo "Parcels Download"
wget -r --no-parent --reject "index.html*" https://archive.cloudera.com/cdh6/6.3.2/parcels/
wget -r --no-parent --reject "index.html*" https://archive.cloudera.com/CFM/parcels/1.0.1.0/
echo "Changing Permissions in `pwd`"
chown cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/*
sleep 4
#
echo "-- Install CEM Tarballs"
mkdir -p /opt/cloudera/cem
wget https://archive.cloudera.com/CEM/centos7/1.x/updates/1.0.0.0/CEM-1.0.0.0-centos7-tars-tarball.tar.gz -P /opt/cloudera/cem
#
tar xzf /opt/cloudera/cem/CEM-1.0.0.0-centos7-tars-tarball.tar.gz -C /opt/cloudera/cem
tar xzf /opt/cloudera/cem/CEM/centos7/1.0.0.0-54/tars/efm/efm-1.0.0.1.0.0.0-54-bin.tar.gz -C /opt/cloudera/cem
rm -f /opt/cloudera/cem/CEM-1.0.0.0-centos7-tars-tarball.tar.gz
ln -s /opt/cloudera/cem/efm-1.0.0.1.0.0.0-54 /opt/cloudera/cem/efm
ln -s /opt/cloudera/cem/efm/bin/efm.sh /etc/init.d/efm
chown -R root:root /opt/cloudera/cem/efm-1.0.0.1.0.0.0-54
#
#tar xzf /opt/cloudera/cem/CEM/centos7/1.0.0.0-54/tars/minifi/minifi-0.6.0.1.0.0.0-54-bin.tar.gz -C /opt/cloudera/cem
#tar xzf /opt/cloudera/cem/CEM/centos7/1.0.0.0-54/tars/minifi/minifi-toolkit-0.6.0.1.0.0.0-54-bin.tar.gz -C /opt/cloudera/cem
#ln -s /opt/cloudera/cem/minifi-0.6.0.1.0.0.0-54 /opt/cloudera/cem/minifi
#chown -R root:root /opt/cloudera/cem/minifi-0.6.0.1.0.0.0-54
#chown -R root:root /opt/cloudera/cem/minifi-toolkit-0.6.0.1.0.0.0-54
#rm -f /opt/cloudera/cem/minifi/conf/bootstrap.conf
#cp $InsFolder/conf/bootstrap.conf /opt/cloudera/cem/minifi/conf
#sed -i "s/YourHostname/`hostname -f`/g" /opt/cloudera/cem/minifi/conf/bootstrap.conf
#/opt/cloudera/cem/minifi/bin/minifi.sh install
#
rm -f /opt/cloudera/cem/efm/conf/efm.properties
cp $InsFolder/conf/efm.properties /opt/cloudera/cem/efm/conf
sed -i "s/YourHostname/`hostname -f`/g" /opt/cloudera/cem/efm/conf/efm.properties
#
echo "There is no need to install Passwordless Login for ssh"
#####################################################################
#echo "-- Enable passwordless root login via rsa key"
#ssh-keygen -f ~/myRSAkey -t rsa -N ""
#mkdir ~/.ssh
#cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
#chmod 400 ~/.ssh/authorized_keys
#ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
#sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
#systemctl restart sshd
#####################################################################
#
echo "-- Start CM, it takes about 2 minutes to be ready"
systemctl start cloudera-scm-server
#
echo "Place the ip here already assumed "
while [ `curl -s -X GET -u "admin:admin"  http://$utilityIP:7180/api/version` -z ] ;
    do
    echo "waiting 10s for CM to come up..";
    sleep 10;
done
#
echo "-- Now CM is started and the next step is to automate using the CM API"
yum install -y epel-release
yum install -y python-pip
pip install --upgrade pip
pip install cm_client
echo "Performing OneNode Cluster installation"
sleep 4
#
#
sed -i "s/YourHostname/`hostname -f`/g" $InsFolder/$TEMPLATE
sed -i "s/YourPrivateIP/`hostname -I | tr -d '[:space:]'`/g" $InsFolder/$TEMPLATE
sed -i "s/YourHostname/`hostname -f`/g" $InsFolder/scripts/create_cluster.py
python $InsFolder/scripts/create_cluster.py $TEMPLATE
#
# configure and start EFM and Minifi
# service minifi start
#
service efm start
echo "`service efm status`"
echo ""
sleep 5
clear
echo " The ip to access Cloudera http://`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`:7180"
echo " Starting User/Pass admin/admin"
echo " Test Mariadb Connection as it is the Metadata DB of Cloudera MetadataDB"
echo " to Test connection use command : mysql -h ip -u root -pcloudera"
echo " You have install Cloudera Manager - you need to access the Guy and install the rest from the Web Interface"
