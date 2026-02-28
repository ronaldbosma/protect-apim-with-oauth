using Microsoft.Extensions.Configuration;

namespace IntegrationTests.Configuration;

/// <summary>
/// Contains configuration settings for the integration tests.
/// </summary>
internal class TestConfiguration
{
    public required string AzureTenantId { get; init; }

    public required Uri AzureApiManagementGatewayUrl { get; init; }
    public required Uri AzureKeyVaultUri { get; init; }

    public required string ValidClientId { get; set; }
    public required string InvalidClientId { get; set; }
    public required string OAuthTargetResource { get; init; }

    public static TestConfiguration Load()
    {
        AzdDotEnv.Load(optional: true); // Loads Azure Developer CLI environment variables; optional since .env file might be missing in CI/CD pipelines

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        return new TestConfiguration
        {
            AzureTenantId = configuration.GetRequiredString("AZURE_TENANT_ID"),
            AzureApiManagementGatewayUrl = configuration.GetRequiredUri("AZURE_API_MANAGEMENT_GATEWAY_URL"),
            AzureKeyVaultUri = configuration.GetRequiredUri("AZURE_KEY_VAULT_URI"),
            ValidClientId = configuration.GetRequiredString("ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_CLIENT_ID"),
            InvalidClientId = configuration.GetRequiredString("ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_CLIENT_ID"),
            OAuthTargetResource = configuration.GetRequiredString("ENTRA_ID_APIM_APP_REGISTRATION_IDENTIFIER_URI")
        };
    }
}