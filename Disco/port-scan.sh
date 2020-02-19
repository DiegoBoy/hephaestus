#!/bin/bash

function log_info() {
    green="\033[0;32m"
    nc="\033[0m"
    echo -e "${green}${1}${nc}"
}

function help() {
    echo "Usage: ${0} <'tcp' | 'udp'}> <hostname | ip>"
    exit 1
}

function nmap() {    
    sudo grc nmap ${@}
}


protocol=""
scan=""
if [[ ${#} -ne 2 ]]; then
    help
else
    case "${1,,}" in
        "tcp" | "-t")
        protocol="tcp"
        scan="-sS"
        ;;

        "udp" | "-u")
        protocol="udp"
        scan="-sU"
        ;;

        *)
        help
        ;;
    esac
fi

target=${2}
open_filename="${protocol}-open.nmap"
scan_filename="${protocol}-scan.nmap"

log_info "[*] Looking for open ports..."
nmap ${target} ${scan} -n -Pn -v -p- -T5 -oG ${open_filename}
csv_open_ports=$(cat ${open_filename} | tail -n 2 | head -n 1 | cut -f2 | grep -oP '(\d+)(?=/open)' | paste -sd ',')

log_info "[*] Scanning ports found..."
nmap $target ${scan} -n -Pn -v -p${csv_open_ports} -A -oN ${scan_filename}
