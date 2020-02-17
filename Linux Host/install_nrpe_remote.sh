#!/bin/bash
# Install EPEL and NRPE binaries
yum install epel-release -y
yum install nrpe -y

# Additional packages for IONOS API calls
yum install jq curl -y 
 
# Install plugins for Linux Remote Host
# list available plugins with -> yum list nagios-plugins*
yum install nagios-plugins-{load,http,users,procs,disk,swap,nrpe,uptime} -y

# Install additional plugins from Nagios Exchange Library, Mem, CPU and HTTPS checks
cd /usr/lib64/nagios/plugins/
wget "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=1384&cf_id=24" -O check_https
chmod +x /usr/lib64/nagios/plugins/check_https
wget "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=4174&cf_id=24" -O check_mem
chmod +x /usr/lib64/nagios/plugins/check_mem
wget "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=6998&cf_id=24" -O check_cpu.sh
chmod +x /usr/lib64/nagios/plugins/check_cpu.sh

# Add Nagios Core server to allowed hosts for NRPE execution
nagios_core=10.10.1.12 # <- will need to be changed to your Nagios Core Server
sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,${nagios_core}/" /etc/nagios/nrpe.cfg 

# Set Firewall ports for 5666
firewall-cmd --add-service=nrpe --permanent
firewall-cmd --reload

# Ready services for NRPE
systemctl start nrpe
systemctl enable nrpe

# Script can end here if required

#edit /etc/nagios/nrpe.cfg  and amend command section as below.

#command[check_users]=/usr/lib64/nagios/plugins/check_users -w 5 -c 10
#command[check_load]=/usr/lib64/nagios/plugins/check_load -r -w 8.0,7.5,7.0 -c 11.0,10.0,9.0
#command[check_vda1]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /dev/vda1
#command[check_mem]=/usr/lib64/nagios/plugins/check_mem -w 75 -c 90
#command[check_zombie_procs]=/usr/lib64/nagios/plugins/check_procs -w 5 -c 10 -s Z
#command[check_total_procs]=/usr/lib64/nagios/plugins/check_procs -w 150 -c 200
#command[check_swap]=/usr/lib64/nagios/plugins/check_swap -w 10 -c 5
#command[check_http]=/usr/lib64/nagios/plugins/check_https ionos.co.uk
# then restart nrpe - > systemctl restart nrpe 

# Check open ports for NRPE 5666
#ss -altn | grep 5666
#netstat -an | grep 5666
# Test plugins
#/usr/lib64/nagios/plugins/check_nrpe -H 127.0.0.1 -c check_load
#/usr/lib64/nagios/plugins/check_nrpe -H 127.0.0.1 -c check_total_procs
#/usr/lib64/nagios/plugins/check_nrpe -H 127.0.0.1 -c check_swap
#/usr/lib64/nagios/plugins/check_nrpe -H 127.0.0.1 -c check_users
#/usr/lib64/nagios/plugins/check_nrpe -H 127.0.0.1 -c check_disk
#/usr/lib64/nagios/plugins/check_nrpe -H 127.0.0.1 -c check_mem