az --version
az bicep -v
# az login

# create resource group
az group delete --name dilintest
az group create --location eastus --name dilintest

# deploy bicep file to a resource group
az deployment sub create -f ./main.bicep -l eastus --parameters AADClientId='40beaf37-3903-494d-92b8-3ecbf5d68546' AADClientSecret='xxx' namePrefix='dilin061601' -c