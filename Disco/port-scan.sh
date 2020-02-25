#!/bin/bash

function log_info() {
    green="\033[0;32m"
    nc="\033[0m"
    echo -e "${green}${1}${nc}"
}

function help() {
    echo "Usage: $(basename ${0}) <-t | -u> <target> [-6]"
    echo ""
    echo "Options:"
    echo "      -t                TCP scan"
    echo "      -u                UDP scan"
    echo "      -6                IPv6 scan"
    exit 1
}

function nmap() {    
    sudo grc nmap ${@}
}


protocol=""
nmap_flag=""
amap_flag=""
ip_flag=""

# check argc and protocol
if [[ ${#} -lt 2 ]] || [[ ${#} -gt 3 ]]; then
    help
else
    case "${1}" in
        "-t")
        protocol="tcp"
        nmap_flag="-sS"
        amap_flag=""
        ;;

        "-u")
        protocol="udp"
        nmap_flag="-sU"
        amap_flag="-u"
        ;;

        *)
        help
        ;;
    esac
fi

# check optional IPv6 flag
if [[ ${3} ]]; then
    if [[ ${3} == "-6" ]]; then
        ip_flag="-6"
    else
        help
    fi
fi

target=${2}
open_filename="${protocol}-open${ip_flag}.nmap.grep"
nmap_filename="${protocol}-scan${ip_flag}.nmap"
amap_filename="${protocol}-scan${ip_flag}.amap"

log_info "[*] Looking for open ports..."
nmap ${target} ${nmap_flag} -n -Pn -v -p- -T5 -oG ${open_filename} ${ip_flag}

if [[ -z $(grep /open/ ${open_filename}) ]]; then
    log_info "[-] No open ports found, bye!"
    exit 0

log_info "[*] Scanning ports (nmap)..."
# get comma-separated-values of open ports from gnmap file
csv_open_ports=$(cat ${open_filename} | tail -n 2 | head -n 1 | cut -f2 | grep -oP '(\d+)(?=/open)' | paste -sd ',')
nmap ${target} ${nmap_flag} -n -Pn -v -p${csv_open_ports} -A -oN ${nmap_filename} ${ip_flag}

log_info "[*] Scanning ports (amap)..."
# pass space-separated-values for amap because there's a bug parsing IPv6 addresses from gnmap file
ssv_open_ports=$(echo ${csv_open_ports} | tr "," " ")
amap -A ${amap_flag} -i ${open_filename} -o ${amap_filename} ${ip_flag} ${target} ${ssv_open_ports}