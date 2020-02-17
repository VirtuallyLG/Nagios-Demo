#!/bin/bash
# install packages for Nagios requirements 
yum install -y httpd httpd-tools php gcc glibc glibc-common gd gd-devel make net-snmp openssl-devel xinetd unzip

# set users for nagios and apache
useradd nagios
groupadd nagcmd
usermod -G nagcmd nagios
usermod -G nagcmd apache

# download the nagios and plugin sourcecode
mkdir ./nagios
cd nagios
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.5.tar.gz
wget https://nagios-plugins.org/download/nagios-plugins-2.3.1.tar.gz
tar zxf nagios-4.4.5.tar.gz
tar zxf nagios-plugins-2.3.1.tar.gz

# compile and install nagios core
cd nagios-4.4.5/
./configure --with-command-group=nagcmd
make all
make install
make install-commandmode
make install-init
make install-config
make install-webconf

# compile and install nagios plugins
cd ../nagios-plugins-2*
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
make
make install

# download and install NRPE
cd ../
curl -L -O http://downloads.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz
tar xvf nrpe-*.tar.gz
cd nrpe*
./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
make all
sudo make install
sudo make install-xinetd
sudo make install-daemon-config

# get host ip and change allowed hosts for NRPE
localip=$(hostname -I)
sed -i "s/127.0.0.1/127.0.0.1 ${localip}/g" /etc/xinetd.d/nrpe 

# modify nagios configuration for server configuration location 
sed -i 's|#cfg_dir=/usr/local/nagios/etc/servers|cfg_dir=/usr/local/nagios/etc/servers|g' /usr/local/nagios/etc/nagios.cfg
mkdir /usr/local/nagios/etc/servers

# modify email for nagios admin
sed -i 's/nagios@localhost/lorenzo.galelli@ionos.com/g'  /usr/local/nagios/etc/objects/contacts.cfg

echo 'define command {
        command_name check_nrpe
        command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}' >> /usr/local/nagios/etc/objects/commands.cfg

# create password for nagiosadmin
htpasswd -cdb /usr/local/nagios/etc/htpasswd.users nagiosadmin Ionos110 # < change password

# ready services for nagios
# systemctl daemon-reload
systemctl start nagios.service
systemctl restart httpd.service
systemctl enable nagios
systemctl enable httpd
echo "Installation of Nagios Core 4.4.5 is complete, connect to the server using http://"$localip"/nagios"
