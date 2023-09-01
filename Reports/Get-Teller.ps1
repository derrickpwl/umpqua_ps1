

function Get-Teller([string]$ComputerName)
{
    # Look for a TI database file on the computer
    $chkFile = "\\" + $ComputerName + "\c$\TI_DB"

    # Parse DB file name. Lookup only uses first 6 characters ex: AA0376T1.db > AA0376

    $dbFile = Get-ChildItem $chkFile
    if($dbFile -eq $null){return $false}

	$dbName = Get-ChildItem $chkFile -name
    $lastMod = (Get-ChildItem $chkFile).LastWriteTime
    
    $dbName = $dbName.Substring(0,8)
	
	# Finds the row in the cvs file at this path assocated with dbName
	$csv = Import-Csv \\X55555AA00400V.umpq.umpquabank.com\core\Sybase\Central\TIDatabases.csv |
        Where-Object {$_.DBName -like $dbName} |
        ForEach-Object {$StoreNum = $_.BRNumber; $StoreName = $_.StoreName}

    # Create Output Object
    $userObj = New-Object System.Object
    $userObj | Add-Member -type NoteProperty -Name DBName -Value $dbName
    $userObj | Add-Member -type NoteProperty -Name StoreNum -Value $StoreNum
    $userObj | Add-Member -type NoteProperty -Name StoreName -Value $StoreName
    $userObj | Add-Member -type NoteProperty -Name LastWrite -Value $lastMod
    #$userObj | Add-Member -type NoteProperty -Name ProdName -Value $prodName
    return $userObj
}

