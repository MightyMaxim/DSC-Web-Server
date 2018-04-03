# Copyright 2018, Maksim Krupnov
#
# Version 1.0
# 

param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Cert,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $NodeName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path

)

configuration PullServerConfig
{
    # Modules must exist on target pull server
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $NodeName {
        
        WindowsFeature DSCServiceFeature {
            Ensure = "Present"
            Name   = "DSC-Service"
        }
# Only for GUI
#        WindowsFeature IISConsole {
#            Ensure = "Present"
#            Name   = "Web-Mgmt-Console"
#        }

        xDscWebService PSDSCPullServer {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint   = $Cert
#for HTTP   CertificateThumbPrint   = "AllowUnencryptedTraffic"
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            RegistrationKeyPath     = "$env:PROGRAMFILES\WindowsPowerShell\DscService"   
            AcceptSelfSignedCertificates = $true  
#for HTTP   AcceptSelfSignedCertificates = $false
            State                   = "Started"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
            UseSecurityBestPractices = $true
#for HTTP   UseSecurityBestPractices = $false
        }

        File RegistrationKeyFile {
        Ensure          = 'Present'
        Type            = 'File'
        DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
        }
    }
}


PullServerConfig -OutputPath $path

New-DSCChecksum ($path + $NodeName + '.mof') -FORCE


