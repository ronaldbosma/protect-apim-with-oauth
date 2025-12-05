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
    public async Task RetrieveAccessTokenForValidClientAndCallProtectedApi()
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

        // Call GET on Protected API with token and assert that a 200 OK is returned
        var getResponse = await apimClient.GetAsync("protected");
        Assert.AreEqual(HttpStatusCode.OK, getResponse.StatusCode, "Unexpected status code returned");

        // Call POST on Protected API with token and assert that a 200 OK is returned
        var postResponse = await apimClient.PostAsync("protected", null);
        Assert.AreEqual(HttpStatusCode.OK, postResponse.StatusCode, "Unexpected status code returned");

        // Call DELETE on Protected API with token and assert that a 401 Unauthorized is returned
        var deleteResponse = await apimClient.DeleteAsync("protected");
        Assert.AreEqual(HttpStatusCode.Unauthorized, deleteResponse.StatusCode, "Unexpected status code returned");
    }

    /// <summary>
    /// Tests that an invalid unauthorized client cannot retrieve an access token from Entra ID.
    /// </summary>
    [TestMethod]
    public async Task RetrieveAccessTokenForInvalidClientAndCallProtectedApi()
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

        // Get access token using MSAL
        var act = async () => await app.AcquireTokenForClient([$"{config.OAuthTargetResource}/.default"]).ExecuteAsync();

        // Assert that the correct exception is returned indicating that the client does not have access
        var exception = await Assert.ThrowsExactlyAsync<MsalUiRequiredException>(act);
        Assert.AreEqual("invalid_grant", exception.ErrorCode, "Unexpected error code");
        Assert.AreEqual(400, exception.StatusCode, "Unexpected status code");
        StringAssert.Contains(exception.Message, "is not assigned to a role for the application", "Unexpected exception message");
    }

    /// <summary>
    /// Tests that a 401 Unauthorized is returned if no Authorization is provided when calling the Protected API.
    /// </summary>
    [TestMethod]
    public async Task CallProtectedApiWithoutAuthorizationHeader()
    {
        var config = TestConfiguration.Load();

        var apimClient = new IntegrationTestHttpClient(config.AzureApiManagementGatewayUrl);
        apimClient.DefaultRequestHeaders.Authorization = null;

        // Call GET on Protected API with token and assert that a 401 Unauthorized is returned
        var getResponse = await apimClient.GetAsync("protected");
        Assert.AreEqual(HttpStatusCode.Unauthorized, getResponse.StatusCode, "Unexpected status code returned");

        // Call POST on Protected API with token and assert that a 401 Unauthorized is returned
        var postResponse = await apimClient.PostAsync("protected", null);
        Assert.AreEqual(HttpStatusCode.Unauthorized, postResponse.StatusCode, "Unexpected status code returned");

        // Call DELETE on Protected API with token and assert that a 401 Unauthorized is returned
        var deleteResponse = await apimClient.DeleteAsync("protected");
        Assert.AreEqual(HttpStatusCode.Unauthorized, deleteResponse.StatusCode, "Unexpected status code returned");
    }
}
