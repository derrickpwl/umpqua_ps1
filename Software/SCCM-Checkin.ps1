Function SCCM-Checkin
{
 
Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername
)
 
Begin {}
 
Process {
    Run-SCCMClientAction -Computername $Computername -ClientAction HardwareInventory,MachinePolicy,MachinePolicyEval,UpdateDeployment,DiscoveryData
    #AppDeployment,DiscoveryData,SoftwareInventory
}
 
End {}
 
}
