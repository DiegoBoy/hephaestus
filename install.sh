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



### Disco tools
mkdir -p Disco

# enyx.py
wget -q -O Disco/enyx.py https://raw.githubusercontent.com/trickster0/Enyx/master/enyx.py

# gobuster
sudo apt-get install gobuster -y

echo "[X] Disco"



### PrivEsc tools
mkdir -p PrivEsc

# linux exploit suggester
git clone https://github.com/DiegoBoy/linux-exploit-suggester.git PrivEsc/linux-exploit-suggester
ln -s PrivEsc/linux-exploit-suggester/linux-exploit-suggester.sh PrivEsc/les.sh

# windows exploit suggester
git clone https://github.com/bitsadmin/wesng.git PrivEsc/wesng
ln -s PrivEsc/wesng/wes.py PrivEsc/wes.py

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
