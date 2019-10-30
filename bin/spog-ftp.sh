#!/bin/bash
SRC=`ls -tr /opt/spog/sbin/*.db|tail -1`
DBFILE=`ls -tr /opt/spog/sbin/*.db|tail -1|awk -F/ '{print \$NF}'`
DISTRICT=`grep ^district /opt/spog/etc/config.yaml |awk -F: '{print $NF}'|sed s/^\ //g`
SUBDIV=`grep ^subdivision /opt/spog/etc/config.yaml |awk -F: '{print $NF}'|sed s/^\ //g`

ftp -np -v 139.59.58.35 << EOT
bin
user spogcms spog123
prompt
mkdir "$DISTRICT"/"$SUBDIV"/$DBFILE
put $SRC "$DISTRICT"/"$SUBDIV"/$DBFILE
bye
EOT
