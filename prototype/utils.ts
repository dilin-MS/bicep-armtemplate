const { exec } = require("child_process");
import * as Handlebars from "handlebars";
import * as fs from "fs";

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


export async function executeCommand(command: string, callback): Promise<void> {
  console.log(`Executing command: ${command}`);

  await exec(command, (err, stdout, stderr) => {
    if (err) {
      throw err;
    }
    callback(stdout);
  });
}

export async function generateBicepFiles(
  templateFilePath: string,
  destFilePath: string,
  pluginsContext: any
): Promise<void> {
  const templateString = fs.readFileSync(templateFilePath, "utf8");
  let template = Handlebars.compile(templateString);

  let updatedBicepFile = template(pluginsContext);
  fs.writeFileSync(destFilePath, updatedBicepFile);

  console.log(`Successfully generate ${destFilePath}`);
}

export function ensureDirectoryExists(directory: string): void {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, { recursive: true });
  }
}