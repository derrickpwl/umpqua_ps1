
function Uninstall-Encompass {
    <#
        .SYNOPSIS
            Set's a user as a local admin 
        .DESCRIPTION
            Adds an associate to the administrators group on their system.
        .EXAMPLE
            PS> Set-LocalAdmin DerrickPowell UB102123L
        .NOTES
            Group policy should revert this setting after a few minutes.
    #>

    [CmdletBinding()]
        Param 
        (
            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$Computer
        )

    Begin {}

    Process
 
    {
        $command = {

            # Full path of the file
            $file = "C:\Temp\Encompass Uninstall.exe"

            #If the file does not exist, copy it
            if (-not(Test-Path -Path $file -PathType Leaf)) {
                try {
                    Write-Host "Copying uninstaller file to system..."
                    #$from = "\\umpquanet.local\share\DeptShared\ClientEngineering\AppDropBox\Encompass\Encompass Uninstaller\Encompass Uninstall.exe"
                    #Copy-Item -Path $from -Destination C:\Temp
                }
                catch {
                    throw $_.Exception.Message
                }
            }

            Start-Process -FilePath $file -ArgumentList ‘/s’ -PassThru

        }
        Invoke-Command -ComputerName $Computer -ScriptBlock $command;
    }

    End {}
 
}
