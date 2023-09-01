Function Set-OutofOffice
{
 
Param
(
 #[String][Parameter(Mandatory=$True, Position=1)] $Computername
)
 
Begin {}

Process {

    ## Check for Exchange connection and connect as needed
    if (!(Get-PSSession | Where { $_.ConfigurationName -eq "Microsoft.Exchange" })) { 
        $username = (get-aduser $env:USERNAME).UserPrincipalName
        Connect-ExchangeOnline -UserPrincipalName $username
    }


    ## Load Main XAML/WPF and set variables
    $path = "C:\PowerShell\Modules\XAML\exoProject.xaml"

    $XamlPath = $PSScriptRoot + "\xaml\exoProject.xaml"
    [xml]$xmlWPF = Get-Content -Path $XamlPath
    $mainGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))
    $xmlWPF.SelectNodes("//*[@Name]") | %{
        Set-Variable -Name ($_.Name) -Value $mainGUI.FindName($_.Name)}


    ## MainGUI Controls
    ###############################################################################

    ## Add function to FindNow button: searches mailboxes with name like searchName and populate the mailbox List
    $findButton.Add_Click({

        if ($searchName.Text){
            # Search mailboxes with name like search field
            $mailboxes = Get-Mailbox -Anr $searchName.Text

            # Create array to populate email list
            $mailboxList = @()
            ForEach ($user in $mailboxes){
                $mailboxList += ([PSCustomObject]@{Name=$user.Name; Email=$user.PrimarySmtpAddress; RecipientType=$user.RecipientType})}
            $emailList.ItemsSource = $mailboxList
        }
    })

    ## Open new Window on double-click for selected item on mailbox list
    $emailList.Add_MouseDoubleClick({

        ## Load UserWindow XAML/WPF and set variables
        $XamlPath = $PSScriptRoot + "\xaml\userWindow.xaml"
        [xml]$xmlWPF = Get-Content -Path $XamlPath
        $userGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))
        $xmlWPF.SelectNodes("//*[@Name]") | %{
            Set-Variable -Name ($_.Name) -Value $userGUI.FindName($_.Name)}

        ## Load AutoReply Configuration settings
        #-------------------------------------------------------------------------
        $userWindow.Title = $emailList.SelectedItem.Email
        $userAutoReplyConfig = Get-MailboxAutoReplyConfiguration $emailList.SelectedItem.Email
    
        # Set AutoReply On/OFF radio button
        $arState = $userAutoReplyConfig.AutoReplyState
        if($arState -eq "Disabled"){$arOff.IsChecked="True"}
        else{$arOn.IsChecked="True"}

        # Set AutoReply time range settings
        $startDP.SelectedDate = $userAutoReplyConfig.StartTime
        $endDP.SelectedDate = $userAutoReplyConfig.EndTime

        # Parse message HTML and convert to plain text with regex. Set AutoReply TextBox text to message
        $arInternalMsg = $userAutoReplyConfig.InternalMessage
        $arTextBox.Text = ($arInternalMsg -replace(‘<[^>]+>’,"”)).Replace("&nbsp;", " ")
        $arExternalMsg = $userAutoReplyConfig.ExternalMessage

        ## Load Rules Configuration settings
        #-------------------------------------------------------------------------
    
        # NOTE: Will load rules once upon getting focus as Get-InboxRule can take a minute to run
        $global:loadRules = $True
        $RulesTab.Add_GotFocus({
            if($global:loadRules){

                $userGUI.Dispatcher.Invoke(
                    [action]{$global:userRules = Get-InboxRule -Mailbox $emailList.SelectedItem.Email},
                    "Render")

            # Create array to populate rule list
            $rulesArray = @()
            ForEach ($rule in $global:userRules){
                $rulesArray += ([PSCustomObject]@{Priority=$rule.Priority; Name=$rule.Name; Enabled=$rule.Enabled})}
            $rulesList.ItemsSource = $rulesArray
            }
        $global:loadRules = $False

        })

        ## UserWindow Controls
        ###########################################################################

        $userOkButton.Add_Click({
            Write-Host "Setting out of office!"

            if($arOff.IsChecked){$arState = "Disabled"}
            else{$arState = "Enabled"}

            Set-MailboxAutoReplyConfiguration $emailList.SelectedItem.Email -AutoReplyState $arState -InternalMessage $arTextBox.Text -ExternalMessage $arTextBox.Text

        })


        $userGUI.ShowDialog()
    })

    $mainGUI.ShowDialog()
}
 
End {}
 
}
