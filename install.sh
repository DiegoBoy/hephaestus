#!/bin/bash
# hephaestus installer
echo "Installing..."
sudo apt-get update > /dev/null



### BinExp tools
echo "[X] BinExp"
mkdir -p BinExp

# gdb-gef
sudo apt-get install gdb -y
mkdir BinExp/gdb-gef
wget -q -O BinExp/gdb-gef/.gdbinit-gef.py https://github.com/hugsy/gef/raw/master/gef.py
echo "source $(pwd)/BinExp/gdb-gef/.gdbinit-gef.py" >> ~/.gdbinit



### Disco tools
echo "[X] Disco"

# autorecon + dependencies
sudo apt install python3-venv seclists curl enum4linux feroxbuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf -y
python3 -m pip install --user pipx
python3 -m pipx ensurepath
source ~/.zshrc &> /dev/null
pipx install git+https://github.com/Tib3rius/AutoRecon.git

# gobuster
sudo apt-get install gobuster -y

# nc -> netcat-openbsd is IPv6 capable
sudo apt-get install netcat-openbsd -y



### PrivEsc tools
mkdir -p PrivEsc
echo "[X] PrivEsc"

# peas
cd PrivEsc
wget https://raw.githubusercontent.com/carlospolop/privilege-escalation-awesome-scripts-suite/master/linPEAS/linpeas.sh
wget https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/raw/master/winPEAS/winPEASexe/binaries/Release/winPEASany.exe
cd ..

# linux exploit suggester
git clone https://github.com/DiegoBoy/linux-exploit-suggester.git PrivEsc/linux-exploit-suggester

# windows exploit suggester
git clone https://github.com/bitsadmin/wesng.git PrivEsc/wesng



### Post tools
echo "[X] Post"
mkdir -p Post

# nishang
git clone https://github.com/samratashok/nishang.git Post/nishang

# PowerSploit 
git clone https://github.com/PowerShellMafia/PowerSploit.git Post/PowerSploit

# Empire
git clone https://github.com/EmpireProject/Empire.git Post/Empire



# go hack stuff
echo "hephaestus toolkit installed, go hack stuff x_x"
