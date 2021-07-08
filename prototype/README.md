## Overview
This project is a prototype of Teamsfx Toolkit ARM support using Bicep.

## How to start the prototype project
1. Create a .env file under root folder of prototype. Fill in your customized values.
    ```
    # .env file
    TENANT_ID="you-tenant-id"
    AZURE_SUBSCRIPTION_ID="your-subscription-id"

    RESOURCE_GROUP_NAME="your-project-name"

    SQL_ADMIN_LOGIN="your-sql-username"
    SQL_ADMIN_LOGIN_PASSWORD="your-sql-password"
    AAD_USER="your-aad-name"
    AAD_OBJECT_ID="your-aad-object-id"

    SERVICE_PRINCIPAL_APPID="your-service-principal-appid"
    SERVICE_PRINCIPAL_PASSWORD="your-service-principal-password"
    ```
1. In the root folder of prototype, run the below commands:
    ```
    npm i
    npm run start
    ```