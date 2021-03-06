#!/bin/bash
set -e
#set -x

if [ "${LOG}" == "TRUE" ]; then
    LOG_DIR=/var/log/letsencrypt
	LOG_FILE=${LOG_DIR}/runtime.log
	mkdir -p ${LOG_DIR}
	touch ${LOG_FILE}

	UUID=$(cat /proc/sys/kernel/random/uuid)
	exec > >(read message; echo "${UUID} $(date -Iseconds) [info] $message" | tee -a ${LOG_FILE} )
	exec 2> >(read message; echo "${UUID} $(date -Iseconds) [error] $message" | tee -a ${LOG_FILE} >&2)
fi

if [ "${LE_ENV}" == 'production' ]; then
	echo "***** production *****"
	sed -i 's@CA=.*@CA="https://acme-v02.api.letsencrypt.org/directory"@g' /etc/dehydrated/config
else
	echo "***** staging *****"
fi

# comma = new line
if [ -z ${LE_DOMAIN+x} ]; then
    echo "***** Skipping domains.txt *****"
    echo "Ensure --domain arg is set"
else
    echo "***** Creating domains.txt *****"
    echo ${LE_DOMAIN} | sed -e $'s/,/\\\n/g' > /etc/dehydrated/domains.txt
    cat /etc/dehydrated/domains.txt
fi

if [ "${LE_KEY_ALGO}" == 'rsa' ]; then
    echo "***** KEY ALGORITHM ${LE_KEY_ALGO} *****"
    sed -i 's@KEY_ALGO=.*@KEY_ALGO=rsa@g' /etc/dehydrated/config
else 
    if [ "${LE_KEY_ALGO}" == 'prime256v1' ]; then
        echo "***** KEY ALGORITHM ${LE_KEY_ALGO} *****"
        sed -i 's@KEY_ALGO=.*@KEY_ALGO=prime256v1@g' /etc/dehydrated/config
    fi
fi

if [ "${LE_KEYSIZE}" == '2048' ]; then
    echo "***** KEY SIZE ${LE_KEYSIZE} bits *****"
    sed -i 's@KEYSIZE=.*@KEYSIZE="2048"@g' /etc/dehydrated/config
else
    echo "***** KEY SIZE 4096 bits *****"
fi


echo "${@}"
exec "${@}"
