param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $NodeName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path
)

configuration FileServerConfig
{

    # Modules must exist on target pull server
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.1.0.0
    Import-DSCResource -ModuleName cNtfsAccessControl -ModuleVersion 1.3.1   
    Import-DscResource -ModuleName xSmbShare -ModuleVersion 2.0.0.0
    Import-DscResource -ModuleName xDFS -ModuleVersion 3.2.0.0
 
    Node $NodeName {
    
        WindowsFeature FileServer {
            Ensure = "Present"
            Name   = "FS-FileServer"
        }

        WindowsFeature DFSNamespace 
        { 
            Ensure = "Present"
            Name = "FS-DFS-Namespace"
        }

        WindowsFeature DFSReplication
        { 
            Ensure = "Present"
            Name = "FS-DFS-Replication"
            DependsOn = '[WindowsFeature]DFSNamespace'

        }

        WindowsFeature RSATDFSMgmtConInstall 
        { 
            Ensure = "Present"
            Name = "RSAT-DFS-Mgmt-Con"
            DependsOn = '[WindowsFeature]DFSNamespace','[WindowsFeature]DFSReplication'
        }


################### SHARED FOLDER ###################

        File SharedFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared'
        }

        cNtfsPermissionsInheritance SharedFolderInheritance {
            Path              = 'D:\Shared'
            Enabled           = $false
            PreserveInherited = $false
        }
        
        cNtfsPermissionEntry SharedFolderPermissionAdministrators {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Administrators_folders'
            Path      = 'D:\Shared'
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance        = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry SharedFolderPermissionUsers {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Пользователи домена'
                Path      = 'D:\Shared'
                ItemType  = 'Directory'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'ReadAndExecute'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

        xSmbShare SharedShare {
                Ensure = "Present"
                Name   = "Shared"
                Path = "D:\Shared" 
                Description = "Shared"         
                FullAccess = "Everyone"
                DependsOn = '[File]SharedFolder'
            }

################### COMMON FOLDER ###################

        File CommnonFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Common'
            DependsOn       = '[File]SharedFolder'
        }

            cNtfsPermissionsInheritance CommnonFolderInheritance {
                Path              = 'D:\Shared\Common'
                Enabled           = $false
                PreserveInherited = $false
            }

            cNtfsPermissionEntry CommnonFolderPermissionAdministrators {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Administrators_folders'
                Path      = 'D:\Shared\Common'
                ItemType  = 'Directory'
                AccessControlInformation = @(

                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'Modify'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

            cNtfsPermissionEntry CommnonFolderPermissionWrite {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Пользователи домена'
                Path      = 'D:\Shared\Common'
                ItemType  = 'Directory'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'Modify'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

################### DOCUMENTS FOLDER ###################

        File DocumentsFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Documents'
            DependsOn       = '[File]SharedFolder'
        }

            cNtfsPermissionsInheritance DocumentsFolderInheritance {
                Path              = 'D:\Shared\Documents'
                Enabled           = $false
                PreserveInherited = $false
            }

            cNtfsPermissionEntry DocumentsFolderPermissionAdministrators {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Administrators_folders'
            Path      = 'D:\Shared\Documents'
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance        = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            }

            cNtfsPermissionEntry DocumentsFolderPermissionWrite {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Shared_Documents_Krupnov_M&A_Write'
                Path      = 'D:\Shared\Documents'
                ItemType  = 'Directory'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'Modify'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

            cNtfsPermissionEntry DocumentsFolderPermissionRead {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Shared_Documents_Krupnov_M&A_Read'
                Path      = 'D:\Shared\Documents'
                ItemType  = 'Directory'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'ReadAndExecute'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

            File KrupnovMAFolder {
                Ensure          = "Present"
                Type            = 'Directory'
                DestinationPath = 'D:\Shared\Documents\Krupnov_M&A'
                DependsOn       = '[File]DocumentsFolder'
            }

################### DOWNLOADS FOLDER ###################

        File DownloadsFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Downloads'
            DependsOn       = '[File]SharedFolder'
        }

            cNtfsPermissionsInheritance DownloadsFolderInheritance {
                Path              = 'D:\Shared\Downloads'
                Enabled           = $false
                PreserveInherited = $false
            }

            cNtfsPermissionEntry DownloadsFolderPermissionAdministrators {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Administrators_folders'
            Path      = 'D:\Shared\Downloads'
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance        = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            }

            cNtfsPermissionEntry DownloadsFolderPermissionWrite {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Shared_Downloads_Write'
                Path      = 'D:\Shared\Downloads'
                ItemType  = 'Directory'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'Modify'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

            cNtfsPermissionEntry DownloadsFolderPermissionRead {
                Ensure    = 'Present'
                Principal = 'krupfamily.net\Shared_Downloads_Read'
                Path      = 'D:\Shared\Downloads'
                ItemType  = 'Directory'
                AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                        AccessControlType  = 'Allow'
                        FileSystemRights   = 'ReadAndExecute'
                        Inheritance        = 'ThisFolderSubfoldersAndFiles'
                        NoPropagateInherit = $false
                    }
                )
            }

            File FromAFSFolder {
                Ensure          = "Present"
                Type            = 'Directory'
                DestinationPath = 'D:\Shared\Downloads\From A-FS1'
                DependsOn       = '[File]DownloadsFolder'
            }

################### EDUCATION FOLDER ###################

        File EducationFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Education'
            DependsOn       = '[File]SharedFolder'
        }

################### Entertainment FOLDER ###################

        File EntertainmentFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Entertainment'
            DependsOn       = '[File]SharedFolder'
        }

################### Exchange FOLDER ###################

        File ExchangeFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Exchange'
            DependsOn       = '[File]SharedFolder'
        }

################### Home FOLDER ###################

        File HomeDirFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Home_dir'
            DependsOn       = '[File]SharedFolder'
        }

################### PHOTO FOLDER ###################

        File PhotoFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Photo'
            DependsOn       = '[File]SharedFolder'
        }

        cNtfsPermissionsInheritance PhotoFolderInheritance {
            Path              = 'D:\Shared\Photo'
            Enabled           = $false
            PreserveInherited = $false
        }

        cNtfsPermissionEntry PhotoFolderPermissionAdministrators {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Administrators_folders'
            Path      = 'D:\Shared\Photo'
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance        = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry PhotoFolderPermissionWrite {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Shared_Home_Photos_Krupnov_M&A_Write'
            Path      = 'D:\Shared\Photo'
            ItemType  = 'Directory'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance        = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry PhotoFolderPermissionRead {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Shared_Home_Photos_Krupnov_M&A_Read'
            Path      = 'D:\Shared\Photo'
            ItemType  = 'Directory'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'ReadAndExecute'
                    Inheritance        = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

################### Software FOLDER ###################

        File SoftwareFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Software'
            DependsOn       = '[File]SharedFolder'
        }

################### SoftwareLocal FOLDER ###################

        File SoftwareLocalFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\Software_local'
            DependsOn       = '[File]SharedFolder'
        }

################### Torrents FOLDER ###################

        File TorrentsFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = 'D:\Shared\TorrentsForDownload'
            DependsOn       = '[File]SharedFolder'
        }

            File TorrentsFinishedFolder {
                Ensure          = "Present"
                Type            = 'Directory'
                DestinationPath = 'D:\Shared\TorrentsForDownload\Finished'
                DependsOn       = '[File]DownloadsFolder'
            }

            File TorrentsTempFolder {
                Ensure          = "Present"
                Type            = 'Directory'
                DestinationPath = 'D:\Shared\TorrentsForDownload\Temp'
                DependsOn       = '[File]DownloadsFolder'
            }

################### Video FOLDER ###################
        
        $VideoFolderPath = "D:\Shared\Video"

        File VideoFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = $VideoFolderPath
            DependsOn       = '[File]SharedFolder'
        }

        cNtfsPermissionsInheritance VideoFolderInheritance {

            Path              = $VideoFolderPath
            Enabled           = $false
            PreserveInherited = $false
        }

        cNtfsPermissionEntry VideoFolderPermissionSystem {
            Ensure    = 'Present'
            Principal = 'System'
            Path      = $VideoFolderPath
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   =  'Full'
                    Inheritance        = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry VideoFolderPermissionAdministrators {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Administrators_folders'
            Path      = $VideoFolderPath
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry VideoFolderPermissionRead {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Пользователи домена'
            Path      = $VideoFolderPath
            ItemType  = 'Directory'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'ReadAndExecute'
                    Inheritance        = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
            )
        }
    }

################### Krupnov_M&A Video FOLDER ###################
        
        $Video_KrupnovMA_FolderPath = "D:\Shared\Video\Krupnov_M&A"

        File VideoFolder {
            Ensure          = "Present"
            Type            = 'Directory'
            DestinationPath = $VideoFolderPath
            DependsOn       = '[File]SharedFolder'
        }

        cNtfsPermissionsInheritance VideoFolderInheritance {

            Path              = $VideoFolderPath
            Enabled           = $false
            PreserveInherited = $false
        }

        cNtfsPermissionEntry VideoFolderPermissionSystem {
            Ensure    = 'Present'
            Principal = 'System'
            Path      = $VideoFolderPath
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   =  'Full'
                    Inheritance        = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry VideoFolderPermissionAdministrators {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\Administrators_folders'
            Path      = $VideoFolderPath
            ItemType  = 'Directory'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'Modify'
                    Inheritance = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry VideoFolderPermissionRead {
            Ensure    = 'Present'
            Principal = 'krupfamily.net\???????????? ??????'
            Path      = $VideoFolderPath
            ItemType  = 'Directory'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType  = 'Allow'
                    FileSystemRights   = 'ReadAndExecute'
                    Inheritance        = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
            )
        }
    }
}

FileServerConfig -OutputPath $path

New-DSCChecksum ($path + $NodeName + ".mof") -FORCE
