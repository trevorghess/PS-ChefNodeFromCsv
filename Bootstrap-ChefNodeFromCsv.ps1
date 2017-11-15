Param
(
    # Source CSV to Bootstrap
    [Parameter(Mandatory=$true)]
    [String]
    $SourceCsv,

    # Domain name to be used for running tasks on nodes
    [Parameter(Mandatory=$true)]
    [String]
    $DomainName,

    # Username for connecting to nodes and running tasks
    [Parameter(Mandatory=$true)]
    [String]
    $Username,

    # Customer name for server
    [Parameter(Mandatory=$true)]
    [String]
    $CustomerName,       

    # Chef Server URL for knife rb
    [Parameter(Mandatory=$true)]
    [String]
    $ChefServerUrl,       

    # Validator file name for knife rb
    [Parameter(Mandatory=$true)]
    [String]
    $ValidatorName,  

    # Location to download chef client installer from
    [Parameter()]
    [String]
    $ChefClientDownloadUrl = "https://packages.chef.io/files/stable/chef/13.6.4/windows/2016/chef-client-13.6.4-1-x64.msi",       

    # Target chef environment
    [Parameter()]
    [String]
    $Environment = '',

    # Parameter help description
    [Parameter()]
    [String]
    $CertName = ''
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
        $DomainName,
        
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $ChefClientDownloadUrl,
        
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $CustomerName,       
    
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $ChefServerUrl,       
    
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $ValidatorName,       
        
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [String]
        $Username, 

        # Parameter help description
        [Parameter(Mandatory=$true)]
        [securestring]
        $Password,

        # Parameter help description
        [String]
        $Environment = '',
        
        # Parameter help description
        [String]
        $CertName = ''
    )
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Password)
    $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
    Write-Host "Bootstrapping Windows Node"
    $session = New-PSSession -ComputerName $ComputerName -Credential $PSCred -ErrorAction Stop

    Write-Host "Entering PSSession at $ComputerName"
    Invoke-Command -Session $session -ScriptBlock {
        $ComputerName = $args[0]
        Write-Host "On remote computer $ComputerName"
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    } -ArgumentList $ComputerName

    Write-Host "Creating Bootstrap Files"
    $location = Get-Location
    Write-Host "$location\$ValidatorName.pem"
    Invoke-Command -Session $session -ScriptBlock{
        $TargetDir = "C:\bootstraptemp"
        if(!(Test-Path -Path $TargetDir )){
            New-Item -Path $TargetDir -ItemType Directory
        }
    }

    Write-Host "Copying files to remote machine"
    Copy-Item -ToSession $session "$location\$ValidatorName.pem" -Destination C:\$ValidatorName.pem
    Copy-Item -ToSession $session "$location\Install-ChefClient.ps1"-Destination C:\bootstraptemp\Install-ChefClient.ps1
    Copy-Item -ToSession $session "$location\Register-ChefNode.ps1" -Destination C:\bootstraptemp\Register-ChefNode.ps1
    if($CertName -ne ""){
        Copy-Item -ToSession $session "$location\$CertName.crt" -Destination C:\$CertName.crt
    }

    Invoke-Command -Session $session -FilePath ./Create-BootstrapFiles.ps1 -ArgumentList $CustomerName, $ChefServerUrl, $ValidatorName, $Environment,':win_evt', $CertName
    Invoke-Command -Session $session -ScriptBlock{
        param($DomainName, $Username, $Password, $ChefClientDownloadUrl)
        Remove-Item C:/$ValidatorName.pem -Force
        if(Test-Path -Path C:/$CertName.crt){
            Remove-Item C:/$CertName.crt -Force
        }
        Write-Host "Cleaning up validator"
        $installTaskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\bootstraptemp\Install-ChefClient.ps1 $ChefClientDownloadUrl"
        $installTaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddDays(7)
        $installTaskSettings = New-ScheduledTaskSettingsSet
        Register-ScheduledTask -TaskName Install-ChefClient -RunLevel Highest -User "$DomainName\$Username" -Password $Password -Action $installTaskAction -Trigger $installTaskTrigger -Settings $installTaskSettings
        $registerTaskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\bootstraptemp\Register-ChefNode.ps1"
        $registerTaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddDays(7)
        $registerTaskSettings = New-ScheduledTaskSettingsSet
        Register-ScheduledTask -TaskName Register-ChefNode -RunLevel Highest -User "$DomainName\$Username" -Password $Password -Action $registerTaskAction -Trigger $registerTaskTrigger -Settings $registerTaskSettings
        Start-ScheduledTask Install-ChefClient
    } -ArgumentList $DomainName, $Username, $result, $ChefClientDownloadUrl
    Exit-PSSession
    
}
function Bootstrap-LinuxNode {
    Write-Host "This is a Linux Node and not yet implemented for Bootstrap"
}

Write-Host "Please specify password for domain user (hidden secure string):"
$Password = Read-Host -AsSecureString

$pscred = New-Object System.Management.Automation.PSCredential ("$DomainName\$Username", $Password)

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
        Bootstrap-WindowsNode -PSCred $pscred -ComputerName ($computer.{Name} + "." + $DomainName) -DomainName $DomainName -ChefClientDownloadUrl $ChefClientDownloadUrl -CustomerName $CustomerName -ChefServerUrl $ChefServerUrl -ValidatorName $ValidatorName -Environment $Environment -CertName $CertName -Username $Username -Password $Password
    }
    else{
        Bootstrap-LinuxNode
    }
}