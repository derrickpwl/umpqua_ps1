Function Pending-Installs
{
 
Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername
)
 
Begin {}
 
Process {
    Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | select Name
}
 
End {}
 
}


