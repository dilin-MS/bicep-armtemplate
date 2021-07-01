import * as path from "path";
import * as utils from "./utils";

export async function generateBicepFiles(
  templateDir: string,
  contextDir: string,
  destDir: string
): Promise<void> {
  const templateFilePath = path.join(templateDir, "simple_auth.template.bicep");
  const contextFilePath = path.join(contextDir, "simple_auth.json");
  const destBicepFilePath = path.join(destDir, "simple_auth.bicep");
  utils.generateBicepFiles(templateFilePath, contextFilePath, destBicepFilePath);
}
