#!/bin/bash
# hephaestus installer
echo "Installing..."
sudo apt-get update > /dev/null
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### BinExp tools
echo "[X] BinExp"
mkdir -p $SCRIPT_DIR/BinExp

# gdb-gef
sudo apt-get install gdb -y
mkdir -p $SCRIPT_DIR/BinExp/gdb-gef
wget -q -O $SCRIPT_DIR/BinExp/gdb-gef/.gdbinit-gef.py https://github.com/hugsy/gef/raw/master/gef.py
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
sudo apt install pipx python3-pip python3-venv seclists curl enum4linux feroxbuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf -y
pipx install git+https://github.com/Tib3rius/AutoRecon.git
rm -rf ~/.config/AutoRecon

# gobuster
sudo apt-get install gobuster -y

# nc -> netcat-openbsd is IPv6 capable
sudo apt-get install netcat-openbsd -y



### PrivEsc tools
echo "[X] PrivEsc"
mkdir -p $SCRIPT_DIR/PrivEsc

# peas
cd $SCRIPT_DIR/PrivEsc
wget -q -o /dev/null https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh
wget -q -o /dev/null https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany_ofs.exe --output-document=winpeas.exe
popd 2>/dev/null

#pspy
cd $SCRIPT_DIR/PrivEsc
wget -q -o /dev/null https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy32
wget -q -o /dev/null https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64
popd 2>/dev/null



### Post tools
echo "[X] Post"
mkdir -p $SCRIPT_DIR/Post

# nishang
git clone https://github.com/samratashok/nishang.git $SCRIPT_DIR/Post/nishang

# PowerSploit 
git clone https://github.com/PowerShellMafia/PowerSploit.git $SCRIPT_DIR/Post/PowerSploit

# Empire
git clone https://github.com/EmpireProject/Empire.git $SCRIPT_DIR/Post/Empire



### Report tools
echo "[X] Report"

cd $SCRIPT_DIR/Report/AutoRePort/
sudo apt install -y npm node-typescript
sudo npm link
popd



# go hack stuff
echo "hephaestus toolkit installed, go hack stuff x_x"
