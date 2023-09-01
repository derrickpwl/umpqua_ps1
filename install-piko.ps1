﻿
function Install-Piko {
    <#
        .SYNOPSIS
            Uninstall software on target machine
        .DESCRIPTION
            Adds an associate to the administrators group on their system.
        .EXAMPLE
            PS> Set-LocalAdmin DerrickPowell UB102123L
        .NOTES
            Group policy should revert this setting after a short amount of time.
    #>

    [CmdletBinding()]
        Param 
        (
            #[Parameter(Mandatory=$True)]
            #[ValidateNotNullOrEmpty()]
            #[String]$ADUser,

            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$Computer
        )

    Begin {}

    Process
 
    {
        #Get-CimInstance -ClassName Win32_Product -ComputerName $Computer | Format-List
        #Get-CimInstance -ClassName Win32_Product -ComputerName $Computer | where name -like "*Encompass*"
        $command = {
            #Get-Package -Name "*Java*" | Uninstall-Package
            #Get-WmiObject Win32_Product | Select Name
            #"C:\Program Files\SASHome\SASDeploymentManager\9.4\sasdm.exe" -uninstall
            #Start-Process "c:\temp\piko-client-5.0.0.35745-windows_x64.exe" #-ArgumentList "/q" #-silent
            Start-Process -FilePath "c:\temp\t99express.exe" -ArgumentList "--quiet" -Verb RunAs -Wait


            #"c:\temp\piko-client-5.0.0.35745-windows_x64.exe"
            #"c:\temp\t99express.exe"
            #Start-Process -Wait -FilePath "c:\temp\piko-client-5.0.0.35745-windows_x64.exe" -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES AgreeToLicense=Yes RebootYesNo=No"
        }
        Invoke-Command -ComputerName $Computer -ScriptBlock $command;

    }

    End {}
 
}

#### ub101593l
### Encompass on: UB087225L