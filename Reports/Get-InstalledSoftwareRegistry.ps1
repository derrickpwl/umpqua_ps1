
function Get-InstalledSoftwareRegistry {
    <#
        .SYNOPSIS
            Lists installed software found in registry.
        .DESCRIPTION
            Queries registry locations for installed 32 and 64 bit software.
        .EXAMPLE
            PS> Get-InstalledSoftwareRegistry UB102123L | Out-GridView
        .NOTES
            There is no gurantee that something found in the registry is in fact installed and not every installed application will record itself. 
            For a more complete lookup, WMI may be needed.
    #>

    [CmdletBinding()]
        Param (
            # Computer name
            [parameter(ValueFromPipeline=$True)]
            [string]$Computer)

    Begin {}

    Process {
        # Gather 32 bit applications
        $Data = Invoke-Command -cn $Computer -ScriptBlock {
            Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
            # Filter out KBs and blank entries with Regex
            where {$_.name -notmatch '(\.)?KB\d+'} -pv p |
            where {$_.displayname -notmatch "KB\d{5,}"} |
            where {($_.name, $_.displayname -notmatch "^$")} |
            Select @{Name="Path";Expression={$p.name}},Displayname,DisplayVersion,Publisher,InstallDate,InstallLocation,Comments,UninstallString
        }

        # Gather 64 bit applications
        $Data += Invoke-Command -cn $Computer -ScriptBlock {
            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
            # Filter out KBs and blank entries with Regex
            where {$_.name -notmatch '(\.)?KB\d+'}  -pv p |
            Where {$_.displayname -notmatch "KB\d{5,}"} |
            where {($_.name, $_.displayname -notmatch "^$")} |
            Select @{Name="Path";Expression={$p.name}},Displayname,DisplayVersion,Publisher,InstallDate,InstallLocation,Comments,UninstallString
        }

        # Output final data
        $Data | Sort-Object DisplayName | Select Displayname,DisplayVersion,Publisher,InstallDate,InstallLocation,Comments,UninstallString
    }

    End{}
}


#####################################################

function GISR {
    [CmdletBinding()]
        Param (
            # Computer name
            [parameter(ValueFromPipeline=$True)]
            [string]$Computer)
    Begin {}

    Process {
        Get-InstalledSoftwareRegistry $Computer | ogv -Title "Installed Software: $computer"
    }
    End{}
}

