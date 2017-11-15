Start-Sleep -Seconds $(Get-Random -Minimum 30 -Maximum 300)
Write-Host "Running Chef Client"
Start-Process cmd.exe -Wait '/c "c:\opscode\chef\bin\chef-client.bat -j c:\chef\first-boot.json"'
Unregister-ScheduledTask Register-ChefNode -Confirm:$false