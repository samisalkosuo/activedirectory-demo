FROM ubuntu:23.10
 
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install samba krb5-config winbind smbclient iproute2 openssl vim tmux
 
RUN rm /etc/krb5.conf

WORKDIR /ad
COPY scripts/* ./

#environment variables
ENV SAMBA_DOMAIN sirius.com
ENV SAMBA_ADMIN_PASSWORD S4m3aPassw@rd
ENV SAMBA_PRINT_LOG true


#CMD ["/bin/bash"]
CMD ["bash","samba-ad-run.sh"]
