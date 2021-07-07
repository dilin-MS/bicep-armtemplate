import * as fs from "fs";
import { PluginTypes, PluginBicepSnippet } from "../../models";
import * as path from "path";
import * as utils from "../../utils";

export function generateBicepFile(context: any): PluginBicepSnippet {
  const templateDir = path.join(
    __dirname,
    "..",
    "..",
    "..",
    "plugins",
    "function",
    "templates"
  );

  const resourcesTemplateFilePath = path.join(
    templateDir,
    "function.template.bicep"
  );
  const resources = utils.generateBicepFiles(
    resourcesTemplateFilePath,
    context
  );

  const inputParamsFilePath = path.join(
    templateDir,
    "main.input_param.template.bicep"
  );
  const intputParams = utils.generateBicepFiles(inputParamsFilePath, context);

  const modulesTemplateFilePath = path.join(templateDir, "main.modules.template.bicep");
  const modules = utils.generateBicepFiles(modulesTemplateFilePath, context);

  const outputFilePath = path.join(templateDir, "main.output.bicep");

  let result: PluginBicepSnippet = {
    PluginTypes: PluginTypes.Function,
    PluginResources: resources,
    MainInputParams: intputParams,
    MainModules: modules,
    MainOutput: fs.readFileSync(outputFilePath, "utf8"),
  };
  return result;
}
