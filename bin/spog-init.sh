#!/bin/bash
export PATH=$PATH:/opt/spog/node/bin
audit_output=`/sbin/auditctl -l`
if [ "$audit_output" = "No Rules" ] || [ "$audit_output" = "" ]; then
	service auditd restart
fi
