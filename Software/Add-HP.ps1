Function Add-HP
{
 
Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername
)
 
Begin {}
 
Process {
    Trigger-AppInstallation -AppName "HP LaserJet M101-M106 Basic Device Software" -Method Install -Computername $Computername
}
 
End {}
 
}
