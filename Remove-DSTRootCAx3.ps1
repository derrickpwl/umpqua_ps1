
function Remove-DSTRootCAx3 {
    <#
        .SYNOPSIS
            Removes the DST Root CA X3 certificate from a target sytem
        .DESCRIPTION
            Removes the DST Root CA X3 certificate from a target sytem
        .EXAMPLE
            PS> Remove-DSTRootCAx3 UB102123L
        .NOTES
            Removes the DST Root CA X3 certificate from a target sytem
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
            gci cert:LocalMachine -Recurse | where{$_.Thumbprint -eq "DAC9024F54D8F6DF94935FB1732638CA6AD77C13"} | Remove-Item -Force -Verbose
        }
        Invoke-Command -ComputerName $Computer -ScriptBlock $command;
    }

    End {}
 
}
