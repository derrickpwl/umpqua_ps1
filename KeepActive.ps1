$myShell = New-Object -com "Wscript.Shell"

for ($i = 1; $i -gt 0; $i) {
  Start-Sleep -Seconds 60
  $myShell.sendkeys('+{F15}')
}
