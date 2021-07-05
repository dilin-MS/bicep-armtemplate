import * as Handlebars from "handlebars";
import * as fs from "fs";
import * as util from "util";
const exec = util.promisify(require("child_process").exec);

Handlebars.registerHelper('if_equal', function(conditional, value, options) {
  if (conditional === value){
    return options.fn(this);
  } else {
    return options.inverse(this);
  }
});

Handlebars.registerHelper('ifIn', function(elem, list, options) {
  if(list.indexOf(elem) > -1) {
    return options.fn(this);
  }
  return options.inverse(this);
});

Handlebars.registerHelper('ifNotIn', function(elem, list, options) {
  if(list.indexOf(elem) == -1) {
    return options.fn(this);
  }
  return options.inverse(this);
});


export async function executeCommand(command: string): Promise<any> {
  console.log(`Executing command: ${command}`);

  const {stdout, stderr} = await exec(command);
  return stdout;
}

export function generateBicepFiles(
  templateFilePath: string,
  pluginsContext: any
): string {
  const templateString = fs.readFileSync(templateFilePath, "utf8");
  let template = Handlebars.compile(templateString);

  let updatedBicepFile = template(pluginsContext);
  // console.log(`Successfully updated bicep file: ${templateFilePath}`);

  return updatedBicepFile;
}

export function ensureDirectoryExists(directory: string): void {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, { recursive: true });
  }
}
