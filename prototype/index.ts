import * as fs from "fs";
import * as path from "path";
import * as Handlebars from "handlebars";
import * as utils from "./utils";
import { PluginTypes, PluginBicepSnippet } from "./models";
import * as AADPlugin from "./plugins/aad/aad_plugin";
import * as FrontendHostingPlugin from "./plugins/frontend_hosting/frontend_hosting_plugin";
import * as FunctionPlugin from "./plugins/function/function_plugin";
import * as SimpleAuthPlugin from "./plugins/simple_auth/simple_auth_plugin";
import * as AzureSqlPlugin from "./plugins/azure_sql/azure_sql_plugin";
import * as IdentityPlugin from "./plugins/identity/identity_plugin";
import {
  ResourceManagementClient,
  ResourceManagementModels,
} from "@azure/arm-resources";
import { ClientSecretCredential } from "@azure/identity";
import {
  BlobServiceClient,
  BlobServiceProperties,
  StaticWebsite,
} from "@azure/storage-blob";
require("dotenv").config();

const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID;
const templateDir = path.join(__dirname, "..", "templates");
const bicepFilesDir = path.join(__dirname, "..", "bicep");
const mainFilePath = path.join(bicepFilesDir, "main.bicep");
const creds = new ClientSecretCredential(
  process.env.TENANT_ID,
  process.env.SERVICE_PRINCIPAL_APPID,
  process.env.SERVICE_PRINCIPAL_PASSWORD
);
let finished = false;

/**
 * This Main function prototypes what solution plugin does.
 */
async function main() {
  const pluginTypes = [
    PluginTypes.AAD,
    PluginTypes.FrontendHosting,
    PluginTypes.Function,
    PluginTypes.SimpleAuth,
    PluginTypes.AzureSql,
    PluginTypes.Identity,
  ];

  // 1. Create AAD App
  const aadInfo: AADPlugin.AADInfo = AADPlugin.createAADApp();

  // 2. generage bicep files
  const parameterKeys = generateBicepFiles(pluginTypes);

  // 3. Update parameter with value from env
  const parameterString = updateParameterWithValue(
    parameterKeys,
    aadInfo.clientId,
    aadInfo.clientSecret
  );
  console.log(`parameters: ${parameterString}`);

  // 3. deploy arm template to azure
  const deploymentResult = await deployArmTemplateToAzure(
    bicepFilesDir,
    parameterString
  );
  console.log(
    `Deployment finished: ${JSON.stringify(deploymentResult, null, 2)}`
  );

  // 4. data plane operation
  const frontendHosting_storageName =
    deploymentResult.properties.outputs.frontendHosting_storageName.value;
  executeDataPlaneOperation(frontendHosting_storageName);
}

/**
 * Generate bicep files
 */
function generateBicepFiles(pluginTypes: PluginTypes[]): string {
  utils.ensureDirectoryExists(bicepFilesDir);

  let codeSnippets: PluginBicepSnippet[] = [];
  const context = {
    pluginTypes: pluginTypes,
  };
  for (const plugin of pluginTypes) {
    switch (plugin) {
      case PluginTypes.AAD:
        codeSnippets.push(AADPlugin.generateBicepFile(context));
        break;
      case PluginTypes.FrontendHosting:
        codeSnippets.push(FrontendHostingPlugin.generateBicepFile());
        break;
      case PluginTypes.Function:
        codeSnippets.push(FunctionPlugin.generateBicepFile(context));
        break;
      case PluginTypes.SimpleAuth:
        codeSnippets.push(SimpleAuthPlugin.generateBicepFile(context));
        break;
      case PluginTypes.AzureSql:
        codeSnippets.push(AzureSqlPlugin.generateBicepFile());
        break;
      case PluginTypes.Identity:
        codeSnippets.push(IdentityPlugin.generateBicepFile());
        break;
      default:
        console.log(`Plugin not supported: ${plugin}`);
    }
  }

  // Resource plugin module
  codeSnippets.forEach((pluginSnippet) => {
    if (pluginSnippet.PluginResources) {
      const pluginResourceDestFilePath = path.join(
        bicepFilesDir,
        `${pluginSnippet.PluginTypes}.bicep`
      );
      fs.writeFileSync(
        pluginResourceDestFilePath,
        pluginSnippet.PluginResources
      );
      console.log(
        `Successfully generate resource plugin ${pluginSnippet.PluginTypes} bicep module file: ${pluginResourceDestFilePath}`
      );
    }
  });

  // main.bicep
  generateMainBicepFile(codeSnippets);

  // parameter
  const parameterKeys: string = getParametersKeys(codeSnippets);

  return parameterKeys;
}

function generateMainBicepFile(codeSnippets: PluginBicepSnippet[]) {
  const mainTemplateFilePath = path.join(templateDir, "main.template.bicep");
  let mainTemplate = fs.readFileSync(mainTemplateFilePath, "utf8");
  for (const pluginSnippet of codeSnippets) {
    if (pluginSnippet.MainInputParams) {
      mainTemplate += pluginSnippet.MainInputParams;
    }
  }
  for (const pluginSnippet of codeSnippets) {
    if (pluginSnippet.MainVars) {
      mainTemplate += pluginSnippet.MainVars;
    }
  }
  for (const pluginSnippet of codeSnippets) {
    if (pluginSnippet.MainModules) {
      mainTemplate += pluginSnippet.MainModules;
    }
  }
  for (const pluginSnippet of codeSnippets) {
    if (pluginSnippet.MainOutput) {
      mainTemplate += pluginSnippet.MainOutput;
    }
  }

  // solution plugin can customize each module's name and file path
  const moduleNames = {
    __simpleAuthDeploy__: "simpleAuthDeploy",
    __functionDeploy__: "functionDeploy",
    __frontendHostingDeploy__: "frontendHostingDeploy",
    __azureSqlDeploy__: "azureSqlDeploy",
    __identityDeploy__: "identityDeploy",
    __frontendHostingFilePath__: `${PluginTypes.FrontendHosting}.bicep`,
    __azureSqlFilePath__: `${PluginTypes.AzureSql}.bicep`,
    __functionFilePath__: `${PluginTypes.Function}.bicep`,
    __identityFilePath__: `${PluginTypes.Identity}.bicep`,
    __simpleAuthFilePath__: `${PluginTypes.SimpleAuth}.bicep`,
  };
  for (let key in moduleNames) {
    let value = moduleNames[key];
    mainTemplate = mainTemplate.replace(new RegExp(key, "g"), value);
  }
  fs.writeFileSync(mainFilePath, mainTemplate);
}

function getParametersKeys(codeSnippets: PluginBicepSnippet[]): string {
  const parameterTemplateFilePath = path.join(
    templateDir,
    "main.parameter.template.json"
  );
  let parameterString = fs.readFileSync(parameterTemplateFilePath, "utf8");
  let parameters = JSON.parse(parameterString);
  for (const pluginSnippet of codeSnippets) {
    if (pluginSnippet.Parameter) {
      parameters = {
        ...parameters,
        ...pluginSnippet.Parameter,
      };
    }
  }

  return parameters;
}

function updateParameterWithValue(
  parameters: string,
  clientId: string,
  clientSecret: string
): string {
  const parameterContext = {
    TENANT_ID: process.env.TENANT_ID,
    CLIENT_ID: clientId,
    CLIENT_SECRET: clientSecret,
    RESOURCE_GROUP_NAME: process.env.RESOURCE_GROUP_NAME,
    SIMPLE_AUTH_SKU: process.env.SIMPLE_AUTH_SKU,
    AAD_USER: process.env.AAD_USER,
    AAD_OBJECT_ID: process.env.AAD_OBJECT_ID,
    SQL_ADMIN_LOGIN: process.env.SQL_ADMIN_LOGIN,
    SQL_ADMIN_LOGIN_PASSWORD: process.env.SQL_ADMIN_LOGIN_PASSWORD,
  };
  let template = Handlebars.compile(JSON.stringify(parameters));
  let updatedParameters = template(parameterContext);
  return updatedParameters;
}

function executeDataPlaneOperation(storageName: string): void {
  const blobServiceClient = new BlobServiceClient(
    `https://${storageName}.blob.core.windows.net`,
    creds
  );
  const blbServiceProperties: BlobServiceProperties = {
    staticWebsite: {
      enabled: true,
      indexDocument: "index.html",
      errorDocument404Path: "index.html",
    } as StaticWebsite,
  };
  blobServiceClient.setProperties(blbServiceProperties);
  console.log(
    `Successfully enable static website of ${blobServiceClient.accountName}.`
  );
}

async function deployArmTemplateToAzure(
  bicepFilesDir: string,
  parameterString: string
): Promise<ResourceManagementModels.DeploymentsCreateOrUpdateResponse> {
  // Transform bicep file to json arm template file through Bicep CLI
  const armTemplateJsonFilePath: string = path.join(bicepFilesDir, "main.json");
  await utils.executeCommand(
    `del ${armTemplateJsonFilePath} && bicep build ${mainFilePath} --outfile ${armTemplateJsonFilePath}`
  );
  console.log(
    `Successfully generate arm template json file ${armTemplateJsonFilePath}. Prepare to deploy the arm template to Azure.`
  );

  // Deploy ARM template to provision resources
  const client = new ResourceManagementClient(creds, subscriptionId);

  let template = JSON.parse(fs.readFileSync(armTemplateJsonFilePath, "utf8"));

  type DeploymentMode = "Incremental" | "Complete";
  let deploymentParameters = {
    properties: {
      parameters: JSON.parse(parameterString),
      template: template,
      mode: "Incremental" as DeploymentMode,
    },
  };
  const resourceGroupName = process.env.RESOURCE_GROUP_NAME;
  if (!resourceGroupName) {
    throw new Error(
      "RESOURCE_GROUP_NAME not found in environment. Please add RESOURCE_GROUP_NAME='myExistingResourceGroupName' in .env file and try again"
    );
  }
  const deploymentName = "TeamsFxToolkitDeployment";
  try {
    const result = client.deployments
      .createOrUpdate(resourceGroupName, deploymentName, deploymentParameters)
      .then((result) => {
        console.log(
          `Successfully deploy arm template to resource group ${resourceGroupName}.`
        );
        return result;
      })
      .finally(() => {
        finished = true;
      });
    let deploymentStartTime = Date.now();
    pollDeploymentStatus(client, deploymentStartTime);
    return result;
  } catch (err) {
    console.log(
      `Fail to deploy arm template to resource group ${resourceGroupName}. Error message: ${err.message}`
    );
  }
}

async function pollDeploymentStatus(
  client: ResourceManagementClient,
  deploymentStartTime: number
): Promise<void> {
  console.log("polling deployment status...");

  setTimeout(async () => {
    if (!finished) {
      let deployments = await client.deployments.listByResourceGroup(
        process.env.RESOURCE_GROUP_NAME
      );
      deployments.forEach((deployment) => {
        if (deployment.properties.timestamp.getTime() > deploymentStartTime) {
          console.log(
            `[${deployment.properties.timestamp}] ${deployment.name} -> ${deployment.properties.provisioningState}`
          );
          if (deployment.properties.error) {
            console.log(
              `Error message: ${JSON.stringify(
                deployment.properties.error,
                null,
                2
              )}`
            );
          }
        }
      });
      pollDeploymentStatus(client, deploymentStartTime);
    }
  }, 10000);
}

main().catch((err) => {
  console.log(err.message);
});
