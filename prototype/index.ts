import * as fs from "fs";
import * as path from "path";
import * as utils from "./utils";
import { PluginTypes, PluginBicepSnippet } from "./api";
import * as AADPlugin from "./plugins/aad/aad_plugin";
import * as FrontendHostingPlugin from "./plugins/frontend_hosting/frontend_hosting_plugin";
import * as FunctionPlugin from "./plugins/function/function_plugin";
import * as SimpleAuthPlugin from "./plugins/simple_auth/simple_auth_plugin";
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
const mainFilePath = path.join(bicepFilesDir, "main.bicep");

/**
 * This Main function prototypes what solution plugin does.
 */
async function main() {
  const pluginTypes = [
    PluginTypes.AAD,
    PluginTypes.FrontendHosting,
    PluginTypes.Function,
    PluginTypes.SimpleAuth,
  ];
  await generateBicepFiles(pluginTypes);

  const deploymentResult = await deployArmTemplateToAzure(bicepFilesDir);

  const frontendHosting_connectionString =
    deploymentResult.properties.outputs.frontendHosting_connectionString.value;
  executeDataPlaneOperation(frontendHosting_connectionString);
}

/**
 * Create AAD App Registration and get clientId, clientSecret
 */
async function generateBicepFiles(pluginTypes: PluginTypes[]): Promise<void> {
  utils.ensureDirectoryExists(bicepFilesDir);

  // Create AAD App
  const aadInfo: AADPlugin.AADInfo = AADPlugin.createAADApp();

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
      default:
    }
  }

  // plugin resources
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
        `Successfully generate resource bicep file: ${pluginResourceDestFilePath}`
      );
    }
  });

  // main.bicep
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
  const mainFilePath = path.join(bicepFilesDir, `main.bicep`);
  fs.writeFileSync(mainFilePath, mainTemplate);

  // parameter.json
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
  fs.writeFileSync(parameterFilePath, JSON.stringify(parameters));

  updateEnvParameterValues(aadInfo.clientId, aadInfo.clientSecret);

  updateModuleNames(mainFilePath);
}

function updateModuleNames(filePath: string) {
  const moduleNames = {
    __simpleAuthDeploy__: "simpleAuthDeploy",
    __functionDeploy__: "functionDeploy",
    __frontendHostingDeploy__: "frontendHostingDeploy",
  };
  let fileString = fs.readFileSync(filePath, 'utf8');
  for (let key in moduleNames) {
    let value = moduleNames[key];
    fileString = fileString.replace(new RegExp(key, 'g'), value);
  }
  fs.writeFileSync(filePath, fileString);
}

function updateEnvParameterValues(
  clientId: string,
  clientSecret: string,
) {
  const aad_context = {
    TENANT_ID: process.env.TENANT_ID,
    CLIENT_ID: clientId,
    CLIENT_SECRET: clientSecret,
    RESOURCE_GROUP_NAME: process.env.RESOURCE_GROUP_NAME,
    SIMPLE_AUTH_SKU: process.env.SIMPLE_AUTH_SKU,
  };

  const parameters = utils.generateBicepFiles(parameterFilePath, aad_context);
  fs.writeFileSync(parameterFilePath, parameters);
}

function executeDataPlaneOperation(
  connectionString: string
): void {
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

async function deployArmTemplateToAzure(
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
