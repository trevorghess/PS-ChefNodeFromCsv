Param
(
    # Parameter help description
    [Parameter(Mandatory=$true)]
    [String]
    $SourceCsv,

    # Parameter help description
    [Parameter(Mandatory=$true)]
    [String]
    $DomainName,

    # Parameter help description
    [Parameter(Mandatory=$true)]
    [String]
    $Username,

    # Parameter help description
    [Parameter()]
    [String]
    $ChefClientDownloadUrl = "https://packages.chef.io/files/stable/chef/13.6.4/windows/2016/chef-client-13.6.4-1-x64.msi"
)
function Bootstrap-WindowsNode {
    Param(
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        $PSCred,

        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $ComputerName,
        
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $ChefClientDownloadUrl
    )
    Write-Host "Bootstrapping Windows Node"
    Enter-PSSession -ComputerName $ComputerName -Credential $PSCred
    Write-Host "Entered PSSession at $ComputerName"
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    # Write-Host "Creating Bootstrap Files"
    # ./Create-BootstrapFiles.ps1 -ChefServerUrl 'https://api.chef.io/organizations/hessco' -ClientBU 'Test' -ValidatorName 'thess-validator' -LogLocation ':win_evt'
    # Write-Host "Downloading Chef Client from $ChefClientDownloadUrl" 
    # Invoke-WebRequest -Uri $ChefClientDownloadUrl -OutFile "chef-client.msi" 
    # Write-Host "Installing Chef Client"
    # Start-Process msiexec.exe -Wait -ArgumentList '/I chef-client.msi /qn ADDLOCAL="ChefClientFeature" /L*V! "C:\repos\bootstrap\ccmsilog.log" ' -Verbose -NoNewWindow
    # Write-Host "Running Chef Client"
    # Start-Process cmd.exe -Wait '/c "c:\opscode\chef\bin\chef-client.bat -j c:\chef\first-boot.json"'
    Exit-PSSession
    
}
function Bootstrap-LinuxNode {
    Write-Host "This is a Linux Node and not yet implemented for Bootstrap"
}

Write-Host "Please specify password for domain user (hidden secure string):"
$Password = Read-Host -AsSecureString

$pscred = New-Object System.Management.Automation.PSCredential ($Username, $Password)

if((Test-Path $SourceCsv) -eq $false){
    Write-Error "Target CSV not found. Check source path." -ErrorAction Stop
}

Write-Host "Valid CSV Found."

$computers = Import-Csv $SourceCsv

$headers = $computers | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'

if($headers -contains 'Guest OS' -and $headers -contains 'IP Address' -and $headers -contains 'Name'){
    Write-Host 'Appropriate Headers Found'
}
else{
    Write-Error "CSV does not contain expected headers." -ErrorAction Stop
}

foreach($computer in $computers){
    $ipaddresses = $computer.{IP Address}.Split(',')
    $ipv4 = $ipaddresses | Where-Object {$_ -match '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'} | Select-Object $_ -First 1
    Write-Host "Preparing $ipv4 for bootstrap"

    if($computer.{Guest OS} -like 'Microsoft Windows*'){
        Bootstrap-WindowsNode -PSCred $pscred -ComputerName $computer.{Name} -ChefClientDownloadUrl $ChefClientDownloadUrl
    }
    else{
        Bootstrap-LinuxNode
    }
}