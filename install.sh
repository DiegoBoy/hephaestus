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



### Disco tools
echo "[X] Disco"

# autorecon + dependencies
sudo apt install pipx python3-pip python3-venv seclists curl enum4linux feroxbuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf -y
pipx install git+https://github.com/Tib3rius/AutoRecon.git
rm -rf ~/.config/AutoRecon

# gobuster
sudo apt-get install gobuster -y

# nc -> netcat-openbsd is IPv6 capable
sudo apt-get install netcat-openbsd -y



### PrivEsc tools
mkdir -p $SCRIPT_DIR/PrivEsc
echo "[X] PrivEsc"

# peas
cd $SCRIPT_DIR/PrivEsc
wget -q -o /dev/null https://raw.githubusercontent.com/carlospolop/privilege-escalation-awesome-scripts-suite/master/linPEAS/linpeas.sh
wget -q -o /dev/null https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/raw/master/winPEAS/winPEASexe/binaries/Release/winPEASany.exe
popd

#pspy
cd $SCRIPT_DIR/PrivEsc
wget -q -o /dev/null https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy32
wget -q -o /dev/null https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64
popd



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
sudo apt install -y npm
sudo npm link $SCRIPT_DIR/Report/AutoRePort



# go hack stuff
echo "hephaestus toolkit installed, go hack stuff x_x"
