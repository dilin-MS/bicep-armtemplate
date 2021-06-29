# Enable storage account static website
az storage blob service-properties update --account-name <ACCOUNT_NAME> --static-website --404-document 'index.html' --index-document 'index.html'