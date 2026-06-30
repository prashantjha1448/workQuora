const featureFlags = require('../config/featureFlags');

class AIProvider {
  constructor() {
    this.primaryProvider = process.env.AI_PROVIDER || 'mock';
    this.timeoutMs = Number(process.env.AI_TIMEOUT) || 5000;
    this.maxRetries = 2;
  }

  /**
   * Sanitizes input prompts to prevent leakages of emails, phones, or keys
   */
  _sanitizePrompt(prompt) {
    if (typeof prompt !== 'string') return prompt;
    // Simple sanitization regexes for demonstration / Vol 11
    let sanitized = prompt;
    sanitized = sanitized.replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '[REDACTED_EMAIL]');
    sanitized = sanitized.replace(/\+?\d{10,13}/g, '[REDACTED_PHONE]');
    sanitized = sanitized.replace(/AI_KEY_[A-Za-z0-9]+/g, '[REDACTED_KEY]');
    return sanitized;
  }

  /**
   * Executed logic wraps timeouts, retries, and fallbacks
   */
  async _executeWithControls(provider, actionFn) {
    if (!featureFlags.ENABLE_AI && provider !== 'mock') {
      throw new Error('AI Engine is disabled via feature flags.');
    }

    let lastError;
    let currentProvider = provider;

    // List of providers to loop through on failure cascade
    const providersCascade = [currentProvider, 'gemini', 'openai', 'mock'].filter((v, i, a) => a.indexOf(v) === i);

    for (const activeProv of providersCascade) {
      for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
        try {
          console.log(`🤖 AIProvider: Executing on "${activeProv}" (Attempt ${attempt + 1})`);
          
          // Wrap action execution in timeout Promise
          const result = await Promise.race([
            actionFn(activeProv),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error('AI Request Timeout')), this.timeoutMs)
            ),
          ]);

          // Log transaction costs metric hooks (stub)
          console.log(`📊 AIProvider Cost Metric: 1 query executed successfully on "${activeProv}"`);
          return result;
        } catch (err) {
          lastError = err;
          console.warn(`⚠️ AIProvider: Attempt failed on "${activeProv}": ${err.message}`);
          // If it was a rate limit or transient error, delay retry
          await new Promise(r => setTimeout(r, 200 * (attempt + 1)));
        }
      }
      console.warn(`🚨 AIProvider: Cascade falling back from "${activeProv}" to next available provider`);
    }

    throw new Error(`AI Execution failed across all fallback providers. Last error: ${lastError?.message}`);
  }

  // ── Abstraction API Methods ────────────────────────────────────────────────

  async generate(prompt) {
    const cleanPrompt = this._sanitizePrompt(prompt);
    return this._executeWithControls(this.primaryProvider, async (provider) => {
      if (provider === 'mock') {
        if (cleanPrompt.toLowerCase().includes('json array')) {
          return '["plumber", "appliance repair"]';
        }
        return `[Mock AI Response for: ${cleanPrompt.slice(0, 30)}...]`;
      }
      if (provider === 'gemini') {
        const { GoogleGenerativeAI } = require('@google/generative-ai');
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'dummy_key');
        const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
        const result = await model.generateContent(cleanPrompt);
        return result.response.text();
      }
      // Stub connections for OpenAI and Anthropic to keep them import independent
      return `[${provider.toUpperCase()} stub response for prompt]`;
    });
  }

  async summarize(text) {
    return this.generate(`Summarize the following text concisely:\n\n${text}`);
  }

  async classify(text, categories = []) {
    return this.generate(`Classify this text into one of these categories: [${categories.join(', ')}]. Output only the category name: "${text}"`);
  }

  async extract(text, schemaDescription) {
    return this.generate(`Extract data from this text according to the schema: ${schemaDescription}. Text: "${text}"`);
  }

  async embed(text) {
    return this._executeWithControls(this.primaryProvider, async (provider) => {
      if (provider === 'mock') {
        return new Array(1536).fill(0).map(() => Math.random());
      }
      return [0.1, 0.2, 0.3]; // mock embedding array fallback
    });
  }
}

module.exports = new AIProvider();
