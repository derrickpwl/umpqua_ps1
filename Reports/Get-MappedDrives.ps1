function Get-MappedDrives{
<#
    .SYNOPSIS
        Lists mapped drives for the current logged in user
    .DESCRIPTION
        Function looks at the mapped network drives for the current logged in user on a remote computer. 
        Mapped drive information is pulled directly from the registry (HKLM) based on that user's SID.
    .PARAMETER Computer
        Specifies the remote computer
    .INPUTS
        System.String.
    .OUTPUTS
        System.Array. Get-MappedDrives returns an array of PSCustomObjects
    .NOTES
        Version:         1.0
        Author:          Derrick Powell
        Creation Date:   12/10/19
    .EXAMPLE
        PS> Get-MappedDrives UB102123L

        DriveLetter RemotePath                                    
        ----------- ----------                                    
        P           \\umpqua3.umpquanet.local\Shared              
        U           \\umpq.umpquabank.com\share\USER\DerrickPowell
#>

    [CmdletBinding()]
    Param (
        # Computer name
        [parameter(ValueFromPipeline=$True)]
        [string]$Computer)

    Begin {}

    Process{

        # Get current logged on user's SID
        $sid = Get-CimInstance -ComputerName $Computer -ClassName 'Win32_ComputerSystem' | 
            select -ExpandProperty username | % {$_ -replace '^(.*[\\])'} | Get-Aduser | select sid | % {$_.sid.value}
        
        # Check HKLM in registry for SID and get mapped drive information
        $key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', $Computer) | % {$_.OpenSubKey("$sid\Network", $True)}
        foreach ($drive in $key.GetSubKeyNames()){
            [pscustomobject]@{
                DriveLetter = $drive.ToUpper()
                RemotePath = $drive | % {$key.OpenSubKey($_,$True)} | % {$_.GetValue('RemotePath')}
            }
        }
    }

    End {}
}
