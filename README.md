# zaovpn
OpenVPN Monitoring

This script is part of a monitoring solution that allows to monitor several
services and applications.

For more information about this monitoring solution please check out this post
on my [site](https://sergiotocalini.github.io/project/monitoring).

# Dependencies
## Packages
* ksh

### Debian/Ubuntu

```
~# sudo apt install ksh
~#
```

### Red Hat

```
#~ sudo yum install ksh
~#
```

# Usage

```bash
~# ./zaovpn.sh -h
Usage: zaovpn [Options]

Options:
  -a            Query arguments.
  -h            Displays this help message.
  -j            Jsonify output.
  -s ARG(str)   Section (status or service).
  -v            Show the script version.

Examples:

  ~# zaovpn.sh -s certs -j ID:STATUS
  {
     "data":[
         { "{#ID}":"sergio.tocalini.sha256.2048", "{#STATUS}":"0" }
      ]
  }
  ~# zaovpn.sh -s cert -a p="sergio.tocalini.sha256.2048" -a p=after 
  1580550683
  ~# zaovpn.sh -s cert -a p="sergio.tocalini.sha256.2048" -a p=expires
  317
  ~#

Please send any bug reports to https://github.com/sergiotocalini/zaovpn/issues
~#
```

# Deploy
## Sudoers
The deploy script is not intended to advise which approach you should implemented nor
deploy the sudoers configuration but the user that will run the script needs to have
sudo privileges for some checks.

There are two options to setting up sudoers for the user:
1. Provided sudo all
```bash
~# cat /etc/sudoers.d/user_zabbix
Defaults:zabbix !syslog
Defaults:zabbix !requiretty

zabbix	ALL=(ALL)  NOPASSWD:ALL
~#
```
2. Limited acccess to run command with sudo
```bash
~# cat /etc/sudoers.d/user_zabbix
Defaults:zabbix !syslog
Defaults:zabbix !requiretty

zabbix ALL=(ALL) NOPASSWD: /usr/bin/lsof *
zabbix ALL=(ALL) NOPASSWD: /bin/ps *
zabbix ALL=(ALL) NOPASSWD: /usr/bin/find *
zabbix ALL=(ALL) NOPASSWD: /usr/bin/grep *
zabbix ALL=(ALL) NOPASSWD: /usr/bin/openssl *
~#
```
## Parameters
Default variables:

NAME|VALUE
----|-----
OPENVPN_BIND|0.0.0.0:1194
OPENVPN_CONF|/etc/openvpn/server.conf
OPENVPN_STATS|/etc/openvpn/openvpn-status.log
OPENVPN_CCD|/etc/openvpn/ccd
OPENVPN_PKI|/etc/openvpn/pki
OPENVPN_CERTS|/etc/openvpn/pki/certs
OPENVPN_CERTS_ALLOW|/etc/openvpn/pki/user-cert-list.txt

*__Note:__ these variables have to be saved in the config file (zaovpn.conf) in
the same directory than the script.*

## Zabbix
```bash
~# git clone https://github.com/sergiotocalini/zaovpn.git
~# ./zaovpn/deploy_zabbix.sh --help
Usage:  [Options]

Options:
  -h | --help            Displays this help message.
  --force                Force configuration overwrite.
  --prefix               Installation prefix (SCRIPT_DIR).
  --zabbix-include       Zabbix agent include files directory (ZABBIX_INC).
  -b | --openvpn-bind    Configuration key OPENVPN_BIND.
  -c | --openvpn-config  Configuration key OPENVPN_CONF.
  -s | --openvpn-status  Configuration key OPENVPN_STATS.
  --openvpn-ccd          Configuration key OPENVPN_CCD.
  --openvpn-certs        Configuration key OPENVPN_CERTS.
  --openvpn-certs-allow  Configuration key OPENVPN_CERTS_ALLOW.

Please send any bug reports to https://github.com/sergiotocalini/zaovpn/issues
~# sudo ./zaovpn/deploy_zabbix.sh \
	--prefix="/etc/zabbix/scripts/agentd" \
	--zabbix-include="/etc/zabbix/zabbix_agentd.d" \
	--openvpn-bind="0.0.0.0:1194" \
	--openvpn-config="/etc/openvpn/server.conf" \
	--openvpn-ccd="/etc/openvpn/ccd" \
	--openvpn-certs="/etc/openvpn/pki/certs" \
	--openvpn-certs-allow="/etc/openvpn/pki/user-cert-list.txt" \
	--openvpn-status="/etc/openvpn/openvpn-status.log"
~# sudo systemctl restart zabbix-agent
```

*__Note:__ the installation has to be executed on the zabbix agent host and you have
to import the template on the zabbix web. The default installation directory is
/etc/zabbix/scripts/agentd/zaovpn*
