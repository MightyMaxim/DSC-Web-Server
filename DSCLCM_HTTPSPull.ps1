# Copyright 2018, Maksim Krupnov
#
# Version 1.1
# 

param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SecureHTTP,

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

if ($SecureHTTP -eq "1") {
    $DSCServerURL = "https://" + $DSCPullServerName + ":8080/PSDSCPullServer.svc"
    $AllowUnsecure = $false
} else {
    $DSCServerURL = "http://" + $DSCPullServerName + ":8080/PSDSCPullServer.svc"
    $AllowUnsecure = $true
}

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
            ServerURL = $DSCServerURL
            RegistrationKey = $RegKey
            ConfigurationNames = $ConfigNames 
            AllowUnsecureConnection = $AllowUnsecure
        }

        ResourceRepositoryWeb PullServerModules {
            ServerURL = $DSCServerURL
            RegistrationKey = $RegKey
            AllowUnsecureConnection = $AllowUnsecure
        }
	}
}

# Generate Meta.Mof in folder
LCM_HTTPSPULL -OutputPath $Path