# The Azure Developer CLI doesn't support deleting Entra ID resources yet, so we have to do it in a hook.
# Related GitHub issue: https://github.com/Azure/azure-dev/issues/4724

function Remove-ApplicationAndServicePrincipal($uniqueName) {
    # Get the application with the unique name
    $app = az ad app list | ConvertFrom-Json | Where-Object { $_.uniqueName -eq $uniqueName }

    if ($app) {
        # Get the service principal of the application
        $sp = az ad sp list --all | ConvertFrom-Json | Where-Object { $_.appId -eq $app.appId }
        
        if ($sp) {
            Write-Host "Deleting service principal $($app.id) of application with unique name $uniqueName"
            # Delete the service principal (moves the service principal to the deleted items)
            az ad sp delete --id $sp.id
            # Permanently delete the service principal. If we don't do this, we can't create a new service principal with the same name.
            az rest --method DELETE --url "https://graph.microsoft.com/beta/directory/deleteditems/$($sp.id)"
        }
        else {
            Write-Host "Unable to delete service princpal for application with unique name $uniqueName. Service principal not found."
        }

        Write-Host "Deleting application $($app.appId) with unique name $uniqueName"
        # Delete the application (moves the application to the deleted items)
        az ad app delete --id $app.id
        # Permanently delete the application. If we don't do this, we can't create a new application with the same name.
        az rest --method DELETE --url "https://graph.microsoft.com/beta/directory/deleteditems/$($app.id)"

    } else {
        Write-Host "Unable to delete application with unique name $uniqueName. Application not found."
    }
}


Remove-ApplicationAndServicePrincipal $env:ENTRA_ID_APIM_APPLICATION_NAME
Remove-ApplicationAndServicePrincipal $env:ENTRA_ID_APIM_CLIENT_NAME