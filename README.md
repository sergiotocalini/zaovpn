# zaovpn
Zabbix Agent - OpenVPN

# Usage
```
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

Please send any bug reports to sergiotocalini@gmail.com
~#
```

# Zabbix deploy
```
#~ git clone https://github.com/sergiotocalini/zaovpn.git
#~ ./zaovpn/deploy_zabbix.sh '0.0.0.0' '1194' '/etc/openvpn/openvpn-status.log' '/etc/openvpn/ccd'
#~
```    
