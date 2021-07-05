import * as fs from "fs";
import { PluginTypes, PluginBicepSnippet } from "../../api";
import * as path from "path";
import * as utils from "../../utils";

export function generateBicepFile(context: any): PluginBicepSnippet {
  const templateDir = path.join(
    __dirname,
    "..",
    "..",
    "..",
    "plugins",
    "simple_auth",
    "templates"
  );

  const resourcesTemplateFilePath = path.join(
    templateDir,
    "simple_auth.template.bicep"
  );
  const resources = utils.generateBicepFiles(resourcesTemplateFilePath, context);

  const inputParamsFilePath = path.join(templateDir, "main.input_param.bicep");
  
  const modulesTemplateFilePath = path.join(templateDir, "main.modules.template.bicep");
  const modules = utils.generateBicepFiles(modulesTemplateFilePath, context);

  const outputFilePath = path.join(templateDir, "main.output.bicep");
  const parameterFilePath = path.join(templateDir, "parameter.json");

  let result: PluginBicepSnippet = {
    PluginTypes: PluginTypes.SimpleAuth,
    PluginResources: resources,
    MainInputParams: fs.readFileSync(inputParamsFilePath, "utf8"),
    MainModules: modules,
    MainOutput: fs.readFileSync(outputFilePath, "utf8"),
    Parameter: JSON.parse(fs.readFileSync(parameterFilePath, "utf8")),
  };
  return result;
}
