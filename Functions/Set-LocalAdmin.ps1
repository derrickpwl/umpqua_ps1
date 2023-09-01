
function Set-LocalAdmin {
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
            [String]$User,

            [Parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$Computer
        )

    Begin {}

    Process
 
    {
        $command = {
             Add-LocalGroupMember -Group Administrators -Member $using:User
        }
        Invoke-Command -ComputerName $Computer -ScriptBlock $command;
    }

    End {}
 
}