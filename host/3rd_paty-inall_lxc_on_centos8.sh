#!/bin/bash

# do not forget to add below line to sudoers file
# we need sudo to not ask for password for virl user
# virl ALL=(ALL) NOPASSWD: ALL


LXC_BRANCH="stable-3.0"
LXC_NET_SCRIPT="/usr/local/libexec/lxc/lxc-net"
LXC_NET_CONF="/usr/local/etc/sysconfig/lxc-net"

sudo dnf update -y
sudo dnf install epel-release -y
sudo dnf groupinstall "Development Tools" -y
# we need dnsmasq as it used by '/usr/local/libexec/lxc/lxc-net start'
sudo dnf install dnsmasq -y
sudo dnf install git htop libtool openssl-devel libcap-devel wget -y

git clone https://github.com/lxc/lxc.git -b "$LXC_BRANCH"
cd lxc || exit 1
./autogen.sh
./configure
#--disable-dependency-tracking \
#--enable-apparmor \
#--enable-openssl \
#--enable-selinux \
#--enable-capabilities \
#--enable-tests

make
sudo make install

cd ~ || exit 1
git clone https://github.com/lxc/lxc-templates.git
cd lxc-templates || exit 1
./autogen.sh
./configure
make
sudo make install

cd ~ || exit 1

sudo chmod u+s /usr/bin/new{g,u}idmap

mkdir -p ~/.config/lxc/
cat >> ~/.config/lxc/default.conf<< EOF
lxc.include = /usr/local/etc/lxc/default.conf
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536
EOF

# in script /usr/local/libexec/lxc/lxc-net USE_LXC_BRIDGE=true
# above script then loads /usr/local/etc/sysconfig/lxc where USE_LXC_BRIDGE=false
# that in turn loads /usr/local/etc/sysconfig/lxc-net if exists (it doesn't by default)
# that is why we create below file so the bridge will be created correctly
echo 'USE_LXC_BRIDGE="true"' | sudo sh -c "cat >> $LXC_NET_CONF"
[ -f "$LXC_NET_CONF" ] || exit 1

# dnsmasq directory structure changed - we need to create dir for lxc
# to store lease file
# directory named 'misc' will be created in location defined by 'varlib'
# variable in '/usr/local/libexec/lxc/lxc-net' script
VARLIB=$(grep "varlib=" "$LXC_NET_SCRIPT" | awk -F= '{ print $2 }')
sudo mkdir -p "${VARLIB:1:-1}/misc"

sudo "$LXC_NET_SCRIPT" start

LXC_BRIDGE=$(grep -w "LXC_BRIDGE=" "$LXC_NET_SCRIPT" | awk -F= '{ print $2 }')

ip addr show "${LXC_BRIDGE:1:-1}" || exit 1

echo "done"
