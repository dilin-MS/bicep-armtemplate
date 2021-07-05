
{{#each pluginTypes}}
{{#if_equal this 'aad'}}
{{#ifIn 'frontend_hosting' ../pluginTypes}}
{{#ifNotIn 'bot' ../pluginTypes}}
var applicationIdUri = 'api://${__frontendHostingDeploy__.outputs.domain}/${AADClientId}'
{{/ifNotIn}}
{{#ifIn 'bot' ../pluginTypes}}
var applicationIdUri = 'api://${__frontendHostingDeploy__.outputs.domain}/botid-${AADClientId}'
{{/ifIn}}
{{/ifIn}}
{{#ifNotIn 'frontend_hosting' ../pluginTypes}}
{{#ifIn 'bot' ../pluginTypes}}
var applicationIdUri = 'api://${__botDeploy__.outputs.domain}/botid-${AADClientId}'
{{/ifIn}}
{{/ifNotIn}}
{{/if_equal}}
{{/each}}
