function Restart-Bomgar{

<#
    .SYNOPSIS
        Restarts the Bomgar service on the remote computer
    .DESCRIPTION
        Restarts the Bomgar service on the remote computer
    .PARAMETER Computer
        Specifies the remote computer
    .INPUTS
        System.String.
    .OUTPUTS
        System.Array. Restart-Bomgar returns an array of PSCustomObjects with stop and start codes
    .NOTES
        Version:         1.0
        Author:          Derrick Powell
        Creation Date:   12/12/19
    .EXAMPLE
        PS> Restart-Bomgar ub102123l

        StopCode StartCode
        -------- ---------
               0         0    
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
        
        $bomgar = Get-CimInstance -CimSession $mySession -ClassName win32_service -Filter "Name like '%bomgar-ps%'"

        ## Return this custom object
        [pscustomobject]@{
            StopCode = (Invoke-CimMethod $bomgar -MethodName StopService).ReturnValue
            StartCode = (Invoke-CimMethod $bomgar -MethodName StartService).ReturnValue
            }
        }

    End {
        ## Cleanup CIM Session
        Remove-CimSession $mySession
        }
}
