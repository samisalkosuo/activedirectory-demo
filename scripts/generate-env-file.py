import configparser
import os

#read config
config = configparser.ConfigParser(strict=False)
config.read('config.ini')

#read global settings
configuration=config['globalsettings']

adminPassword = configuration['adminPassword']
domain = configuration['domain']
printSambaLogs = configuration['printSambaLogs']
allowAnonymousBind = configuration['allowAnonymousBind']

#set environment variables, if not available
f = open("config.env", "w")
envName="SAMBA_DOMAIN"
if  os.getenv(envName) == None:
    f.write(f"export {envName}={domain}\n")
envName="SAMBA_ADMIN_PASSWORD"
if  os.getenv(envName) == None:
    f.write(f"export {envName}={adminPassword}\n")
envName="SAMBA_PRINT_LOG"
if  os.getenv(envName) == None:
    f.write(f"export {envName}={printSambaLogs}\n")
envName="SAMBA_ALLOW_ANONYMOUS_BIND"
if  os.getenv(envName) == None:
    f.write(f"export {envName}={allowAnonymousBind}\n")
f.close()
