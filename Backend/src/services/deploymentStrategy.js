const featureFlags = require('../config/featureFlags');

class DeploymentStrategy {
  constructor() {
    this.canaryWeight = 0; // default 0% canary traffic routing weight
  }

  /**
   * Set canary traffic routing splits (5%, 10%, 25%, 50%, 100%) (Vol 9)
   */
  setCanaryWeight(weight) {
    if (!featureFlags.ENABLE_CANARY_DEPLOYMENT) {
      throw new Error('Canary deployments are disabled by feature flags.');
    }
    const validWeights = [0, 5, 10, 25, 50, 100];
    if (!validWeights.includes(weight)) {
      throw new Error(`Invalid canary deployment weight split: ${weight}`);
    }
    this.canaryWeight = weight;
    console.log(`🌐 DeploymentStrategy: Traffic route configured. Canary: ${weight}%, Baseline: ${100 - weight}%`);
    return this.canaryWeight;
  }

  /**
   * Evaluates if a request should route to the canary cluster or baseline
   */
  shouldRouteToCanary() {
    if (this.canaryWeight === 0) return false;
    const roll = Math.random() * 100;
    return roll < this.canaryWeight;
  }
}

module.exports = new DeploymentStrategy();
