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
    "identity",
    "templates"
  );

  const resourcesFilePath = path.join(templateDir, "identity.bicep");
  const inputParamsFilePath = path.join(templateDir, "main.input_param.bicep");
  const modulesFilePath = path.join(templateDir, "main.modules.bicep");
  const outputFilePath = path.join(templateDir, "main.output.bicep");

  let result: PluginBicepSnippet = {
    PluginTypes: PluginTypes.Identity,
    PluginResources: fs.readFileSync(resourcesFilePath, "utf8"),
    MainInputParams: fs.readFileSync(inputParamsFilePath, "utf8"),
    MainModules: fs.readFileSync(modulesFilePath, "utf8"),
    MainOutput: fs.readFileSync(outputFilePath, "utf8"),
  };
  return result;
}
