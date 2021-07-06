import * as fs from "fs";
import { PluginTypes, PluginBicepSnippet } from "../../models";
import * as path from "path";

export function generateBicepFile(): PluginBicepSnippet {
  const templateDir = path.join(
    __dirname,
    "..",
    "..",
    "..",
    "plugins",
    "azure_sql",
    "templates"
  );

  const resourcesFilePath = path.join(templateDir, "azure_sql.bicep");
  const inputParamsFilePath = path.join(templateDir, "main.input_param.bicep");
  const modulesFilePath = path.join(templateDir, "main.modules.bicep");
  const outputFilePath = path.join(templateDir, "main.output.bicep");
  const parameterFilePath = path.join(templateDir, "parameter.json");

  let result: PluginBicepSnippet = {
    PluginTypes: PluginTypes.AzureSql,
    PluginResources: fs.readFileSync(resourcesFilePath, "utf8"),
    MainInputParams: fs.readFileSync(inputParamsFilePath, "utf8"),
    MainModules: fs.readFileSync(modulesFilePath, "utf8"),
    MainOutput: fs.readFileSync(outputFilePath, "utf8"),
    Parameter: JSON.parse(fs.readFileSync(parameterFilePath, "utf8")),
  };
  return result;
}
