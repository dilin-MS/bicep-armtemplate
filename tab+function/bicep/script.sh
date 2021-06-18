az --version
az bicep -v
# az login

# deploy bicep file to a resource group
az deployment sub create -f ./main.bicep -l eastus --parameters AADClientId='40beaf37-3903-494d-92b8-3ecbf5d68546' AADClientSecret='xxx' namePrefix='dilin061601' -c