Param(
    # Parameter help description
    [Parameter(Mandatory=$true,Position=0)]
    [String]
    $ChefClientDownloadUrl
)
Write-Host "Downloading Chef Client from $ChefClientDownloadUrl" 
$clientmsi = "chef-client.msi" 
if(!Test-Path $clientmsi){
    Invoke-WebRequest -Uri $ChefClientDownloadUrl -OutFile $clientmsi 
}
Write-Host "Installing Chef Client"
Start-Process msiexec.exe -Wait -ArgumentList '/I chef-client.msi /qn ADDLOCAL="ChefClientFeature" ' -Verbose -NoNewWindow
Start-ScheduledTask Register-ChefNode
Unregister-ScheduledTask Install-ChefClient -Confirm:$false