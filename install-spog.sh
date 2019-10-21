#!/bin/bash
user=`whoami`

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
	apt install ./libauparse-dev_ubuntu_amd64.deb
	apt install ./auditd_ubuntu_amd64.deb
	folder=`grep '^folders:' -A1 /opt/spog/etc/config.yaml |tail -1|sed s/\'//g |awk -F- '{print $2}'|sed 's/^\ //g'|sed 's/\ /\\\ /g'`
	echo "-w $folder -p rw -k audit-watch" >> /etc/audit/audit.rules
	echo "-w $folder -p rw -k audit-watch" >> /etc/audit/rules.d/audit.rules
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

if [ "$user" = "root" ]; then
	vi config.yaml
	echo "*** Setting up Environment ***"
	export PATH=$PATH:/opt/spog/node/bin
	echo 'PATH=$PATH:/opt/spog/node/bin' >> ~/.profile
	extract_files
	audit_setup
	spog_enable
else
	echo "Please execute as root"
fi

