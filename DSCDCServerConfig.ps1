# Copyright 2018, Maksim Krupnov
#
# Version 1.0
# 

param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $NodeName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path

)

configuration DCServerConfig
{
    # Modules must exist on target pull server
 #   Import-DSCResource -ModuleName xActiveDirectory

    Node $NodeName {
        
        File ADFiles            
        {            
            DestinationPath = 'C:\NTDS'            
            Type = 'Directory'            
            Ensure = 'Present'            
        }            
                    
        WindowsFeature ADDSInstall             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"             
        }            
            
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }            
    }
}


DCServerConfig -OutputPath $path

New-DSCChecksum ($path + $NodeName + '.mof') -FORCE