
function Install-Msi {

<#
    .SYNOPSIS
        Installs .MSI files on remote computers
    .DESCRIPTION
        Function will install an MSI on a remote computer. The file cannot be hosted outside the target system and must be an MSI file.
    .PARAMETER Computer
        Specifies the remote computer
    .INPUTS
        System.String.
    .OUTPUTS
        System.Array. Get-MappedDrives returns an array of PSCustomObjects
    .NOTES
        Version:         1.0
        Author:          Derrick Powell
        Creation Date:   12/13/19
    .EXAMPLE
        PS> Install-Msi UB102123L

        ReturnValue ComputerName FilePath                                                     
        ----------- ------------ --------                                                     
                  0 UB102123L    \\UB102123L\c$\Windows\ccmcache\6p\PrinterInstallerClient.msi
#>

    [CmdletBinding()]
    Param (
        # Computer name
        [parameter(ValueFromPipeline=$True, Mandatory=$True)]
        [string]$ComputerName)

    Begin {
        ## Initialize CIM Session
        $mySession = New-CimSession -ComputerName $ComputerName
    }

    Process{

        $fileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = %{"\\$ComputerName\c$\"}; Filter = “All files (*.*)| *.*” }
        $fileBrowser.ShowDialog() | Out-Null

        if ($fileBrowser.FileName){
            $results = Invoke-CimMethod -CimSession $mySession -ClassName Win32_Product -MethodName Install -Arguments @{PackageLocation=$fileBrowser.FileName}
        }

        # non-interactive for .exe files... probably won't work
        # Invoke-CimMethod -CimSession $mySession -ClassName Win32_Process -MethodName "Create" -Arguments @{ CommandLine = $fileBrowser.FileName}
        
        [pscustomobject]@{
            ReturnValue = $results.ReturnValue
            ComputerName = $ComputerName
            FilePath = $fileBrowser.FileName
        }

    }

    End {
        ## Cleanup CIM Session
        Remove-CimSession $mySession
    }
}
