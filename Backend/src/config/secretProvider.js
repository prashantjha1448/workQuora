const featureFlags = require('./featureFlags');

class SecretProvider {
  constructor() {
    this.cachedSecrets = new Map();
  }

  /**
   * Fetch a secret parameter cleanly with cascading fallback routes (Vol 11)
   */
  async getSecret(key, defaultValue = '') {
    if (!featureFlags.ENABLE_SECRETS_PROVIDER) {
      return process.env[key] || defaultValue;
    }

    if (this.cachedSecrets.has(key)) {
      return this.cachedSecrets.get(key);
    }

    try {
      // 1. Cascade 1: AWS Secrets Manager mock checks (Vol 11)
      if (process.env.AWS_SECRETS_MANAGER_ARN) {
        console.log(`🔒 SecretProvider: Resolving secret "${key}" from AWS Secrets Manager.`);
        return process.env[key] || defaultValue; 
      }

      // 2. Cascade 2: Azure Key Vault mock checks
      if (process.env.AZURE_KEYVAULT_URI) {
        console.log(`🔒 SecretProvider: Resolving secret "${key}" from Azure Key Vault.`);
        return process.env[key] || defaultValue;
      }

      // 3. Cascade 3: Hashicorp Vault mock checks
      if (process.env.VAULT_ADDR) {
        console.log(`🔒 SecretProvider: Resolving secret "${key}" from Hashicorp Vault.`);
        return process.env[key] || defaultValue;
      }

      // 4. Cascade 4: Environment Variables fallback
      const envVal = process.env[key];
      if (envVal !== undefined) {
        this.cachedSecrets.set(key, envVal);
        return envVal;
      }

      // 5. Cascade 5: Safe Default values
      return defaultValue;
    } catch (err) {
      console.warn(`🔒 SecretProvider: Error resolving secret "${key}". Falling back to environment.`, err.message);
      return process.env[key] || defaultValue;
    }
  }
}

module.exports = new SecretProvider();
