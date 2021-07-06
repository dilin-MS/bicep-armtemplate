import * as Handlebars from "handlebars";
import * as fs from "fs";
import * as util from "util";
const exec = util.promisify(require("child_process").exec);

Handlebars.registerHelper("contains", function( value, array, options ){
	array = ( array instanceof Array ) ? array : [array];
	return (array.indexOf(value) > -1) ? options.fn( this ) : "";
});
Handlebars.registerHelper("notContains", function( value, array, options ){
	array = ( array instanceof Array ) ? array : [array];
	return (array.indexOf(value) == -1) ? options.fn( this ) : "";
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
  return updatedBicepFile;
}

export function ensureDirectoryExists(directory: string): void {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, { recursive: true });
  }
}
