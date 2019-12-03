#!/bin/sh
#Author: rewardone
#Description:
# Requires root or enough permissions to use tcpdump
# Will listen for the first 7 packets of a null login
# and grab the SMB Version
#Notes:
# Will sometimes not capture or will print multiple
# lines. May need to run a second time for success.
#DiegoBoy:
# 1. Added interface parameter (hardcoded before)
# 2. Added sleep statements to increase probability
#    of gettng and printing version at first run
if [ -z $1 ] || [ -z $2 ]; then echo "Usage: ./smbver.sh <interface> <ip4_addr/hostname> [port]" && exit; else iface=$1; rhost=$2; fi
if [ ! -z $3 ]; then rport=$3; else rport=139; fi

tcpdump -s0 -n -i $iface src $rhost and port $rport -A -c 7 2>/dev/null | grep -i "samba\|s.a.m" | tr -d '.' | grep -oP 'UnixSamba.*[0-9a-z]' | tr -d '\n' & echo -n "$rhost: " &
sleep 1 && echo "exit" | smbclient -L $rhost 1>/dev/null 2>/dev/null
sleep 2 && echo ""