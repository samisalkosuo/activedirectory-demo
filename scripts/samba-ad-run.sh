#!/bin/bash
 
set -e
 
info () {
    echo "[INFO] $@"
}

error () {
    echo "[ERROR] $@"
    exit -1
}

if [ "$SAMBA_DOMAIN" = "" ]; then
  error "SAMBA_DOMAIN not set."
fi 

if [ "$SAMBA_ADMIN_PASSWORD" = "" ]; then
  error "SAMBA_ADMIN_PASSWORD not set."
fi 

info "Starting Samba Active Directory..."

info "Provisioning domain controller..."
  
rm /etc/samba/smb.conf

#setup idmaps
sed -i 's/lowerBound: 3000000/lowerBound: 10000/g' /usr/share/samba/setup/idmap_init.ldif
sed -i 's/upperBound: 4000000/upperBound: 60000/g' /usr/share/samba/setup/idmap_init.ldif

#configure samba AD 
samba-tool domain provision\
 --server-role=dc \
 --dns-backend=SAMBA_INTERNAL \
 --use-rfc2307 \
 --realm=${SAMBA_DOMAIN} \
 --domain=DEMO-AD \
 --adminpass=${SAMBA_ADMIN_PASSWORD} \
 --option="vfs objects = acl_xattr xattr_tdb" \
 --option="idmap config * : range = 10000-60000"

SAMBA_CONFIG_FILE=/var/lib/samba/private/smb.conf

mv /etc/samba/smb.conf $SAMBA_CONFIG_FILE
 
sed -i s@\\[global\\]@\\[global\\]\\nallow\ dns\ updates\ =\ nonsecure@g $SAMBA_CONFIG_FILE
sed -i s@\\[global\\]@\\[global\\]\\ndns\ forwarder\ =\ 8.8.8.8@g $SAMBA_CONFIG_FILE

info "Provisioning domain controller...done."
 
#start samba as foreground daemon
samba -D -s /var/lib/samba/private/smb.conf

info "Configuring Samba Active Directory..."

#Samba AD configurations
samba-tool domain passwordsettings set --complexity=off

#Initialize AD
python3 samba-ad-setup.py

samba-tool group add testgroup2

info "Configuring Samba Active Directory...done."

info "Starting Samba Active Directory...done."

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c {
    #     echo "** Trapped CTRL-C"
    # SAMBA_PID=$(cat /run/samba/samba.pid)
    # kill $SAMBA_PID
    info "Shutting down Samba Active Directory."
    exit 0
}

info "Press [CTRL+C] to stop."

while true
do
    if [ "$SAMBA_PRINT_LOG" = "true" ]; then
        tail -f /var/log/samba/log.samba
    else
        sleep 1
    fi 	
done
