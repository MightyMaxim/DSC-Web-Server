# Copyright 2018, Maksim Krupnov
#
# Version 1.0
# Run step by step

# Install DSC Server Setup Module
Install-Module xPSDesiredStateConfiguration
# 
Set-ExecutionPolicy Unrestricted


# Setup Variables
$DSCPullServerName ="mcesapdsc1"
$DomainName = "mceinc.net"
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

$ConfigNames = "PullServerConfig"

# Generate Reg key
Invoke-Command -Computername $DSCPullServerName `
               -Credential $DSCPullServerCredentials `
               {(New-Guid).Guid | 
                Out-File "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt" -Append}
# Get Reg key
$DSCPullServerRegKey = Invoke-Command -Computername $DSCPullServerName `
                                      -Credential $DSCPullServerCredentials `
                                      {Get-Content "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"}

# Show RegKey
$DSCPullServerRegKey

# Generate META MOF file
powershell -File ($ScriptFolder + "DSCLCM_HTTPSPull.ps1") -Path $MOFFolder -DSCPullServerName $DSCPullServerName -NodeName $DSCPullServerName -ConfigNames $ConfigNames -Regkey $DSCPullServerRegKey -SecureHTTP 0

# Check result - Show MOF folder
Explorer $MOFFolder

# Send LCM
Set-DSCLocalConfigurationManager -ComputerName $DSCPullServerName -Credential $DSCPullServerCredentials -Path $MOFFolder –Verbose

######################### LCM configuration for any node ##########################

$ServerName = "mcesapad1"
$ConfigNames = "DCServerConfig"

# Get Reg key
$DSCPullServerRegKey = Invoke-Command -Computername $DSCPullServerName `
                                      -Credential $DSCPullServerCredentials `
                                      {Get-Content "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"}

# Show RegKey
$DSCPullServerRegKey

# Generate META MOF file
powershell -File ($ScriptFolder + "DSCLCM_HTTPSPull.ps1") -Path $MOFFolder -DSCPullServerName $DSCPullServerName -NodeName $ServerName -ConfigNames $ConfigNames -Regkey $DSCPullServerRegKey -SecureHTTP 0

# Check result - Show MOF folder
Explorer $MOFFolder

# Send LCM
Set-DSCLocalConfigurationManager -ComputerName $ServerName -Credential $DSCPullServerCredentials -Path $MOFFolder –Verbose

######################### PULL configuration for any server ##########################

$ServerName = "mcesapad1"
$ConfigName = "PullServerConfig"

$DSCPullServerCert = Invoke-Command -Computername $DSCPullServerName `
                                    -Credential $DSCPullServerCredentials `
                                    {Get-Childitem Cert:\LocalMachine\My | 
                                     Where-Object {$_.FriendlyName -like ($DSCPullServerName)} | 
                                     Select-Object -ExpandProperty ThumbPrint}
# Show Cert
$DSCPullServerCert 

# Generate initial PUSH MOF file
powershell -File ($ScriptFolder + "DSC" + $ConfigName + ".ps1") -Path $MOFFolder -NodeName $ConfigName -Cert $DSCPullServerCert

# Check result - Show MOF folder
Explorer $MOFFolder

Copy-Item –Path ($MOFFolder + $ConfigName + ".*") –Destination ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder)

# Check result - Show DSC Server Configurations folder
Explorer ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder)

# Force to UPDATE Server Configuration manualy
Update-DscConfiguration -ComputerName $ServerName -Credential $Credentials -Wait -Verbose   #Check to see if it installs

######################### CHECK LCM and PULL configuration for any server ##########################

$ServerName = "mcesapdsc1"
$Credentials = Get-Credential -Credential "sap\administrator"

$Session = New-CimSession -ComputerName $ServerName -Credential $Credential

Get-DscConfiguration -CimSession $Session

Get-DscLocalConfigurationManager -CimSession $Session

# TO cleanup pull server configuration

Remove-DscConfigurationDocument -Stage Current -CimSession $Session