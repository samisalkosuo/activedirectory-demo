FROM kazhar/certificate-authority AS cert

FROM ubuntu:25.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install samba samba-ad-provision samba-dsdb-modules krb5-config winbind smbclient iproute2 openssl vim tmux && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install samba* && \
    rm /etc/krb5.conf
WORKDIR /ad

#environment variables
ENV SAMBA_DOMAIN=sirius.com
ENV SAMBA_ADMIN_PASSWORD=STRONGpassw0rd
ENV SAMBA_PRINT_LOG=false
ENV SAMBA_ALLOW_ANONYMOUS_BIND=false
ENV DEFAULT_PASSWORD=passw0rd

#users given as env variables
#format:
#GROUPNAME:<USERNAME>,<USERNAME>;GROUPNAME:<USERNAME>;<USERNAME>,<USERNAME>
#where username is one of: USERNAME, FIRST LAST,USERNAME=PWD,FIRST LAST=PWD
#if FIRST LAST then username is first letter of first name and last name
ENV USERS___ADMIN="admin:Kiara Doyle,Zac Fraser,Andre Shaw,Daniella Wells"
ENV USERS___RESEARCH="research:Olivia Berry,Oscar Davis,Amelia Lawson,Jonah Stone"
ENV USERS___OPERATIONS="operations:Tom Foster,Cara Hawkins,Natalia Matthews,George Watts"
ENV USERS___MARKETING="marketing:Hilary Banks=hilarybanks,Mallory Keaton=mallkeat,Ed Norton=pw8chars,Michael Scott"
ENV USERS___TEST="testers:tester1=tester1,tester2,tester3"

COPY scripts/* ./

#copy CA certificate and script from cert container
COPY --from=cert /ca/certificate/ca.crt ./
COPY --from=cert /usr/local/bin/create-certificate.sh ./

#to use custom cert:
#copy ca.crt, tls.crt and tls.key to /etc/samba/tls/
#COPY certs/ca.crt /etc/samba/tls/
#COPY certs/adcert.crt /etc/samba/tls/tls.crt
#COPY certs/adcert.key /etc/samba/tls/tls.key

#CMD ["/bin/bash"]
CMD ["bash","samba-ad-run.sh"]
