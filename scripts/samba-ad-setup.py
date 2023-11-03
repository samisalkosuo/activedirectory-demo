#!/usr/bin/python
# -*- coding: utf-8 -*-
import getpass
import ldb
import configparser
import random


from samba.auth import system_session
from samba.credentials import Credentials
from samba.dcerpc import security
from samba.dcerpc.security import dom_sid
from samba.ndr import ndr_pack, ndr_unpack
from samba.param import LoadParm
from samba.samdb import SamDB

lp = LoadParm()
creds = Credentials()
creds.guess(lp)
samdb = SamDB(url='/var/lib/samba/private/sam.ldb', session_info=system_session(),credentials=creds, lp=lp)


#read config
config = configparser.ConfigParser(strict=False)
config.read('config.ini')

#read global settings
configuration=config['globalsettings']

defaultPassword = configuration['defaultPassword']
adminPassword = configuration['adminPassword']
domain = configuration['domain']
organizationName = configuration['organization']
allowAnonymousBind = configuration['allowAnonymousBind']

#TODO: set env variables from above, like SAMBA_DOMAIN etc (see Dockerfile)
#add generate certificate to config.ini like CERT_DOMAIN, CERT_SERVER, if not available use default self signed?
#generate groups and users based on config


#groups: admin,research,operations,marketing
#same users as in openldap

#a
samdb.create_ou('OU=admin,DC=sirius,DC=com')
samdb.create_ou('OU=Users,OU=admin,DC=sirius,DC=com')

samdb.create_ou('OU=research,DC=sirius,DC=com')
samdb.create_ou('OU=Users,OU=research,DC=sirius,DC=com')

samdb.create_ou('OU=operations,DC=sirius,DC=com')
samdb.create_ou('OU=Users,OU=operations,DC=sirius,DC=com')

samdb.create_ou('OU=marketing,DC=sirius,DC=com')
samdb.create_ou('OU=Users,OU=marketing,DC=sirius,DC=com')

#samdb.newgroup(groupname='Users',groupou='OU=admin')
samdb.newgroup(groupname='testgroup')
# samdb.newgroup(groupname='operations')
# samdb.newgroup(groupname='marketing')

samdb.newuser(username="tfoster",givenname="Tom", surname="Foster",password='passw0rd')
samdb.add_remove_group_members(groupname='testgroup', members=['tfoster'], add_members_operation=True)

samdb.newuser(username="dwells",givenname="Daniella", surname="Wells",password='passw0rd')

samdb.rename('CN=dwells,CN=Users,DC=sirius,DC=com','CN=dwells,OU=Users,OU=admin,DC=sirius,DC=com')

#samdb.add_remove_group_members(groupname='admin', members=['dwells'], add_members_operation=True)