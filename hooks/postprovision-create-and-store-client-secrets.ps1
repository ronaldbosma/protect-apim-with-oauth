<#
  This PowerShell script is executed after the infra resources are provisioned. 
  Currently, we can't create secrets for an app registration with Bicep.
  This script creates a client secret for each client app registration in Entra ID and stores it securely in Azure Key Vault. 
  If the client secret already exists in Key Vault, it won't create a new one.

  NOTE: secrets are stored as base64 encoded strings to avoid issues with special characters.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$ValidClientAppId = $env:ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_CLIENT_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$InvalidClientAppId = $env:ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_CLIENT_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = $env:AZURE_KEY_VAULT_NAME
)

# Validate required parameters
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    throw "SubscriptionId parameter is required. Please provide it as a parameter or set the AZURE_SUBSCRIPTION_ID environment variable."
}

if ([string]::IsNullOrEmpty($ValidClientAppId)) {
    throw "ValidClientAppId parameter is required. Please provide it as a parameter or set the ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_CLIENT_ID environment variable."
}

if ([string]::IsNullOrEmpty($InvalidClientAppId)) {
    throw "InvalidClientAppId parameter is required. Please provide it as a parameter or set the ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_CLIENT_ID environment variable."
}

if ([string]::IsNullOrEmpty($KeyVaultName)) {
    throw "KeyVaultName parameter is required. Please provide it as a parameter or set the AZURE_KEY_VAULT_NAME environment variable."
}


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


# Function to create and store client secret
function Add-ClientSecretToKeyVault {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        
        [Parameter(Mandatory = $true)]
        [string]$SecretName,
        
        [Parameter(Mandatory = $true)]
        [string]$SecretDisplayName,
        
        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName
    )
    
    # Check if the secret already exists in Key Vault and skip if it does
    Write-Host "Checking if secret '$SecretName' exists in Key Vault '$KeyVaultName'"
    $existingSecret = az keyvault secret show `
        --vault-name $KeyVaultName `
        --name $SecretName `
        --query "value" `
        --output tsv 2>$null
        
    if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrEmpty($existingSecret)) {
        Write-Host "Secret '$SecretName' already exists. Skipping creation."
        return
    }

    # Create client secret for the app registration
    # Retry if the secret starts with '-' as this can cause issues with Key Vault storage
    # See also https://github.com/Azure/azure-cli/issues/23016
    Write-Host "Creating client secret for app registration '$AppId'"
    do {
        $secretResult = az ad app credential reset `
            --id $AppId `
            --display-name $SecretDisplayName `
            --query "password" `
            --append `
            --output tsv

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create client secret for app registration: $AppId"
        }

        if ($secretResult.StartsWith('-')) {
            Write-Host "Generated secret starts with '-', regenerating..."
        }
    } while ($secretResult.StartsWith('-'))

    Write-Host "Client secret created successfully for app registration '$AppId'"

    # Store the client secret in Key Vault
    Write-Host "Storing client secret '$SecretName' in Key Vault '$KeyVaultName'"
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name $SecretName `
        --value $secretResult `
        --output none

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to store client secret '$SecretName' in Key Vault: $KeyVaultName"
    }

    Write-Host "Client secret '$SecretName' stored successfully in Key Vault"
}


# Create and store client secret for valid client app registration
Add-ClientSecretToKeyVault -AppId $ValidClientAppId -SecretName "valid-client-secret" -SecretDisplayName "Valid Client Secret" -KeyVaultName $KeyVaultName

# Create and store client secret for invalid client app registration
Add-ClientSecretToKeyVault -AppId $InvalidClientAppId -SecretName "invalid-client-secret" -SecretDisplayName "Invalid Client Secret" -KeyVaultName $KeyVaultName
