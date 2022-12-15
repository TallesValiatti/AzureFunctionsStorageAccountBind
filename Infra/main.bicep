// az group create -n rg-order-app-eastus -l eastus
// az deployment group create --resource-group  rg-order-app-eastus --template-file main.bicep
// az group delete -n rg-order-app-eastus

// Default Location
param defaultLocation string = resourceGroup().location

// Shared Variables
var regionPlaceholder = '<REGION>'
var workFlowPlaceholder = '<WORKFLOW>'
var storageAccountDefaultName = 'st${workFlowPlaceholder}${regionPlaceholder}'
var applicationInsightsDefaultName = 'appi-${workFlowPlaceholder}-${regionPlaceholder}'
var functionDefaultName = 'func-${workFlowPlaceholder}-${regionPlaceholder}'
var appServicePlanDefaultName = 'asp-${workFlowPlaceholder}-${regionPlaceholder}'

// Workflow
var workflowName = 'order-app'

// Storage Account
var storageAccountName = replace(replace(replace(storageAccountDefaultName,regionPlaceholder, defaultLocation), workFlowPlaceholder, workflowName), '-', '')
var storageAccountType = 'Standard_LRS'
var storageAccountQueueName = 'order-queue'

// Applicantion Insights
var applicationInsightsName = replace(replace(applicationInsightsDefaultName, workFlowPlaceholder, workflowName), regionPlaceholder, defaultLocation)

// Azure Function
var funcName = replace(replace(functionDefaultName, workFlowPlaceholder, workflowName), regionPlaceholder, defaultLocation)
var applicationServicePlanName = replace(replace(appServicePlanDefaultName, workFlowPlaceholder, workflowName), regionPlaceholder, defaultLocation)
var funcRuntime =  'dotnet'
var funcSkuName = 'Y1'
var funcSkuType = 'Dynamic'

// Resource -> Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: defaultLocation
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

// Resource -> Storage Account Queue
resource storageAccountQueues 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  name: 'default'
  parent: storageAccount  
}

resource symbolicname 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-05-01' = {
  name: storageAccountQueueName
  parent: storageAccountQueues
  properties: {
    metadata: {}
  }
}


// Resource -> Application Service Plan
resource applicationServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: applicationServicePlanName
  location: defaultLocation
  sku: {
    name: funcSkuName
    tier: funcSkuType
  }
  properties: {}
}

// Resource Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: defaultLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Resource -> Azure Function
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: funcName
  location: defaultLocation
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: applicationServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(funcName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: funcRuntime
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

// Outputs
output storageAccountName string = storageAccountName 
output applicationServicePlanName string = applicationServicePlanName 
output applicationInsightsName string = applicationInsightsName 
output funcName string = funcName 
output env string = environment().name 
