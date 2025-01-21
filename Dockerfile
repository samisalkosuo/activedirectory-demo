FROM kazhar/certificate-authority as cert

FROM ubuntu:23.10

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install samba krb5-config winbind smbclient iproute2 openssl vim tmux

WORKDIR /ad

RUN rm /etc/krb5.conf

# RUN  useradd -s /bin/bash -d /home/samba/ -m -G sudo samba && \
#     chown -R samba:root /ad && \ 
#     passwd -d samba
#USER samba

COPY scripts/* ./

#copy CA certificate and script from container
COPY --from=cert /ca/certificate/ca.crt ./
COPY --from=cert /usr/local/bin/create-certificate.sh ./

#to use custom cert:
#copy ca.crt, tls.crt and tls.key to /etc/samba/tls/
#COPY certs/ca.crt /etc/samba/tls/
#COPY certs/adcert.crt /etc/samba/tls/tls.crt
#COPY certs/adcert.key /etc/samba/tls/tls.key
#CMD ["/bin/bash"]
CMD ["bash","samba-ad-run.sh"]
