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
wget -q -O BinExp/gdb-gef/.gdbinit-gef.py https://github.com/hugsy/gef/raw/master/gef.py
echo "source $SCRIPT_DIR/BinExp/gdb-gef/.gdbinit-gef.py" >> ~/.gdbinit

# pwntools
sudo apt-get install python3 python3-pip python3-dev git libssl-dev libffi-dev build-essential
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade pwntools



### Disco tools
echo "[X] Disco"

# rustscan
TEMP_DEB="$(mktemp)"
wget -O "$TEMP_DEB" 'https://github.com/RustScan/RustScan/releases/download/2.0.1/rustscan_2.0.1_amd64.deb'
sudo dpkg -i "$TEMP_DEB"
rm -f "$TEMP_DEB"

# autorecon + dependencies
sudo apt install seclists curl enum4linux feroxbuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf -y
git clone https://github.com/Tib3rius/AutoRecon.git Disco/AutoRecon
python3 -m pip install -r Disco/AutoRecon/requirements.txt
chmod +x Disco/AutoRecon/autorecon.py
sudo ln -s "$SCRIPT_DIR/Disco/AutoRecon/autorecon.py" /usr/local/bin/autorecon

# gobuster
sudo apt-get install gobuster -y

# nc -> netcat-openbsd is IPv6 capable
sudo apt-get install netcat-openbsd -y



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

# BunnyHat
sudo apt install -y golang
git clone https://github.com/DiegoBoy/BunnyHat.git Post/BunnyHat

# nishang
git clone https://github.com/samratashok/nishang.git Post/nishang

# PowerSploit 
git clone https://github.com/PowerShellMafia/PowerSploit.git Post/PowerSploit

# Empire
git clone https://github.com/EmpireProject/Empire.git Post/Empire


### Report tools
echo "[X] Report"

cd Report/AutoRePort/
sudo apt install -y npm node-typescript
sudo npm link
cd $SCRIPT_DIR



# go hack stuff
echo "hephaestus toolkit installed, go hack stuff x_x"
