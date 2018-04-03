# Copyright 2018, Maksim Krupnov
#
# Version 1.0
# 

param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $RegKey,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $DSCPullServerName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $NodeName,  

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [array]  $ConfigNames
)

[DSCLocalConfigurationManager()]

Configuration LCM_HTTPSPULL 
{
	Node $NodeName {
	
		Settings {
        
        	AllowModuleOverwrite = $True
            ConfigurationMode = 'ApplyAndAutoCorrect'
			RefreshMode = 'Pull'

        }
 
        ConfigurationRepositoryWeb PullServer {
            ServerURL = "https://" + $DSCPullServerName + ":8080/PSDSCPullServer.svc"
#for HTTP   ServerURL = "http://" + $DSCPullServerName + ":8080/PSDSCPullServer.svc"
            RegistrationKey = $RegKey
            ConfigurationNames = $ConfigNames 
            AllowUnsecureConnection = $false
#for HTTP   AllowUnsecureConnection = $true
        }

        ResourceRepositoryWeb PullServerModules {
            ServerURL = "https://" + $DSCPullServerName + ":8080/PSDSCPullServer.svc"
#for HTTP   ServerURL = "http://" + $DSCPullServerName + ":8080/PSDSCPullServer.svc"
            RegistrationKey = $RegKey
            AllowUnsecureConnection = $false
#for HTTP   AllowUnsecureConnection = $true
        }
	}
}

# Generate Meta.Mof in folder
LCM_HTTPSPULL -OutputPath $Path