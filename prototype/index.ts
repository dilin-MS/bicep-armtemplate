import * as AADPlugin from "./aad_plugin";
import * as fs from "fs";
import * as path from "path";
import * as utils from "./utils";
import {
  ResourceManagementClient,
  ResourceManagementModels,
} from "@azure/arm-resources";
import { DefaultAzureCredential } from "@azure/identity";
import {
  BlobServiceClient,
  BlobServiceProperties,
  StaticWebsite,
} from "@azure/storage-blob";
require("dotenv").config();

const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID;
const templateDir = path.join(__dirname, "..", "templates");
const bicepFilesDir = path.join(__dirname, "..", "bicep");
const parameterTemplateFilePath = path.join(
  templateDir,
  "main.parameter.template.json"
);
const parameterFilePath = path.join(bicepFilesDir, "main.parameter.json");
const mainTemplateFilePath = path.join(templateDir, "main.template.bicep");
const mainFilePath = path.join(bicepFilesDir, "main.bicep");

enum PluginTypes {
  AAD = "aad_app",
  Function = "function",
  FrontendHosting = "frontend_hosting",
  AzureSql = "azure_sql",
  Identity = "identity",
  SimpleAuth = "simple_auth",
}

async function main() {
  const pluginsContext = {
    pluginTypes: [
      PluginTypes.AAD,
      PluginTypes.FrontendHosting,
      PluginTypes.Function,
      PluginTypes.SimpleAuth,
    ],
  };

  await preProvision(pluginsContext);

  const deploymentResult = await provisionArmBicepToAzure(bicepFilesDir);

  const frontendHosting_connectionString =
    deploymentResult.properties.outputs.frontendHosting_connectionString.value;
  await executeDataPlaneOperation(frontendHosting_connectionString);
}

/**
 * Create AAD App Registration and get clientId, clientSecret
 */
async function preProvision(pluginsContext: any): Promise<void> {
  utils.ensureDirectoryExists(bicepFilesDir);

  // Create AAD App
  const aadInfo: AADPlugin.AADInfo = AADPlugin.createAADApp();

  // generate main.parameter.json
  generateParameterFile(aadInfo.clientId, aadInfo.clientSecret, pluginsContext);

  // generate frontend hosting update bicep files
  const frontendHostingTemplateFilePath = path.join(
    templateDir,
    "frontend_hosting.template.bicep"
  );
  const frontendHostingDestFilePath = path.join(
    bicepFilesDir,
    "frontend_hosting.bicep"
  );
  utils.generateBicepFiles(
    frontendHostingTemplateFilePath,
    frontendHostingDestFilePath,
    pluginsContext
  );

  // generate function update bicep files
  const functionTemplateFilePath = path.join(
    templateDir,
    "function.template.bicep"
  );
  const functionDestFilePath = path.join(bicepFilesDir, "function.bicep");
  utils.generateBicepFiles(
    functionTemplateFilePath,
    functionDestFilePath,
    pluginsContext
  );

  // generate simple auth bicep files
  const simpleAuthTemplateFilePath = path.join(
    templateDir,
    "function.template.bicep"
  );
  const simpleAuthDestFilePath = path.join(bicepFilesDir, "function.bicep");
  utils.generateBicepFiles(
    simpleAuthTemplateFilePath,
    simpleAuthDestFilePath,
    pluginsContext
  );

  // generate main.bicep
  utils.generateBicepFiles(mainTemplateFilePath, mainFilePath, pluginsContext);
}

async function generateParameterFile(
  clientId: string,
  clientSecret: string,
  pluginsContext: any
) {
  const aad_context = {
    TENANT_ID: process.env.TENANT_ID,
    CLIENT_ID: clientId,
    CLIENT_SECRET: clientSecret,
    RESOURCE_GROUP_NAME: process.env.RESOURCE_GROUP_NAME,
    SIMPLE_AUTH_SKU: process.env.SIMPLE_AUTH_SKU,
  };

  const context = {
    ...pluginsContext,
    ...aad_context,
  };

  utils.generateBicepFiles(
    parameterTemplateFilePath,
    parameterFilePath,
    context
  );
}

async function executeDataPlaneOperation(
  connectionString: string
): Promise<void> {
  const blobServiceClient = BlobServiceClient.fromConnectionString(
    connectionString
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

async function provisionArmBicepToAzure(
  bicepFilesDir: string
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
  const creds = new DefaultAzureCredential();
  const client = new ResourceManagementClient(creds, subscriptionId);

  let template = JSON.parse(fs.readFileSync(armTemplateJsonFilePath, "utf8"));
  let parameter = JSON.parse(fs.readFileSync(parameterFilePath, "utf8"));

  type DeploymentMode = "Incremental" | "Complete";
  let deploymentParameters = {
    properties: {
      parameters: parameter,
      template: template,
      mode: "Incremental" as DeploymentMode,
    },
  };
  const resourceGroupName = process.env.RESOURCE_GROUP_NAME;
  if (!resourceGroupName) {
    throw new Error(
      "RESOURCE_GROUP_NAME not found in environment. Please add RESOURCE_GROUP_NAME='myExistingResourceName' in .env file and try again"
    );
  }
  const deploymentName = "TeamsFxToolkitDeployment";
  try {
    const result = await client.deployments.createOrUpdate(
      resourceGroupName,
      deploymentName,
      deploymentParameters
    );
    console.log(
      `Successfully deploy arm template to resource group ${resourceGroupName}.`
    );
    return result;
  } catch (err) {
    console.log(
      `Fail to deploy arm template to resource group ${resourceGroupName}. Error message: ${err.message}`
    );
  }
}

main().catch((err) => {
  console.log(err.message);
});
