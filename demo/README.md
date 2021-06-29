Pre-provision:
* AAD App

Provision:
* Create Resources
    * Function
    * Simple Auth
    * Azure SQL
    * Identity
* Data plane update
    * Frontend hosting storage enable static website: `az storage blob service-properties update --account-name <ACCOUNT_NAME> --static-website --404-document 'index.html' --index-document 'index.html'`

Post-provision:
* Update configuration with bicep files under ./postProvision
