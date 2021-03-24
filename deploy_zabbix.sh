#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -h | --help       Displays this help message."
    echo "  --force           Force configuration overwrite."
    echo "  --prefix          Installation prefix (SCRIPT_DIR)."
    echo "  --zabbix-include  Zabbix agent include files directory (ZABBIX_INC)."
    echo "  -b | --openvpn-bind    Configuration key OPENVPN_BIND."
    echo "  -c | --openvpn-config  Configuration key OPENVPN_CONF."
    echo "  -s | --openvpn-status  Configuration key OPENVPN_STATS."
    echo "  --openvpn-ccd          Configuration key OPENVPN_CCD."
    echo "  --openvpn-certs        Configuration key OPENVPN_CERTS."
    echo "  --openvpn-certs-allow  Configuration key OPENVPN_CERTS_ALLOW."
    echo ""
    echo "Please send any bug reports to https://github.com/sergiotocalini/zaovpn/issues"
    exit 1
}

while getopts "h:bcs:-:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	b)
	    OPENVPN_BIND="${OPTARG}"
	    ;;
        c)
            OPENVPN_CONF="${OPTARG}"
            ;;
	s)
	    OPENVPN_STATS="${OPTARG}"
	    ;;
	-  ) [ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1 ) || optind=$OPTIND
	     eval OPTION="\$$optind"
             OPTARG=$(echo $OPTION | cut -d'=' -f2)
             OPTION=$(echo $OPTION | cut -d'=' -f1)
             case $OPTION in
		 --force)
		     FORCE=true
		     ;;
		 --help)
		     usage
		     ;;
		 --zabbix-include)
		     ZABBIX_INC="${OPTARG}"
		     ;;
		 --prefix)
		     SCRIPT_DIR="${OPTARG}"
		     if [[ ! "${SCRIPT_DIR}" =~ .*zaovpn ]]; then
			 SCRIPT_DIR="${SCRIPT_DIR}/zaovpn"
		     fi
		     ;;
		 --openvpn-bind)
		     OPENVPN_BIND="${OPTARG}"
		     ;;
		 --openvpn-config)
		     OPENVPN_CONF="${OPTARG}"
		     ;;
		 --openvpn-ccd)
		     OPENVPN_CCD="${OPTARG}"
		     ;;
		 --openvpn-certs)
		     OPENVPN_CERTS="${OPTARG}"
		     ;;
		 --openvpn-certs-allow)
		     OPENVPN_CERTS_ALLOW="${OPTARG}"
		     ;;
		 --openvpn-pki)
		     OPENVPN_PKI="${OPTARG}"
		     ;;
		 --openvpn-status)
		     OPENVPN_STATS="${OPTARG}"
		     ;;
	     esac
	     ;;
        \?)
	    usage
            ;;
    esac
done

[ -n "${SCRIPT_DIR}"          ] || SCRIPT_DIR="${ZABBIX_DIR}/scripts/agentd/zaovpn"
[ -n "${ZABBIX_INC}"          ] || ZABBIX_INC="${ZABBIX_DIR}/zabbix_agentd.d"
[ -n "${OPENVPN_BIND}"        ] || OPENVPN_BIND="0.0.0.0:1194"
[ -n "${OPENVPN_CONF}"        ] || OPENVPN_CONF="/etc/openvpn/server.conf"
[ -n "${OPENVPN_STATS}"       ] || OPENVPN_STATS="/etc/openvpn/openvpn-status.log"
[ -n "${OPENVPN_CCD}"         ] || OPENVPN_CCD="/etc/openvpn/ccd"
[ -n "${OPENVPN_PKI}"         ] || OPENVPN_PKI="/etc/openvpn/pki"
[ -n "${OPENVPN_CERTS}"       ] || OPENVPN_CERTS="/etc/openvpn/pki/certs"
[ -n "${OPENVPN_CERTS_ALLOW}" ] || OPENVPN_CERTS_ALLOW="/etc/openvpn/pki/user-cert-list.txt"

# Creating necessary directories
mkdir -p "${SCRIPT_DIR}" "${ZABBIX_INC}" 2>/dev/null
# Copying the main script and dependencies
cp -rpv  "${SOURCE_DIR}/zaovpn/zaovpn.sh"           "${SCRIPT_DIR}/zaovpn.sh"
# Provisioning script configuration
SCRIPT_CFG="${SCRIPT_DIR}/zaovpn.conf"
cp -rpv  "${SOURCE_DIR}/zaovpn/zaovpn.conf.example" "${SCRIPT_CFG}.new"
# Adding script configuration values
regex_cfg[0]="s|OPENVPN_BIND=.*|OPENVPN_BIND=\"${OPENVPN_BIND}\"|g"
regex_cfg[1]="s|OPENVPN_CONF=.*|OPENVPN_CONF=\"${OPENVPN_CONF}\"|g"
regex_cfg[2]="s|OPENVPN_STATS=.*|OPENVPN_STATS=\"${OPENVPN_STATS}\"|g"
regex_cfg[3]="s|OPENVPN_CCD=.*|OPENVPN_CCD=\"${OPENVPN_CCD}\"|g"
regex_cfg[4]="s|OPENVPN_PKI=.*|OPENVPN_PKI=\"${OPENVPN_PKI}\"|g"
regex_cfg[5]="s|OPENVPN_CERTS=.*|OPENVPN_CERTS=\"${OPENVPN_CERTS}\"|g"
regex_cfg[6]="s|OPENVPN_PKI=.*|OPENVPN_PKI=\"${OPENVPN_PKI}\"|g"
for index in ${!regex_cfg[*]}; do
    sed -i'' -e "${regex_cfg[${index}]}" "${SCRIPT_CFG}.new"
done
# Checking if the new configuration exist 
if [[ -f "${SCRIPT_CFG}" && ${FORCE:-false} == false ]]; then
    state=$(cmp --silent "${SCRIPT_CFG}" "${SCRIPT_CFG}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_CFG}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_CFG}.new" "${SCRIPT_CFG}" 2>/dev/null
fi
# Provisioning zabbix_agent configuration
SCRIPT_ZBX="${ZABBIX_INC}/zaovpn.conf"
cp -rpv "${SOURCE_DIR}/zaovpn/zabbix_agentd.conf"   "${SCRIPT_ZBX}.new"
regex_inc[0]="s|{PREFIX}|${SCRIPT_DIR}|g"
for index in ${!regex_inc[*]}; do
    sed -i'' -e "${regex_inc[${index}]}" "${SCRIPT_ZBX}.new"
done
if [[ -f "${SCRIPT_ZBX}" ]]; then
    state=$(cmp --silent "${SCRIPT_ZBX}" "${SCRIPT_ZBX}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_ZBX}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_ZBX}.new" "${SCRIPT_ZBX}" 2>/dev/null
fi
