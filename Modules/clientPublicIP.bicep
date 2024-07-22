resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'inlinePS'
  location: az.resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '10.0'
    scriptContent: '''
      Write-Host 'Getting Client Public IP'
      $output = (Invoke-WebRequest ifconfig.me/ip).Content.Trim()
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['ip'] = $output
    '''
    retentionInterval: 'PT1H'
  }
}

output clientIP string = deploymentScript.properties.outputs.ip
