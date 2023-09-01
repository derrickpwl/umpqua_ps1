
function Configure-RightFax {
    <#
        .SYNOPSIS
            Repair's RightFax configuration settings 
        .DESCRIPTION
            Configures the associate's computer registry so that RightFax client will connect to the correct server
        .EXAMPLE
            PS> Configure-RightFax UB102123L
        .NOTES
            Will set registry settings for all users
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
             #Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\RightFax Client\PrintDriver\' | select Name
             #Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\RightFax Client\PrintDriver\' -Name "Name" -Value "rightfax.umpq.umpquabank.com"

            # Regex pattern for SIDs
            $PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
            # Get Username, SID, and location of ntuser.dat for all users
            $ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} | 
                Select  @{name="SID";expression={$_.PSChildName}}, 
                        @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                        @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
 
            # Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
            $LoadedHives = gci Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select @{name="SID";expression={$_.PSChildName}}
 
            # Get all users that are not currently logged
            $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select @{name="SID";expression={$_.InputObject}}, UserHive, Username
 
            # Loop through each profile on the machine
            Foreach ($item in $ProfileList) {
                # Load User ntuser.dat if it's not already loaded
                IF ($item.SID -in $UnloadedHives.SID) {
                    reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
                }

            #####################################################################
            # This is where you can read/modify a users portion of the registry 

            #Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\RightFax Client\PrintDriver\' | select Name
            
            <#
            try{
            "{0}" -f $($item.Username) | Write-Output
            Get-ItemProperty "registry::HKEY_USERS\$($Item.SID)\SOFTWARE\RightFAX Client\PrintDriver" -ErrorAction Stop | select name| Write-Output
            }
            catch [System.Management.Automation.ItemNotFoundException] {
                #"{0}" -f $($item.Username) | Write-Output
                "REG NOT FOUND" | Write-Output
            }
            #>


            try{
            $username = "{0}" -f $($item.Username)
            $value = Get-ItemProperty "registry::HKEY_USERS\$($Item.SID)\SOFTWARE\RightFAX Client\PrintDriver" -ErrorAction Stop | select name
            #Set-ItemProperty "registry::HKEY_USERS\$($Item.SID)\SOFTWARE\RightFAX Client\PrintDriver" -Value  
            Write-Output ($username + ": " + $value.name)

            }
            catch [System.Management.Automation.ItemNotFoundException] {
                Write-Host ($username + ": NOT FOUND ")
            }


            <# DO NOT USE THIS CODE, just an example
            "{0}" -f $($item.Username) | Write-Output
            Get-ItemProperty registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                Foreach {"{0} {1}" -f "   Program:", $($_.DisplayName) | Write-Output}
            Get-ItemProperty registry::HKEY_USERS\$($Item.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                Foreach {"{0} {1}" -f "   Program:", $($_.DisplayName) | Write-Output}
             #>   
    
            #####################################################################
 
            # Unload ntuser.dat        
            IF ($item.SID -in $UnloadedHives.SID) {
                ### Garbage collection and closing of ntuser.dat ###
                [gc]::Collect()
                reg unload HKU\$($Item.SID) | Out-Null
            }
            }

        }


        Invoke-Command -ComputerName $Computer -ScriptBlock $command;
    }

    End {}
 
}
