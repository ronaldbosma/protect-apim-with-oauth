# The Azure Developer CLI doesn't support deleting Entra ID resources yet, so we have to do it in a hook.
# Related GitHub issue: https://github.com/Azure/azure-dev/issues/4724

function Remove-Application($uniqueName) {
    $app = az ad app list | ConvertFrom-Json | Where-Object { $_.uniqueName -eq $uniqueName }

    if ($app) {
        Write-Host "Deleting service principal $($app.appId) of application with unique name $uniqueName"
        az ad sp delete --id $app.appId

        Write-Host "Deleting application $($app.appId) with unique name $uniqueName"
        az ad app delete --id $app.appId
    } else {
        Write-Host "Unable to delete application with unique name $uniqueName. Application not found."
    }
}


Remove-Application $env:ENTRA_ID_APIM_APPLICATION_NAME
Remove-Application $env:ENTRA_ID_APIM_CLIENT_NAME
