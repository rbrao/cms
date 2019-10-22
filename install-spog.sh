#!/bin/bash
#Author: SPOGWorks
#Version: 2019.10.22
user=`whoami`
option=$1

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
#	apt install ./libauparse-dev_ubuntu_amd64.deb
#	apt install ./auditd_ubuntu_amd64.deb
	apt install auditd
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
	echo "*** Starting service ... ***"
	service spog-cms start
	echo "*** Done with setup ***"
}

install() {
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
	extract_files
	audit_setup
	spog_enable
}

uninstall() {
	echo "*** Uninstalling ... ***"
	service spog-cms stop
	service auditd stop
	/bin/systemctl disable spog-cms
	/bin/systemctl disable auditd
	apt remove auditd
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

