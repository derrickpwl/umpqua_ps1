Function Test-Install
{
 
Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername
)
 
Begin {}
 
Process {
    $MyDevice = Get-CMDevice -name $Computername -CollectionName "All Windows Workstations With an Active Agent"
    Add-CMDeviceCollectionDirectMembershipRule -CollectionID "UB104020" -ResourceID $MyDevice.ResourceID
}
 
End {}
 
}


