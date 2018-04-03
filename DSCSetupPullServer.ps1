# Copyright 2018, Maksim Krupnov
#
# Version 1.0
# Run step by step

# Install DSC Server Setup Module
Install-Module xPSDesiredStateConfiguration
# 
Set-ExecutionPolicy Unrestricted


# Setup Variables
$ServerName = "**"
$DSCPullServerName ="**"
$DomainName = "**"
$Credentials = Get-Credential -Credential "**"
$ScriptFolder = "C:\GitHub\DSCServer\DSC-Web-Server\"
$DSCConfigurationFolder = "c$\Program Files\WindowsPowerShell\DscService\Configuration"
$MOFFolder = "C:\DSC\HTTPS\"

######################### Initial PUSH configuration for pull server ##########################

# Generate Cert
Invoke-Command -Computername $DSCPullServerName -Credential $Credentials {New-SelfSignedCertificate -CertStoreLocation 'CERT:\LocalMachine\MY' -DnsName ($DSCPullServerName + "." + $DomainName) -OutVariable DSCCert}
# Get Cert
$Cert = Invoke-Command -Computername $DSCPullServerName -Credential $Credentials {Get-Childitem Cert:\LocalMachine\My | 
                                                                                  Where-Object {$_.FriendlyName -like ($DSCPullServerName)} | 
                                                                                  Select-Object -ExpandProperty ThumbPrint}
# Show Cert
$Cert 

# Generate initial PUSH MOF file
powershell -File ($ScriptFolder + "DSCPullServerConfig.ps1") -Path $MOFFolder -NodeName $DSCPullServerName -Cert $Cert

# Check result - Show MOF folder
Explorer $MOFFolder

# Start PUSH
Start-DscConfiguration -Path $MOFFolder -ComputerName $DSCPullServerName -Force -Verbose -Wait

######################### LCM configuration for any server ##########################

$ServerName = "***"
$ConfigNames = "PullServerConfig"

# Generate Reg key
Invoke-Command -Computername $DSCPullServerName -Credential $Credentials {(New-Guid).Guid | Out-File "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt" -Append}
# Get Reg key
$RegKey = Invoke-Command -Computername $DSCPullServerName -Credential $Credentials {Get-Content "$Env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"}

# Show RegKey
$RegKey

# Generate META MOF file
powershell -File ($ScriptFolder + "DSCLCM_HTTPSPull.ps1") -Path $MOFFolder -DSCPullServerName $DSCPullServerName -NodeName $ServerName -ConfigNames $ConfigNames -Regkey $RegKey

# Check result - Show MOF folder
Explorer $MOFFolder

# Send LCM
Set-DSCLocalConfigurationManager -ComputerName $DSCPullServerName -Path $MOFFolder –Verbose

######################### PULL configuration for any server ##########################

$ServerName = "***"
$ConfigName = "PullServerConfig"

$Cert = Invoke-Command -Computername $DSCPullServerName -Credential $Credentials {Get-Childitem Cert:\LocalMachine\My | 
                                                                                  Where-Object {$_.FriendlyName -like ($DSCPullServerName)} | 
                                                                                  Select-Object -ExpandProperty ThumbPrint}
# Show Cert
$Cert 

# Generate initial PUSH MOF file
powershell -File ($ScriptFolder + "DSC" + $ConfigName + ".ps1") -Path $MOFFolder -NodeName $ConfigName -Cert $Cert

# Check result - Show MOF folder
Explorer $MOFFolder

Copy-Item –Path ($MOFFolder + $ConfigName + ".*") –Destination ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder)

# Check result - Show DSC Server Configurations folder
Explorer ("\\" + $DSCPullServerName + "\" + $DSCConfigurationFolder)

# Force to UPDATE Server Configuration manualy
Update-DscConfiguration -ComputerName $ServerName -Wait -Verbose   #Check to see if it installs


