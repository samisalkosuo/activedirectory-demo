#!/usr/bin/python
# -*- coding: utf-8 -*-
import getpass
import ldb
import configparser
import random
import sys, os

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
domain = configuration['domain']
organizationName = configuration['organization']
allowAnonymousBind = configuration['allowAnonymousBind']
printSambaLogs = configuration['printSambaLogs']
adminPassword = configuration['adminPassword']
#default password from configuration if environment variable does not exist
defaultPassword = os.environ.get("DEFAULT_PASSWORD", configuration['defaultPassword'])

#generate groups and users based on config
for sectionName in config.sections():
    if sectionName == "globalsettings":
        continue
    groupName = sectionName
    samdb.newgroup(groupname=groupName)
    groupConfig = config[groupName]
    #create each user
    for user in groupConfig:
        try:
            userName = user.split(" ")
            firstName = userName[0].capitalize()
            lastName = userName[1].capitalize()
            uid = firstName.lower()[0:1] + lastName.lower()
            pwd = groupConfig[user]
            if pwd == None or pwd == "":
                pwd = defaultPassword
            #print("uid: %s, defaultPassword: %s " % (uid,defaultPassword))
            samdb.newuser(username=uid,givenname=firstName, surname=lastName,password=pwd)
            samdb.add_remove_group_members(groupname=groupName, members=[uid], add_members_operation=True)
        except Exception as e:
            print("ERROR when creating user:"+user)
            print(str(e))
            sys.exit(1)

#READ env variable to create groups and users
try:
    #USERS format:
    #GROUPNAME:USERNAME,USERNAME;GROUPNAME:USERNAME;USERNAME,USERNAME
    #TODO: add option to add password to user, add firstname and lastname
    users = os.environ['USERS']
    groups = users.split(";")
    for group in groups:
        if group.find(":") == -1:
            print(f"WARN: No group specified ({group}). Ignoring.")
            continue
        groupConfig = group.split(":")
        groupName = groupConfig[0]
        try:
            samdb.newgroup(groupname=groupName)
        except Exception as e:
            print(f"WARN: {e}. Ignoring.")
        users = groupConfig[1].split(",")
        for uid in users:
            name = uid.capitalize()
            try:
                samdb.newuser(username=uid,givenname=name, surname=name,password=defaultPassword)
            except Exception as e:
                print(f"WARN: {e}. Ignoring.")
            samdb.add_remove_group_members(groupname=groupName, members=[uid], add_members_operation=True)
        
except Exception as e:
    print(e)

# samdb.create_ou('OU=marketing,DC=sirius,DC=com')
# samdb.create_ou('OU=Users,OU=marketing,DC=sirius,DC=com')

# #samdb.newgroup(groupname='Users',groupou='OU=admin')
# samdb.newgroup(groupname='testgroup')

# samdb.newuser(username="tfoster",givenname="Tom", surname="Foster",password='passw0rd')
# samdb.add_remove_group_members(groupname='testgroup', members=['tfoster'], add_members_operation=True)

# samdb.newuser(username="dwells",givenname="Daniella", surname="Wells",password='passw0rd')

# samdb.rename('CN=dwells,CN=Users,DC=sirius,DC=com','CN=dwells,OU=Users,OU=admin,DC=sirius,DC=com')

# #samdb.add_remove_group_members(groupname='admin', members=['dwells'], add_members_operation=True)