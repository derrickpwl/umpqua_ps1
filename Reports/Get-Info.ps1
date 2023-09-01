## Get-Info 2.0


function Get-Info2{
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

        ## Gathering all system information
        $comp = Get-CimInstance -CimSession $mySession -ClassName Win32_ComputerSystem
        $disk = Get-CimInstance -CimSession $mySession -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        $model = Get-CimInstance -CimSession $mySession -ClassName Win32_ComputerSystemProduct
        $os = Get-CimInstance -CimSession $mySession -ClassName Win32_OperatingSystem
        $osKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName) | % {$_.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion", $True)}
        $proc = Get-CimInstance -CimSession $mySession -ClassName win32_processor
        $ram = Get-CimInstance -CimSession $mySession -ClassName win32_PhysicalMemory

        ## Return this custom object
        [pscustomobject]@{
            Model = "$($comp.Manufacturer) - $($model.Version)"
            OperatingSystem = "$($os.Caption) - $($proc.AddressWidth) bit" 
            OSInfo = "ReleaseID: v$($osKey.GetValue('ReleaseID')) - Build: $($os.BuildNumber) - Patch: $($osKey.GetValue('UBR'))"
            InstallDate = $os.installdate
            Domain = $comp.Domain
            LoggedOnUser = $comp.Username
            SystemUptime = (Get-Date) - ($os.LastBootUpTime) | % {"{0} Days, {1} hours, {2} minutes" -f $_.Days,$_.Hours,$_.Minutes}
            PhysicalMemory = "$($ram | Measure-Object -Property capacity -Sum | % {[math]::round(($_.Sum / 1GB),2)}) GB"
            DiskSpace = "$([math]::Round($disk.FreeSpace/1GB,2))/$([math]::Round($disk.Size/1GB,2)) GB"
        }
    }

    End {
        ## Cleanup CIM Session
        Remove-CimSession $mySession
        }
}


