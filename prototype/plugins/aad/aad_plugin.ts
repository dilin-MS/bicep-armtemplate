
import * as fs from "fs";
import { PluginTypes, PluginBicepSnippet } from "../../models";
import * as path from "path";
import * as utils from "../../utils";


export interface AADInfo {
    clientId: string;
    clientSecret: string;
  }
  
/**
 * AAD plugin create app registration and return information of the AAD app.
 */
export function createAADApp(): AADInfo {
    // hard-code here
    return {
        clientId: '40beaf37-3903-494d-92b8-3ecbf5d68546',
        clientSecret: 'xxx'
    }
}

export function calculateApplicationIdUri(domain: string, clientId: string): string {
    return `api://${domain}/${clientId}`;
}

export function generateBicepFile(context: any): PluginBicepSnippet {
    // generate bicep code snippet
    const templateDir = path.join(__dirname, '..', '..', '..', 'plugins', 'aad', 'templates');
    const inputParamsFilePath = path.join(templateDir, 'main.input_param.bicep');
    const parameterFilePath = path.join(templateDir, 'parameter.json');
    
    const variablesTemplateFilePath = path.join(templateDir, 'main.variables.template.bicep');
    const variablesCodeSnippet = utils.generateBicepFiles(variablesTemplateFilePath, context);

    let result: PluginBicepSnippet = {
        PluginTypes: PluginTypes.AAD,
        MainInputParams: fs.readFileSync(inputParamsFilePath, "utf8"),
        MainVars: variablesCodeSnippet,
        Parameter: JSON.parse(fs.readFileSync(parameterFilePath, "utf8")),
    };

    return result;
}