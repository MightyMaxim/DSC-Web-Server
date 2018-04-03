# Copyright 2018, Maksim Krupnov
#
# Version 1.1
# Run step by step

# Install DSC Server Setup Module
Install-Module xPSDesiredStateConfiguration
# 
Set-ExecutionPolicy Unrestricted


# Set general variables

$DomainName = "mceinc.net"

$DSCPullServerName ="mcesapdsc1"
$DSCPullServerCredentials = Get-Credential -Credential "sap\administrator"

$ScriptFolder = "C:\GitHub\DSC-Web-Server\"
$DSCConfigurationFolder = "c$\Program Files\WindowsPowerShell\DscService\Configuration"
$MOFFolder = "C:\DSC\HTTPS\"

######################### Initial PUSH configuration for PULL server ##########################

# Generate Cert
Invoke-Command -Computername $DSCPullServerName `
               -Credential $DSCPullServerCredentials `
               {New-SelfSignedCertificate -CertStoreLocation 'CERT:\LocalMachine\MY'`
                                          -DnsName ($DSCPullServerName + "." + $DomainName)`
                                          -OutVariable DSCCert}
# Get Cert
$DSCPullServerCert = Invoke-Command -Computername $DSCPullServerName `
                       -Credential $DSCPullServerCredentials `
                       {Get-Childitem Cert:\LocalMachine\My | 
                        Where-Object {$_.FriendlyName -like ($DSCPullServerName)} | 
                        Select-Object -ExpandProperty ThumbPrint}
# Show Cert
$DSCPullServerCert 

# Generate initial PUSH MOF file
powershell -File ($ScriptFolder + "DSCPullServerConfig.ps1") -Path $MOFFolder -NodeName $DSCPullServerName -Cert $DSCPullServerCert

# Check result - Show MOF folder
Explorer $MOFFolder

# Start PUSH
Start-DscConfiguration -Path $MOFFolder -ComputerName $DSCPullServerName -Force -Verbose -Wait

######################### Initial LCM configuration for PULL server ##########################

# Generate Reg key
Invoke-Command -Computername $DSCPullServerName `
               -Credential $DSCPullServerCredentials `
               {(New-Guid).Guid | 
                Out-File "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt" -Append}

######################### LCM configuration for any node ##########################

$LCMServerName = "mcesapad2"
$LCMConfigNames = "DCServerConfig"

# Get Reg key
$DSCPullServerRegKey = Invoke-Command -Computername $DSCPullServerName `
                                      -Credential $DSCPullServerCredentials `
                                      {Get-Content "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"}
# Show RegKey
$DSCPullServerRegKey

# Generate META MOF file
powershell -File ($ScriptFolder + "DSCLCM_HTTPSPull.ps1") -Path $MOFFolder -DSCPullServerName $DSCPullServerName -NodeName $LCMServerName -ConfigNames $LCMConfigNames -Regkey $DSCPullServerRegKey -SecureHTTP 0

# Check result - Show MOF folder
Explorer $MOFFolder

# Send LCM
Set-DSCLocalConfigurationManager -ComputerName $LCMServerName -Credential $DSCPullServerCredentials -Path $MOFFolder –Verbose

######################### PULL configuration for any server ##########################

$PullConfigName = "PullServerConfig"
$DCConfigName   = "DCServerConfig"

$DSCPullServerCert = Invoke-Command -Computername $DSCPullServerName `
                                    -Credential $DSCPullServerCredentials `
                                    {Get-Childitem Cert:\LocalMachine\My | 
                                     Where-Object {$_.FriendlyName -like ($DSCPullServerName)} | 
                                     Select-Object -ExpandProperty ThumbPrint}
# Show Cert
$DSCPullServerCert 

New-PSDrive -Name "T" -PSProvider "FileSystem" -Root ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder) -Credential $DSCPullServerCredential

# Generate PULLConfig MOF file
powershell -File ($ScriptFolder + "DSC" + $PullConfigName + ".ps1") -Path $MOFFolder -NodeName $PullConfigName -Cert $DSCPullServerCert
Copy-Item –Path ($MOFFolder + $PullConfigName + ".*") –Destination ("T:\")

# Generate DCConfig MOF file
powershell -File ($ScriptFolder + "DSC" + $DCConfigName + ".ps1") -Path $MOFFolder -NodeName $DCConfigName 
Copy-Item –Path ($MOFFolder + $DCConfigName + ".*") –Destination ("T:\")

# Check result - Show MOF folder
dir t:\

Copy-Item –Path ($MOFFolder + $ConfigName + ".*") –Destination ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder)

# Check result - Show DSC Server Configurations folder
Explorer ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder)

# Force to UPDATE Server Configuration manualy

$UpdateServerName = "mcesapad2"
$UpdateServerCredentials = Get-Credential "sap\administrator"

Update-DscConfiguration -ComputerName $UpdateServerName -Credential $UpdateServerCredentials -Wait -Verbose   #Check to see if it installs

######################### CHECK LCM and PULL configuration for any server ##########################

$TestServerName = "mcesapad2"
$TestServerCredentials = Get-Credential -Credential "sap\administrator"

$Session = New-CimSession -ComputerName $TestServerName -Credential $TestServerCredentials

Get-DscConfiguration -CimSession $Session

Get-DscLocalConfigurationManager -CimSession $Session

# TO cleanup pull server configuration

Remove-DscConfigurationDocument -Stage Current -CimSession $Session

Invoke-Command -Computername $TestServerName -Credential $TestServerCredentials {Get-WindowsFeature | Format-Table}