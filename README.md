# PS-ChefBootstrapFromCsv

## Usage

* Copy your validator pem into this directory
* Ensure the csv you're using has the appropriate headers
    * Name
    * IP Address
    * Guest OS

* To run the script
    ```.\Bootstrap-ChefNodeFromCsv.ps1 -SourceCsv [PATH TO CSV] -DomainName [DOMAIN FOR USER]
        -Username [USER TO LOGIN] -ChefServerUrl [URL FOR KNIFE.RB] -Customer [SERVER CUSTOMER TAG]
        -ValidatorName [VALIDATOR FILE NAME NO .PEM] -Environment [CHEF ENVIRONMENT]
    ```
    * **NOTE: The script will prompt you for the password for the username provided via securestring prompt**

** NOTE: To reduce load on Chef Server the Scheduled Task to run Chef Client for the first time has a splay of 30 seconds to 15 minutes