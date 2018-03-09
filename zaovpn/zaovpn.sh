#!/usr/bin/env ksh
PATH=/usr/local/bin:${PATH}

#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="0.0.1"
APP_WEB="http://www.sergiotocalini.com.ar/"
#
#################################################################################

#################################################################################
#
#  Load Environment
# ------------------
#
[[ -f ${APP_DIR}/${APP_NAME%.*}.conf ]] && . ${APP_DIR}/${APP_NAME%.*}.conf

#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -a            Query arguments."
    echo "  -h            Displays this help message."
    echo "  -j            Jsonify output."
    echo "  -s ARG(str)   Section (default=stat)."
    echo "  -v            Show the script version."
    echo ""
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}

get_service() {
    resource=${1}

    pid=`lsof -Pi TCP@${OPENVPN_LISTEN}:${OPENVPN_PORT} -sTCP:LISTEN -t`
    rcode="${?}"
    if [[ ${resource} == 'listen' ]]; then
	if [[ ${rcode} == 0 ]]; then
	    res=1
	fi
    elif [[ ${resource} == 'uptime' ]]; then
	res=`ps -p ${pid} -o etimes -h`
    fi
    echo ${res:-0}
    return 0
}

get_status() {
    attr=${1}
    qfilter=${2}
    file=${3:-/etc/openvpn/openvpn-status.log}

    index="1:Common Name;2:Real Address;3:Bytes Received;4:Bytes Sent;5:Connected Since"
    
    raw=`awk '/CLIENT LIST/,/ROUTING TABLE/' ${file} | tail -n +4 | head -n -1`
    if ! [[ -z ${qfilter} ]]; then
	raw=`echo "${raw}" | grep "${qfilter}"`
    fi
    
    if [[ ${attr} =~ ^(3|4)$ ]]; then
	res=`echo "${raw}" | awk -F, "{s+=$"${attr}"} END {print s}"`
    else
	res=`echo "${raw}" | wc -l`
    fi
    echo ${res}
    return 0
}
#
#################################################################################

#################################################################################
while getopts "s::a:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SECTION="${OPTARG}"
	    ;;
        j)
            JSON=1
            IFS=":" JSON_ATTR=(${OPTARG//p=})
            ;;
	a)
	    ARGS[${#ARGS[*]}]=${OPTARG//p=}
	    ;;
	v)
	    version
	    ;;
         \?)
            exit 1
            ;;
    esac
done


if [[ ${JSON} -eq 1 ]]; then
    rval=$(discovery ${SECTION} ${ARGS[*]})
    echo '{'
    echo '   "data":['
    count=1
    while read line; do
        IFS="|" values=(${line})
        output='{ '
        for val_index in ${!values[*]}; do
            output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
            if (( ${val_index}+1 < ${#values[*]} )); then
                output="${output}, "
            fi
        done 
        output+=' }'
        if (( ${count} < `echo ${rval}|wc -l` )); then
            output="${output},"
        fi
        echo "      ${output}"
        let "count=count+1"
    done <<< ${rval}
    echo '   ]'
    echo '}'
else
    if [[ ${SECTION} == 'status' ]]; then
	rval=$( get_status ${ARGS[*]} )
	rcode="${?}"
    elif [[ ${SECTION} == 'service' ]]; then
	rval=${ get_service ${ARGS[*]}}
	rcode="${?}"
    fi
    echo ${rval:-0}
fi

exit ${rcode:-0}
