#!/bin/bash
# hephaestus installer
echo "Installing..."
sudo apt-get update > /dev/null
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

### BinExp tools
echo "[X] BinExp"
mkdir -p BinExp

# gdb-gef
sudo apt-get install gdb -y
mkdir -p BinExp/gdb-gef
wget -q -o /dev/null -O BinExp/gdb-gef/.gdbinit-gef.py https://github.com/hugsy/gef/raw/master/gef.py
echo "source $SCRIPT_DIR/BinExp/gdb-gef/.gdbinit-gef.py" >> ~/.gdbinit

# pwntools
sudo apt-get install python3 python3-pip python3-dev git libssl-dev libffi-dev build-essential
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade pwntools



### Disco tools
echo "[X] Disco"

# rustscan
TMP_FILE="$(mktemp)"
wget -q -o /dev/null -O $TMP_FILE 'https://github.com/RustScan/RustScan/releases/download/2.0.1/rustscan_2.0.1_amd64.deb'
sudo dpkg -i $TMP_FILE
rm -f $TMP_FILE

# autorecon + dependencies
sudo apt install seclists curl enum4linux feroxbuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf -y
git clone https://github.com/Tib3rius/AutoRecon.git Disco/AutoRecon
sudo python3 -m pip install -r Disco/AutoRecon/requirements.txt
chmod +x Disco/AutoRecon/autorecon.py
sudo ln -s "$SCRIPT_DIR/Disco/AutoRecon/autorecon.py" /usr/local/bin/autorecon

# gobuster
sudo apt-get install gobuster -y

# nc -> netcat-openbsd is IPv6 capable
sudo apt-get install netcat-openbsd -y



### Lateral movement tools
echo "[X] Lateral"

# sshuttle
sudo apt install sshuttle -y

# ligolo-ng
#go build -o server cmd/proxy/main.go
#GOOS=windows GOARCH=i386 go build -o agent_windows_x32.exe cmd/agent/main.go
#GOOS=windows GOARCH=amd64 go build -o agent_windows_x64.exe cmd/agent/main.go
#GOOS=linux GOARCH=i386 go build -o agent_linux_x32.exe cmd/agent/main.go
#GOOS=linux GOARCH=amd64 go build -o agent_linux_x64.exe cmd/agent/main.go

### PrivEsc tools
echo "[X] PrivEsc"
mkdir -p PrivEsc

# peas
cd PrivEsc
wget -q -o /dev/null https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh
wget -q -o /dev/null https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany_ofs.exe --output-document=winpeas.exe
cd $SCRIPT_DIR

#pspy
cd PrivEsc
wget -q -o /dev/null https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy32
wget -q -o /dev/null https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64
cd $SCRIPT_DIR



### Post tools
echo "[X] Post"
mkdir -p Post

## C2
# Sliver
curl https://sliver.sh/install | sudo bash 

# nishang
git clone https://github.com/samratashok/nishang.git Post/nishang

# PowerSploit 
git clone https://github.com/PowerShellMafia/PowerSploit.git Post/PowerSploit

# Empire
git clone https://github.com/EmpireProject/Empire.git Post/Empire

## Tools
# BunnyHat
sudo apt install -y golang
git clone https://github.com/DiegoBoy/BunnyHat.git Post/BunnyHat

# Sysinternals
mkdir -p Post/Sysinternals
cd Post/Sysinternals
TMP_FILE="$(mktemp)"
wget -q -o /dev/null -O $TMP_FILE 'https://download.sysinternals.com/files/SysinternalsSuite.zip'
unzip -q $TMP_FILE
rm -f $TMP_FILE
cd $SCRIPT_DIR



### Report tools
echo "[X] Report"

cd Report/AutoRePort/
sudo apt install -y npm node-typescript
npm i -D @types/node
sudo npm i -g .
cd $SCRIPT_DIR



# go hack stuff
echo "hephaestus toolkit installed, go hack stuff x_x"
