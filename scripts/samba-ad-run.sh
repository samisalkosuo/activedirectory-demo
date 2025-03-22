#!/bin/bash
 
set -e
 
info () {
    echo "[INFO] $@"
}

error () {
    echo "[ERROR] $@"
    exit -1
}

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

echo "nameserver 8.8.8.8" > /etc/resolv.conf

#copy smb.confg and remove existing dns forwarder entry
cat /etc/samba/smb.conf |grep -v "dns forwarder" >$SAMBA_CONFIG_FILE
#mv /etc/samba/smb.conf $SAMBA_CONFIG_FILE
 
#sed -i s@\\[global\\]@\\[global\\]\\nallow\ dns\ updates\ =\ nonsecure@g $SAMBA_CONFIG_FILE
sed -i s@\\[global\\]@\\[global\\]\\nallow\ dns\ updates\ =\ disabled@g $SAMBA_CONFIG_FILE
sed -i s@\\[global\\]@\\[global\\]\\ndns\ forwarder\ =\ 8.8.8.8@g $SAMBA_CONFIG_FILE
#disable anonymous bind
if [ "$SAMBA_ALLOW_ANONYMOUS_BIND" = "false" ]; then
  sed -i s@\\[global\\]@\\[global\\]\\nrestrict\ anonymous\ =\ 2@g $SAMBA_CONFIG_FILE
fi 

#add TLS config
if [ "$TLS_SAN" != "" ]; then
  if [ "$TLS_IP" != "" ]; then
    tls_ip="-I $TLS_IP"
  else
    tls_ip=""
  fi
  ./create-certificate.sh -c "Samba AD Demo" -f tls ${tls_ip} ${HOSTNAME}.${SAMBA_DOMAIN} ${TLS_SAN}
  mkdir -p /etc/samba/tls/
  mv tls.key tls.crt ca.crt /etc/samba/tls/
  #exit 1
fi

#if tls.key exists, configure TLS
#otherwise self-signed certificate is created
if [[ -f "/etc/samba/tls/tls.crt" ]] && [[ -f "/etc/samba/tls/tls.key" ]] && [[ -f "/etc/samba/tls/ca.crt" ]]; then
  chmod -R 600 /etc/samba/tls/
  sed -i s@\\[global\\]@\\[global\\]\\ntls\ enabled\ =\ yes@g $SAMBA_CONFIG_FILE
  sed -i s@\\[global\\]@\\[global\\]\\ntls\ keyfile\ =\ /etc/samba/tls/tls.key@g $SAMBA_CONFIG_FILE
  sed -i s@\\[global\\]@\\[global\\]\\ntls\ certfile\ =\ /etc/samba/tls/tls.crt@g $SAMBA_CONFIG_FILE
  sed -i s@\\[global\\]@\\[global\\]\\ntls\ cafile\ =\ /etc/samba/tls/ca.crt@g $SAMBA_CONFIG_FILE
fi

info "Provisioning domain controller...done."

#start samba as foreground daemon
samba -D -s $SAMBA_CONFIG_FILE

info "Configuring Samba Active Directory..."

#Samba AD configurations
samba-tool domain passwordsettings set --complexity=off

#Initialize AD
python3 samba-ad-setup.py

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
