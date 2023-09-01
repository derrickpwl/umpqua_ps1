#Title:		Account-Status
#Author:	Derrick Powell, edit: Joey Civin
#Version:	Version 1.3
#Purpose:	Returns status of Active Directory accounts on UMPQ domain
#Created:	20161220, edit: 20180913
#
#
#9/13/2018 edit (Joey Civin): Testing workflow for parallel DC unlock, added DisplayName/EmailAddress, removed SIP, cleaned up display for lockout/expiration if false
#----------------------------------------------------------------------------

###################### Alias Declaration ##################################################

New-Item alias:a-s -value Account-Status -ErrorAction SilentlyContinue | out-null

###################### Object Declaration #################################################

### Import active directory modules ###
import-module activedirectory

### Get all domain controllers ###
$dcs = get-ADGroupMember 'Domain Controllers'

### Declare $newuser array
$newuser = @(0)

### Set object output
$myobj = "" | Select-Object SamAccountName, DistinguishedName, LockedOut, Enabled, PasswordExpired, PasswordLastSet, `
                            BadLogonCount, BadPwdCount, City, TelephoneNumber, Description, Manager, extensionAttribute2, `
                            extensionAttribute12,extensionAttribute15, Office, DisplayName, EmailAddress

###################### Account-Status #####################################################
workflow accountUnlockWorkflow {
    param(
        [string[]] $dcs,
        [string] $selectedUser
    )

    function accountUnlock([string] $dc, [string] $selectedUser){
        unlock-adaccount $selectedUser -server $dc.name
        InlineScript {write-host "unlocked on:" $dc.name}
    }
    
    foreach -parallel ($dc in $dcs) { accountUnlock $dc $selectedUser}
}
function Account-Status([string]$user)
{
<#
.SYNOPSIS
Returns status of Active Directory accounts on UMPQ domain

.DESCRIPTION
Returns status of Active Directory accounts on UMPQ domain. Function performs the following:
* Reports basic account information
* Displays warnings if accounts are locked, disabled, or expired. 
* Prompts to unlock accounts across all dc's if applicable

.PARAMETER u
Account-Status accepts string "u". 
The parameter should either match the login name or be similar to the userprincipalname in AD. 
Userprinipalname is used to more easily search classic sterling users
(See example below)
 
.EXAMPLE
Account-Status derrickpowell 
Retrieves AD information for single user, derrickpowell

.EXAMPLE
Account-Status derrickpow
Retrieves AD information for users, derrickpowell and derrickpowell.adm

.EXAMPLE
Account-Status justinward
Retrieves AD information for users, JUward and JustinWard.ADM
#>


### End Script if string is empty else search will happen across entire OU
if ([string]::IsNullOrWhiteSpace($user)) {write-warning "Given string is NULL or having WHITESPACE";return}

### Get User Information ###

# Check if name matches exactly
Try{
$newuser[0] = get-aduser $user -Properties "*"
    }

# If name is wrong, pull from UserPrincipleName e.g. derrickpowell@umpquabank.com
Catch {
$v = "*" + $user + "*"
$tempuser = get-aduser `
    -filter {UserPrincipalName -like $v} -Properties "*"

# Ensure that $newuser is an array
if ($tempuser -isnot [system.array]) {$newuser[0] = $tempuser}
else {$newuser = $tempuser}

    }

# Exit Program if no user found
if (!$newuser) { 
    Write-Host "No User Found"
    return
    }

### Write Information ###

# Cycle through each user in $newuser array
$i = 0
foreach($counter in $newuser){

    ### PREPARE LIST FOR OUTPUT ###
    # AD Info ------------    
    $myobj.SamAccountName = $newuser[$i].SamAccountName
    $myobj.DistinguishedName = $newuser[$i].DistinguishedName

    $myobj.extensionAttribute2 = $newuser[$i].extensionAttribute2 # (Employee ID)
    $myobj.extensionAttribute12 = $newuser[$i].extensionAttribute12 # (Cost Center)
    $myobj.extensionAttribute15 = $newuser[$i].extensionAttribute15 # (FIS Login)

    $myobj.DisplayName = $newuser[$i].DisplayName # (Associate name)
    $myobj.EmailAddress = $newuser[$i].EmailAddress


    <# SIP Address
    try{
    $tempSIP = $myobj.DistinguishedName
    if($tempSIP.Contains("OU=STERLING")){$tempserver='Sterlingsavings'}
    if($tempSIP.Contains("OU=UMPQUANET")){$tempserver='Umpquanet'}
    $userSIP = Get-ADUser $myobj.SamAccountName -server $tempserver -properties "msRTCSIP-PrimaryUserAddress"
    $SIP = $userSIP.'msRTCSIP-PrimaryUserAddress'
    }
    catch{$SIP = ""} 
    #>

    $myobj.telephonenumber = $newuser[$i].telephonenumber
    $myobj.city = $newuser[$i].city
    $myobj.office = $newuser[$i].office
    $myobj.manager = $newuser[$i].Manager
        # Parse Manager name
        if ($myobj.Manager){$myobj.Manager = $myobj.Manager.substring(3);$myobj.Manager = $myobj.Manager.split(",")[0]}
    $myobj.Description = $newuser[$i].description

    # Account Status ------------
    $myobj.enabled = $newuser[$i].enabled
    $myobj.lockedout = $newuser[$i].lockedout
    $myobj.passwordexpired = $newuser[$i].passwordexpired
    $myobj.passwordlastset = $newuser[$i].passwordlastset
    $myobj.BadLogonCount = $newuser[$i].BadLogonCount
    $myobj.badPwdCount = $newuser[$i].badPwdCount

    ### WRITE LIST TO HOST ###
    $pad = 20

    Write-Host ""
    funline("-- $($myobj.SamAccountName) --------------------")

    write-host (“Employee ID: ”).padright($pad) -NoNewline
    write-host $myobj.extensionAttribute2 -fore Cyan
    write-host (“Employee Name: ”).padright($pad) -NoNewline
    write-host $myobj.DisplayName -fore Cyan
    write-host (“Email Address: ”).padright($pad) -NoNewline
    write-host $myobj.EmailAddress -fore Cyan
    write-host (“FIS Login: ”).padright($pad) -NoNewline
    write-host $myobj.extensionAttribute15 -fore Cyan
    <#
    write-host (“SIP Address: ”).padright($pad) -NoNewline
    write-host $SIP -fore green
    #>
    write-host (“TelephoneNumber: ”).padright($pad) -NoNewline
    write-host $myobj.TelephoneNumber -fore green
    write-host (“City: ”).padright($pad) -NoNewline
    write-host $myobj.city -fore green
    write-host (“Mail Code: ”).padright($pad) -NoNewline
    write-host $myobj.office -fore green
    write-host (“Cost Center: ”).padright($pad) -NoNewline
    write-host $myobj.extensionAttribute12 -fore green
    write-host (“Manager: ”).padright($pad) -NoNewline
    write-host $myobj.Manager -fore green
    write-host (“Description: ”).padright($pad) -NoNewline
    write-host $myobj.Description -fore green

    Write-Host ""
    funline("Account Status")
    write-host (“PasswordLastSet: ”).padright($pad) -NoNewline
    write-host $myobj.PasswordLastSet -fore green
    #if ($myobj.passwordexpired -match "True") {
        write-host (“PasswordExpired: ”).padright($pad) -NoNewline
        write-host $myobj.PasswordExpired -fore Cyan
    #}
    <#
    write-host (“BadLogonCount: ”).padright($pad) -NoNewline
    write-host $myobj.BadLogonCount -fore green
    #>
    write-host (“BadPwdCount: ”).padright($pad) -NoNewline
    write-host $myobj.BadPwdCount -fore green

    #if ($myobj.lockedout -match "True") {
        write-host (“LockedOut: ”).padright($pad) -NoNewline
        write-host $myobj.LockedOut -fore Cyan
    #}

    ### WRITE WARNING ERROR MESSAGES ###
    $warningnotice = "False"

    # Account Disabled
    if ($myobj.enabled -match "False"){
        write-host ""
        write-warning "Account is Disabled"
        $warningnotice = "True"
    }
    # Password Expired
    if ($myobj.passwordexpired -match "True") {
        if($warningnotice -match "False") {write-host ""}
        else{$warningnotice = "True"}

        write-warning "Password is Expired"
    }
    # Unlock on all DCs
    if ($myobj.lockedout -match "True") {
        if($warningnotice -match "False") {write-host ""}
        else{$warningnotice = "True"}

        write-warning "Account is Locked"
        $YorN = read-host "Unlock AD Account? Y/N"
        if ( $YorN -match "Y" ) {
            foreach ($dc in $dcs) {
                unlock-adaccount $myobj -server $dc.name
                write-host "unlocked on:" $dc.name
            }
  
            #accountUnlockWorkflow $dcs $myobj.SamAccountName
        }
    }

    $i++

    # INCLUDE SEPARATION IF MORE THAN ONE USER 
    if($i -ne $newuser.Length){
        Write-Host ""
        write-host "########################################" -ForegroundColor Cyan
    }
}

}

## Function used to underline information
function funline ($strIN)
{
 $num = $strIN.length
 for($i=1 ; $i -le $num ; $i++)
  { $funline = $funline + "=" }
    Write-Host -ForegroundColor yellow $strIN
    Write-Host -ForegroundColor darkYellow $funline
} #end funline