using IntegrationTests.Clients;
using IntegrationTests.Configuration;

namespace IntegrationTests;

/// <summary>
/// Tests scenarios where the Unprotected API is called, which inturn calls a Protected Backend with OAuth.
/// </summary>
[TestClass]
public sealed class ValidClientTests
{

    [TestMethod]
    public async Task TestMethod()
    {
        // Act
        var config = TestConfiguration.Load();

        var keyVaultClient = new KeyVaultClient(config.AzureKeyVaultUri);
        var validClientSecret = await keyVaultClient.GetSecretValueAsync("valid-client-secret");

        var apimClient = new IntegrationTestHttpClient(config.AzureApiManagementGatewayUrl);


        // Arrange

    }
}
