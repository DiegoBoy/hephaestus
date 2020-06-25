#!/bin/bash
# hephaestus installer

echo "Installing..."


### BinExp tools
mkdir -p BinExp

# gdb-gef
sudo apt-get install gdb -y
mkdir BinExp/gdb-gef
wget -q -O BinExp/gdb-gef/.gdbinit-gef.py https://github.com/hugsy/gef/raw/master/gef.py
echo "source $(pwd)/BinExp/gdb-gef/.gdbinit-gef.py" >> ~/.gdbinit

echo "[X] BinExp"



### Creds tools
mkdir -p Creds

# seclists
sudo apt-get install seclists -y



### Disco tools
mkdir -p Disco

# gobuster
sudo apt-get install gobuster -y

# nc -> netcat-openbsd is IPv6 capable
sudo apt-get install netcat-openbsd -y

echo "[X] Disco"



### PrivEsc tools

# linux exploit suggester
git clone https://github.com/DiegoBoy/linux-exploit-suggester.git PrivEsc/linux-exploit-suggester

# windows exploit suggester
git clone https://github.com/bitsadmin/wesng.git PrivEsc/wesng

echo "[X] PrivEsc"



### misc tools
mkdir -p misc

# nishang
git clone https://github.com/samratashok/nishang.git misc/nishang

# PowerSploit 
git clone https://github.com/PowerShellMafia/PowerSploit.git misc/PowerSploit

# Empire
git clone https://github.com/EmpireProject/Empire.git misc/Empire

echo "[X] misc"



# go hack stuff
echo "hephaestus toolkit installed, go hack stuff x_x"
