#!/usr/bin/python
# -*- coding: utf-8 -*-
import getpass
import ldb
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

defaultPassword = os.environ["DEFAULT_PASSWORD"]

def sortDictionary(dictionary):
    keyList = list(dictionary.keys())
    keyList.sort()
    # Sorted Dictionary
    return {i: dictionary[i] for i in keyList}

def createUsersAndGroupFromEnv():
    #READ env variable to create groups and users
    #USERS format:
    #GROUPNAME:<USERNAME>,<USERNAME>;GROUPNAME:<USERNAME>;<USERNAME>,<USERNAME>
    #where username is one of: USERNAME, FIRST LAST,USERNAME=PWD,FIRST LAST=PWD
    #if FIRST LAST then username is first letter of first name and last name

    #read environment variables to dictionary and sort them
    environmentVariables = dict()
    for k, v in os.environ.items():
        environmentVariables[k] = v
    environmentVariables = sortDictionary(environmentVariables)
    
    for name, value in environmentVariables.items():
        if name.startswith("USERS"):
            print(f"Creating users from env var {name}...")
            createUsersAndGroup(value)
            print(f"Creating users from env var {name}...done.")
        
def createUsersAndGroup(envVarValue):    
    groups = envVarValue.split(";")
    for group in groups:
        if group.find(":") == -1:
            print(f"WARN: No group specified ({group}). Ignoring.")
            continue
        groupConfig = group.split(":")
        groupName = groupConfig[0]
        try:
            samdb.newgroup(groupname=groupName)
            print(f"Created group: {groupName}")
        except Exception as e:
            print(f"WARN: {e}. Ignoring.")
        users = groupConfig[1].split(",")
        for uid in users:
            uid = uid.strip()
            password = defaultPassword
            #check pwd
            if uid.find("=") > -1:
                uname = uid.split("=")
                uid = uname[0]
                password = uname[1]
            #check first name and last name
            if uid.find(" ") > -1:
                uname = uid.split(" ")
                firstName = uname[0].capitalize()
                lastName = uname[1].capitalize()
                uid = (firstName[0] + lastName).lower()
            else:
                firstName = uid.capitalize()
                lastName = uid.capitalize()
            try:
                samdb.newuser(username=uid,givenname=firstName, surname=lastName,password=password)
                samdb.add_remove_group_members(groupname=groupName, members=[uid], add_members_operation=True)
                print(f"Added user - uid: {uid}, firstName: {firstName}, lastName: {lastName}")
            except Exception as e:
                print(f"WARN: {e}. Ignoring.")
            

# samdb.create_ou('OU=marketing,DC=sirius,DC=com')
# samdb.create_ou('OU=Users,OU=marketing,DC=sirius,DC=com')

# #samdb.newgroup(groupname='Users',groupou='OU=admin')
# samdb.newgroup(groupname='testgroup')

# samdb.newuser(username="tfoster",givenname="Tom", surname="Foster",password='passw0rd')
# samdb.add_remove_group_members(groupname='testgroup', members=['tfoster'], add_members_operation=True)

# samdb.newuser(username="dwells",givenname="Daniella", surname="Wells",password='passw0rd')

# samdb.rename('CN=dwells,CN=Users,DC=sirius,DC=com','CN=dwells,OU=Users,OU=admin,DC=sirius,DC=com')

# #samdb.add_remove_group_members(groupname='admin', members=['dwells'], add_members_operation=True)

# Using the special variable 
# __name__
if __name__=="__main__":
    createUsersAndGroupFromEnv()