using IntegrationTests.Clients;
using IntegrationTests.Configuration;
using Microsoft.Identity.Client;
using System.Net;
using System.Net.Http.Headers;

namespace IntegrationTests;

/// <summary>
/// Tests scenarios for a valid authorized client and invalid unauthorized client.
/// </summary>
[TestClass]
public sealed class ClientTests
{
    /// <summary>
    /// Tests that a valid authorized client can retrieve an access token from Entra ID,
    /// and successfully call GET and POST endpoints on the protected API, while DELETE
    /// requests return 401 Unauthorized as expected.
    /// </summary>
    [TestMethod]
    public async Task RetrieveAccessTokenForValidClientAndCallPortectedApi()
    {
        var config = TestConfiguration.Load();

        // Get client secret from Key Vault
        var keyVaultClient = new KeyVaultClient(config.AzureKeyVaultUri);
        var clientSecret = await keyVaultClient.GetSecretValueAsync("valid-client-secret");

        // Get access token using MSAL
        var app = ConfidentialClientApplicationBuilder
            .Create(config.ValidClientId)
            .WithClientSecret(clientSecret)
            .WithAuthority(new Uri($"https://login.microsoftonline.com/{config.AzureTenantId}"))
            .Build();
        var result = await app.AcquireTokenForClient([$"{config.OAuthTargetResource}/.default"]).ExecuteAsync();

        var apimClient = new IntegrationTestHttpClient(config.AzureApiManagementGatewayUrl);
        apimClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", result.AccessToken);

        // Call GET on Protected API with token and verify that a 200 OK is returned
        var getResponse = await apimClient.GetAsync("protected");
        Assert.AreEqual(HttpStatusCode.OK, getResponse.StatusCode, "Unexpected status code returned");

        // Call POST on Protected API with token and verify that a 200 OK is returned
        var postResponse = await apimClient.PostAsync("protected", null);
        Assert.AreEqual(HttpStatusCode.OK, postResponse.StatusCode, "Unexpected status code returned");

        // Call DELETE on Protected API with token and verify that a 401 Unauthorized is returned
        var deleteResponse = await apimClient.DeleteAsync("protected");
        Assert.AreEqual(HttpStatusCode.Unauthorized, deleteResponse.StatusCode, "Unexpected status code returned");
    }

    /// <summary>
    /// Tests that an invalid unauthorized client cannot retrieve an access token from Entra ID.
    /// </summary>
    [TestMethod]
    public async Task RetrieveAccessTokenForInvalidClientAndCallPortectedApi()
    {
        var config = TestConfiguration.Load();

        // Get client secret from Key Vault
        var keyVaultClient = new KeyVaultClient(config.AzureKeyVaultUri);
        var clientSecret = await keyVaultClient.GetSecretValueAsync("invalid-client-secret");

        // Get access token using MSAL
        var app = ConfidentialClientApplicationBuilder
            .Create(config.InvalidClientId)
            .WithClientSecret(clientSecret)
            .WithAuthority(new Uri($"https://login.microsoftonline.com/{config.AzureTenantId}"))
            .Build();

        // Get access token using MSAL and verify that it failed
        var act = async () => await app.AcquireTokenForClient([$"{config.OAuthTargetResource}/.default"]).ExecuteAsync();
        await Assert.ThrowsExactlyAsync<MsalUiRequiredException>(act);
    }
}
