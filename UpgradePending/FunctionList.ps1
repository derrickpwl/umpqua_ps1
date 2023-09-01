## NOTE: Many Scripts here came from Josh. Some have been tweaked and some left as is.

function Check-IsGroupMember{

Param($user,$grp)

$strFilter = "(&(objectClass=Group)(name=" + $grp +"))"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = "Subtree"

$colResults = $objSearcher.FindOne()

$objItem = $colResults.Properties
([string]$objItem.member).contains($user)

}

function ping-system
{
    $ping = Test-Connection -ComputerName $ub -Count 1 -ErrorAction SilentlyContinue
    $ip = (Resolve-DNSName $ub).IPAddress
    if($ip.substring(0,6) -eq "10.233") {
        write-host "Possible VPN IP detected - results may be inaccurate" -fore red -back yellow
    }
    if($ping) {
        write-host "$ub ($ip) online :: $true".PadRight(20)
        return $true
    } else {
        write-host "$ub ($ip) online :: $false".PadRight(20)
        return $false
    }
}
 
function OS-info
{
    $proc = get-wmiobject win32_processor -comp $ub | Select-Object AddressWidth
    $os = get-wmiobject win32_operatingsystem -comp $ub | Select-Object BuildNumber,Caption,LastBootupTime,InstallDate
    $comp = Get-WmiObject Win32_ComputerSystem -comp $ub | Select-Object Manufacturer,Username,Domain
    $model = Get-WmiObject Win32_ComputerSystemProduct -comp $ub | Select-Object Name,Version
    $ram = Get-WMIObject win32_physicalmemory -comp $ub | Measure-Object -Property capacity -Sum | % {[math]::round(($_.Sum / 1GB),2)}
    $disk = Get-WmiObject Win32_LogicalDisk -comp $ub -Filter "DeviceID='C:'" | Select-Object Size,FreeSpace
    
    # Model version 
    write-host (“Model: ”).padright(30) -NoNewline
    $a = $model.Name; $b = $model.version; $c = $comp.manufacturer
    write-host ("$c - $b - $a") -fore green

    # OS Info
    $a = $OS.Caption; $b = $proc.addresswidth; $c = $os.buildnumber; $d = $os.installdate
    Write-Host "Operating System: ".padright(30) -NoNewline
    Write-Host ("$a - v$c - $b bit") -fore green

    $year = $d.substring(0,4); $month = $d.substring(4,2); $day = $d.substring(6,2); $hour = $d.substring(8,2); $mins = $d.substring(10,2); $secs = $d.substring(12,2)
    if ($hour -gt 12) { $ampm = "PM" }
    else { $ampm = "AM" }
    Write-Host "OS Install Date: ".padright(30) -NoNewline
    Write-Host "$month/$day/$year, $hour" -fore green -NoNewline
    Write-Host ":$mins" -fore green -NoNewline
    Write-Host ":$secs $ampm" -fore green

    # Physical Memory
    write-host "Physical Memory: ".padright(30) -NoNewline
    write-host "$ram GB" -fore green

    # Domain
    write-host "Domain: ".padright(30) -NoNewline
    write-host $comp.Domain -fore green

    # Logged On User
    write-host "Current User: ".padright(30) -NoNewline
    write-host $comp.Username -fore cyan
    
    # System Uptime
    $lastBootuptime = [System.Management.ManagementDateTimeconverter]::ToDateTime($os.lastbootuptime)
    $now = Get-Date
    $uptime = $now - $lastBootuptime

    $time = "{0} Days,{1} hours,{2} minutes" -f $Uptime.Days,$Uptime.Hours,$uptime.Minutes
    write-host "System Uptime: ".padright(30) -NoNewline
    if ($Uptime.Days -gt 3) {WRITE-HOST $time -foregroundcolor red -backgroundcolor yellow}
    else {WRITE-HOST $time -fore cyan}

    # IE Version
    $IEPath32 = "\\$ub\c$\Program Files (x86)\Internet Explorer\iexplore.exe"
    $IEPath64 = "\\$ub\c$\Program Files\Internet Explorer\iexplore.exe"

    if (Test-Path $IEPath32) {
        $IEPath = $IEPath32
    } else {
        $IEPath = $IEPath64
    }

    $IEVerMajor = (get-item $IEPath).VersionInfo.ProductMajorPart
    $IEVerPrivate = (get-item $IEPath).VersionInfo.ProductPrivatePart
    $IEVerBuild = (get-item $IEPath).VersionInfo.ProductBuildPart
    $IEVerMinor = (get-item $IEPath).VersionInfo.ProductMinorPart
 
    write-host "Internet Explorer Version: ".PadRight(30) -NoNewline
    write-host "$IEVerMajor.$IEVerPrivate.$IEVerBuild.$IEVerMinor" -fore green

    # Chrome Version
    $chromePath32 = "\\$ub\c$\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    $chromePath64 = "\\$ub\c$\Program Files\Google\Chrome\Application\chrome.exe"

    if (Test-Path $chromePath32) {
        $chromeVer = (get-item $chromePath32).VersionInfo.ProductVersion
    } else {
        $chromeVer = (get-item $chromePath64).VersionInfo.ProductVersion
    }

    write-host "Chrome Version: ".PadRight(30) -NoNewline
    write-host $chromeVer -fore green

    # Hard drive space
    $freespace = [math]::Round($disk.FreeSpace/1GB,2)
    $totalspace = [math]::Round($disk.Size/1GB,2)

    write-host "Disk Space (C:): ".PadRight(30) -NoNewline
    write-host $freespace/$totalspace GB -fore Gray
}
 
function get-SCCMWS
{
    get-wmiobject -ComputerName PDX-SCCM-APP01 -namespace root/sms/site_HDC -query "select lastlogonusername, IPaddresses, IPsubnets, MACaddresses from sms_r_system where name = '$ub'” | select-object lastlogonusername, IPaddresses, IPsubnets, MACaddresses |format-list
}
 
Function Check-WMI
{
    $wmi = Get-WmiObject Win32_OperatingSystem -comp $ub -ErrorAction SilentlyContinue
    if($wmi) {
        return "Healthy"
    } else { 
        return "Broken"
    }     
    <#        
    $namespace = 'root\cimv2'
    $class = 'Win32_OperatingSystem'

    $wmi = Get-WmiObject -ComputerName $ub -Namespace $namespace -Class $class -ErrorAction SilentlyContinue
        if($wmi){
            $Status = "Healthy"
            #write-host "$UB WMI Status :: ".PadRight(30) -NoNewline
            #write-host $Status -ForegroundColor Green
            return $status}
        else{ 
            $Status = "Broken"
            #write-host "$UB WMI Status :: ".PadRight(30) -NoNewline
            #write-host $Status -ForegroundColor Red
            return $Status} 
    #>     
 }
 
Function Check-Client
{
    write-host "Getting Client Information: ".PadRight(30) -NoNewline   
        if(test-path "\\$ub\C$\Windows\CCM\CcmExec.exe")
        {  
        $client = get-command "\\$ub\C$\Windows\CCM\CcmExec.exe" -ErrorAction SilentlyContinue 
        $clientver = $client.FileVersionInfo.fileversion
        write-host $clientver -foregroundcolor cyan -NoNewline 
        write-host " NEW VERSION" -ForegroundColor Green}

        elseif(Test-Path "\\$ub\C$\Windows\system32\CCM\CcmExec.exe") 
        { 
        $client = get-command "\\$ub\C$\Windows\system32\CCM\CcmExec.exe" -ErrorAction SilentlyContinue
        $clientver = $client.FileVersionInfo.fileversion
        write-host $clientver -NoNewline -ForegroundColor darkcyan 
        Write-host "OLD VERSION" -ForegroundColor DarkGreen} 

        else {write-host "NO CLIENT DETECTED/INSTALLED" -ForegroundColor Red} 
} 
  
Function Check-AD_OU-WSUS
{
    $Group = get-adgroup “GPO_Client-WSUS” 
    $Groupmem = Get-ADGroupMember -Identity $Group
 
    If($Groupmem.name -match $UB)
        {
        Write-host "$ub is member of ::" -fore Yellow -NoNewline
        Write-host "GPO_Client-WSUS" -back DarkGray}
    ELSE
        {
        write-host "$ub is not a member of ::" -fore Green -NoNewline
        Write-host "GPO_Client-WSUS" -back DarkGray}
}
 
Function test-c$
{
    if(Test-path \\$ub\c$) {return $true}
    else{return $false}
}
 
Function Check-StaleStatus
{
    $group = "OU=_Stale Client Accounts,OU=UB-Computers,DC=Umpquanet,DC=local" 
    if (get-adcomputer -filter {name -eq $ub}) 
        {
        write-host "Found in AD" -foregroundcolor Green
            if (get-adcomputer -filter * -searchbase $group | Where-Object {$_.name -match $ub}) 
                {write-host "Found in Stale Accounts" -ForegroundColor Yellow} 
            else{write-host "Not Stale" -ForegroundColor Green} } 
 
    else {write-host " - Not in AD" -ForegroundColor Red} 
}
 
Function InfoTable
{
    $global:data.GetEnumerator() | Format-Table
} 

function RAM-Info([string]$strComputer)
{

    ### SYSTEM INFO #####################
    #Summary information
    $comp = Get-WmiObject Win32_ComputerSystem -comp $strComputer | Select-Object name, Manufacturer
    $model = Get-WmiObject Win32_ComputerSystemProduct -comp $strComputer | Select-Object name, version

    # Computer Name
    write-host (“Name: ”).padright(30) -NoNewline
    write-host $comp.Name -fore green

    # Model version
    write-host (“Model: ”).padright(30) -NoNewline
    $a = $model.Name; $b = $model.version; $c = $comp.manufacturer
    write-host ("$c - $b - $a")-fore green

    #write-host (“Manufacturer: ”).padright(30) -NoNewline
    #write-host $Stats.Manufacturer -fore green

    # Model version
    #write-host (“Model: ”).padright(30) -NoNewline
    #$a = $model.Name; $b = $model.version
    #write-host ("$b - $a")-fore green

    ### SLOTS FILLED ####################
    $colRAM = Get-WmiObject win32_PhysicalMemory -comp $strComputer | Select-Object Capacity,DeviceLocator
    $NumSlots = (Get-WmiObject win32_PhysicalMemoryArray -comp $strComputer).MemoryDevices

    $SlotsFilled = 0
    $TotMemPopulated = 0

    #Write-Host ""
    $colRAM | ForEach {
        $gb = ($_.Capacity / 1GB)
        $dev = $_.DeviceLocator
        
        write-host (“Memory Installed: ”).padright(30) -NoNewline
        write-host ("$dev - $gb GB") -fore green
            
        $SlotsFilled = $SlotsFilled + 1
        $TotMemPopulated = $TotMemPopulated + ($_.Capacity / 1GB)
    }

    write-host ""
    write-host "Total Memory Populated = " $TotMemPopulated "GB"
    write-host ($SlotsFilled) " of " $NumSlots " slots Used/Filled"
}

function SCCM([string]$ComputerName)
{
    Write-Host ""
    write-host "Forcing SCCM Device Check In" -ForegroundColor Yellow
    Write-Host "============================" -ForegroundColor DarkYellow
    $SCCMClient = [wmiclass] "\\$ComputerName\root\ccm:SMS_Client"

    $ApplicationDeploy = "{00000000-0000-0000-0000-000000000121}"
    $HardwareInventory = "{00000000-0000-0000-0000-000000000001}"
    $MachinePolicy = "{00000000-0000-0000-0000-000000000022}"

    try{
        write-host "Triggering Application Deployment Evaluation Cycle..."
        $SCCMClient.TriggerSchedule($ApplicationDeploy) > $null
        write-host "Triggering Hardware Inventory Cycle..."
        $SCCMClient.TriggerSchedule($HardwareInventory) > $null
        write-host "Triggering Machine Policy Retrieval and Evaluation Cycle..."
        $SCCMClient.TriggerSchedule($MachinePolicy) > $null
        }
    catch{$_.Exception.Message}

    Write-Host ""
}

function checkOffline([string]$ub)
{
    ## Check for valid input
    if ([string]::IsNullOrWhiteSpace($ub)) {write-warning "Given string is NULL or having WHITESPACE";return $true}
    if(-not (ping2($ub))) {write-warning "$ub is offline";return $true}

    return $false
}