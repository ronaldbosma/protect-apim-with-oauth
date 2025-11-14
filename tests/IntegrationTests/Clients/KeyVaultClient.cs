using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace IntegrationTests.Clients;

/// <summary>
/// Provides a client for interacting with Azure Key Vault to retrieve secrets.
/// </summary>
internal class KeyVaultClient
{
    private readonly SecretClient _secretClient;

    /// <summary>
    /// Creates an instance of <see cref="KeyVaultClient"/> to interact with the specified Key Vault.
    /// </summary>
    /// <param name="keyVaultUri">The URI of the Azure Key Vault instance.</param>
    public KeyVaultClient(Uri keyVaultUri)
    {
        _secretClient = new SecretClient(keyVaultUri, new DefaultAzureCredential());
    }

    /// <summary>
    /// Retrieves the value of a secret from Azure Key Vault asynchronously.
    /// Automatically handles base64-encoded secrets by checking for an "encoding=base64" tag.
    /// </summary>
    /// <param name="secretName">The name of the secret to retrieve.</param>
    /// <returns>The decoded value of the secret as a UTF-8 string.</returns>
    public async Task<string> GetSecretValueAsync(string secretName)
    {
        var secret = await _secretClient.GetSecretAsync(secretName);

        // Check if the secret has a tag indicating it's base64 encoded
        // This allows storing binary data or special characters in Key Vault secrets
        if (secret.Value.Properties.Tags.Any(tag => tag.Key == "encoding" && tag.Value == "base64"))
        {
            // Decode the base64 string and convert to UTF-8 text
            var decodedBytes = Convert.FromBase64String(secret.Value.Value);
            return System.Text.Encoding.UTF8.GetString(decodedBytes);
        }

        // Return the secret value as-is if no base64 encoding is indicated
        return secret.Value.Value;
    }
}
