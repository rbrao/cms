#!/bin/bash
DISTRICT=`grep -i ^district /opt/spog/etc/config.yaml |awk -F: '{print $NF}'|sed s/^\ //g`
SUBDIV=`grep -i ^subdivision /opt/spog/etc/config.yaml |awk -F: '{print $NF}'|sed s/^\ //g`
SCHOOL=`grep -i ^school /opt/spog/etc/config.yaml |awk -F: '{print $NF}'|sed s/^\ //g`

/opt/spog/node/bin/bytenode /opt/spog/sbin/copydb.jsc
SRC=`ls -tr /opt/spog/sbin/*.db|tail -1`
DBFILE=`ls -tr /opt/spog/sbin/*.db|tail -1|awk -F/ '{print \$NF}'`

ftp -np -v 139.59.58.35 << EOT
bin
user spogcms spog123
prompt
mkdir "$DISTRICT"
mkdir "$DISTRICT"/"$SUBDIV"
mkdir "$DISTRICT"/"$SUBDIV"/"$SCHOOL"
put $SRC "$DISTRICT"/"$SUBDIV"/"$SCHOOL"/$DBFILE
bye
EOT
