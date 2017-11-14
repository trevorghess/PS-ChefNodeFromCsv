Param(
    # Parameter help description
    [Parameter(Mandatory=$true,Position=2)]
    [String]
    $ChefClientDownloadUrl
)
Write-Host "Downloading Chef Client from $ChefClientDownloadUrl" 
Invoke-WebRequest -Uri $ChefClientDownloadUrl -OutFile "chef-client.msi" 
Write-Host "Installing Chef Client"
Start-Process msiexec.exe -Wait -ArgumentList '/I chef-client.msi /qn ADDLOCAL="ChefClientFeature" ' -Verbose -NoNewWindow
$splay = Get-Random -Minimum 30 -Maximum 900
$T = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($splay)
Set-ScheduledTask Register-ChefNode -Trigger $T
Unregister-ScheduledTask Install-ChefClient -Confirm:$false