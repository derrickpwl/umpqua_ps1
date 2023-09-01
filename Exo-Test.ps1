Function Exo-Test
{
 
Param
(
 #[String][Parameter(Mandatory=$True, Position=1)] $Computername
)
 
Begin {}

Process {

    ## Check for Exchange connection and connect as needed
    $username = (get-aduser $env:USERNAME).UserPrincipalName
    Connect-ExchangeOnline -UserPrincipalName $username -CommandName "Get-MailboxAutoReplyConfiguration" -ShowBanner:$false

    Get-MailboxAutoReplyConfiguration "derrickpowell@umpquabank.com"


    Disconnect-ExchangeOnline -Confirm:$false
}

End {}
 
}
