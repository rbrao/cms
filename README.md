# spog-cms
## Installation procedure

## Linux/Ubuntu/CentOS
1. Download contents to a temporary location
2. `cd /tmp/location`   (Replace /tmp/location to actual temporary location)
3. `./install-spog.sh install | uninstall | reinstall | update`  (Run `chmod a+x *.sh` if unable to execute)
	- reinstall will uninstall and perform a fresh install
	- update will refresh files under bin and sbin

### Current changelist
* All identified install options included
* Handling of auditd persistence across reboots
* Segregated handling of bin and sbin files
* Include copydb script
* Auto ftp script

### Future changelist
* Enable execute of external pen/flash drives
* Cleaner error handling

## Windows 10
* Configure Directory audit,
	- Folder properties > advanced > audit. Select users and apply.

* Extract to c:\spog
* c:\spog\node\bytenode c:\spog\sbin\spog.jsc
