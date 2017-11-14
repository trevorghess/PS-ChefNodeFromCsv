# Get parameters from pipeline
Param
(
    # This is the business unit variable for the firstboot json file
    [Parameter(Mandatory=$true)]
    [String]
    $ClientBU,

    # This is the chef_server_url variable for the client RB file
    [Parameter(Mandatory=$true)]
    [String]
    $ChefServerURL,

    # This is the validation client name variable for the client RB file
    [Parameter(Mandatory=$true)]
    [String]
    $ValidatorName,   
    
    # This is the environment variable for the client RB file
    [String]
    $ClientEnv = '',
    
    # This is the log location variable for the client RB file
    [String]
    $LogLocation = "'STDOUT'",

    #Name of our certificate for trusted_certs
    [String]
    $CertName = ''
)

$ChefRootDir = "c:\chef"
$CertPath = "c:\chef\trusted_certs"
$ChefClientRBFile = "client.rb"
$ChefFirstBootFile = "first-boot.json"
#$ClientEnv = "non-prod"
#$ClientBU = "Test"

# This funtion writes the required output to the client.rb file. The file needs to be generated instead of copied since the individual computer name needs to be injected into it.
function Create-ClientRBFile {
    write-output "log_level        :info" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii
    write-output "log_location     $LogLocation" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "chef_server_url  '$ChefServerURL'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "validation_client_name '$ValidatorName'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "validation_key '$ChefRootDir\$ValidatorName.pem'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "node_name '$($env:computername)'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "ssl_verify_mode :verify_none" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "environment '$ClientEnv'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
}

# Create the first-boot.json file. This runlist may need to be edited to specify the appropriate runlist and additional info (i.e. system_info)
function Create-FirstBootFile {
    write-output "{`"run_list`": [`"recipe[it_chef_client::default]`"], `"system_info`": {`"customer`": `"[$ClientBU]`"}}" | Out-File -FilePath $ChefRootDir\$ChefFirstBootFile -Encoding ascii
}

if($CertName -ne ''){
    Write-Host "$CertPath"
    if (!(Test-Path -Path "$CertPath")){
        New-Item -Path "$CertPath" -Type Directory
    }
}

### Let's make the client.rb
if (Test-Path -Path "$ChefRootDir\$ChefClientRBFile") {
    #File already exists so let's overwrite it with the new params
    Create-ClientRBFile
}
else{
    # something doesn't exist so we need to make the things
    if (Test-Path -Path "$ChefRootDir"){
        #Folder is there so all we need to do is make the file
        Out-File -FilePath "$ChefRootDir\$ChefClientRBFile" -Encoding ascii
    }
    else {
        #nothing exists so make all the things
        New-Item -Path "$ChefRootDir" -ItemType Directory
        Out-File -FilePath "$ChefRootDir\$ChefClientRBFile" -Encoding ascii
    }

    # now that the file exists, populate it!
    Create-ClientRBFile
}

### No make the firstboot.json
if (Test-Path -Path "$ChefRootDir\$ChefFirstBootFile") {
    #File already exists so let's overwrite it with the new params
    Create-ClientRBFile
}
else{
    # something doesn't exist so we need to make the things
    if (Test-Path -Path "$ChefRootDir"){
        #Folder is there so all we need to do is make the file
        Out-File -FilePath "$ChefRootDir\$ChefFirstBootFile" -Encoding ascii
    }
    else {
        #nothing exists so make all the things
        New-Item -Path "$ChefRootDir" -ItemType Directory
        Out-File -FilePath "$ChefRootDir\$ChefFirstBootFile" -Encoding ascii
    }


    # now that the file exists, populate it!
    Create-FirstBootFile
}

# Add hack so the script will run in PS 2.0 and higher ($PSScriptRoot isn't a thing in PS2.0 so this will use the old way to get the path)
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

# Last but not least, copy the validator file from the SCCM cache directory into the $ChefRootDir with the other files
Copy-Item -Path "$PSScriptRoot\$ValidatorName.pem" -Destination $ChefRootDir
if($CertName -ne ""){
    Copy-Item -Path "$PSScriptRoot\$CertName.crt" -Destination "$CertPath\$CertName.crt"
}
