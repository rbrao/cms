#!/bin/bash
#Author: SPOGWorks
#Version: 2019.10.22_02
user=`whoami`
option=$1

precheck() {
	echo "*** Checking and Installing dependent packages ***"
	auditd_state=`dpkg -l auditd|grep '^ii'|awk '{print $2}'`
	if [ "$auditd_state" != "auditd" ]; then
		apt install auditd
	fi
	dmid_state=`dpkg -l dmidecode|grep '^ii'|awk '{print $2}'`
	if [ "$dmid_state" != "dmidecode" ]; then
		apt install dmidecode
	fi
	x11_state=`dpkg -l x11-xserver-utils|grep '^ii'|awk '{print $2}'`
	if [ "$x11_state" != "x11-xserver-utils" ]; then
		apt install x11-server-utils
	fi
	util_state=`dpkg -l util-linux|grep '^ii'|awk '{print $2}'`
	if [ "$util_state" != "util-linux" ]; then
		apt install util-linux
	fi
	udev_state=`dpkg -l udev|grep '^ii'|awk '{print $2}'`
	if [ "$udev_state" != "udev" ]; then
		apt install udev
	fi
	final_check=`dpkg -l auditd dmidecode x11-xserver-utils util-linux udev|grep '^ii'|wc -l`
	if [ "$final_check" -ne 5 ]; then
		echo "Some dependency packages were not installed. Please install manually and rereun installer"
		exit -1
	fi
}

postcheck() {
	/opt/spog/node/bin/bytenode /opt/spog/sbin/list.jsc
	service auditd status
	service spog-cms status
	auditctl -l
}

extract_files() {
	if [ ! -e /opt ]; then
		mkdir /opt
	fi
	echo "*** Extracting files to /opt/spog ***"
	tar -zxf spog-linux.tar.gz && mv spog /opt/
	cp config.yaml /opt/spog/etc/
	echo "*** Creating data and logs folders ***"
	mkdir /opt/spog/data /opt/spog/logs
}

audit_setup() {
	echo "*** Setting up auditd ***"
	folder=`grep '^folders:' -A1 /opt/spog/etc/config.yaml |tail -1|sed s/\'//g |awk -F- '{print $2}'|sed 's/^\ //g'|sed 's/\ /\\\ /g'`
	echo "-w $folder -p rw -k audit-watch" >> /etc/audit/audit.rules
	echo "-w $folder -p rw -k audit-watch" >> /etc/audit/rules.d/audit.rules
	/bin/systemctl enable auditd
	service auditd restart
}

spog_enable() {
	echo "*** Setting up init scripts and enabling service ***"
	cp spog-init.sh /opt/spog/bin && chmod a+x /opt/spog/bin/spog-init.sh
	cp spog-cms.service /etc/systemd/system/
	/bin/systemctl enable spog-cms
	if [ -e /tmp/spog.db.prev ]; then
		read -p "Found an existing DB file. DO YOU WANT TO MERGE (Y/n)?" merge_response
		if [ "$merge_response" = "y" ] || [ "$merge_response" = "Y" ]; then
			cp /tmp/spog.db.prev /opt/spog/data/spog.db
			echo "*** DB Merged ***"
		fi
	fi
	echo "*** Starting service ... ***"
	service spog-cms start
}

install() {
	if [ -e /opt/spog ]; then
		echo "spog-cms is already installed. Run $0 reinstall instead"
		exit 0
	fi
	echo "Installing ..."
	vi config.yaml
	read -p "DO YOU WANT TO CONTINUE .. (Y/n)?" response
	if [ "$response" = "n" ] || [ "$response" = "N" ]; then
		echo "*** User initiated abort. Exiting ***"
		exit 0
	fi
	echo "*** Setting up Environment ***"
	export PATH=$PATH:/opt/spog/node/bin
	echo 'PATH=$PATH:/opt/spog/node/bin' >> ~/.profile
	source ~/.profile
	precheck
	extract_files
	audit_setup
	spog_enable
	postcheck
	echo "*** Done with setup ***"
}

uninstall() {
	echo "*** Uninstalling ... ***"
	service spog-cms stop
	service auditd stop
	/bin/systemctl disable spog-cms
	/bin/systemctl disable auditd
#	apt remove auditd
	cp /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules.old
	cp /etc/audit/audit.rules /etc/audit/audit.rules.old
	grep -v '^-w' /etc/audit/audit.rules.old > /etc/audit/audit.rules
	grep -v '^-w' /etc/audit/rules.d/audit.rules.old > /etc/audit/rules.d/audit.rules
	rm -rf /opt/spog
	echo "*** Uninstalled ***"
}

reinstall() {
	cp -p /opt/spog/data/spog.db /tmp/spog.db.prev
	echo "*** Existing DB file copied to /tmp ***"
	uninstall
	install
}

update() {
	echo "Updating ..."
}

if [ "$user" = "root" ] && [ "$option" != "" ]; then
	case $option in
		install )
			install ;;
		uninstall )
			uninstall ;;
		update )
			update ;;
		reinstall )
			reinstall ;;
	esac
else
	echo "Please execute as root with appropriate parameters
	USAGE: $0 install|uninstall|reinstall|update"
fi

