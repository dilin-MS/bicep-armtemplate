
{{#contains 'aad' pluginTypes}}
{{#contains 'frontend_hosting' pluginTypes}}
{{#notContains 'bot' pluginTypes}}
var applicationIdUri = 'api://${__frontendHostingDeploy__.outputs.domain}/${AADClientId}'
{{/notContains}}
{{#contains 'bot' pluginTypes}}
var applicationIdUri = 'api://${__frontendHostingDeploy__.outputs.domain}/botid-${AADClientId}'
{{/contains}}
{{/contains}}
{{#notContains 'frontend_hosting' pluginTypes}}
{{#contains 'bot' pluginTypes}}
var applicationIdUri = 'api://${__botDeploy__.outputs.domain}/botid-${AADClientId}'
{{/contains}}
{{/notContains}}
{{/contains}}
