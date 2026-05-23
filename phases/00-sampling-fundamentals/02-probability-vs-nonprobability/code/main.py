# ============================================================
# Lesson 0.2: Probability vs Non-Probability Sampling
# Python — Simulation demonstrating bias in convenience sampling
# ============================================================

import numpy as np
from scipy.special import expit

np.random.seed(2024)

# --- Create population with selection bias mechanism ---
N = 100000

income = np.random.lognormal(mean=7.0, sigma=1.0, size=N)

# Internet access correlates with income
prob_online = expit(-3 + 0.5 * np.log(income))
has_internet = np.random.binomial(1, prob_online)

theta = np.mean(income)
print(f"True population mean income: {theta:.2f}")
print(f"Internet access rate: {np.mean(has_internet)*100:.1f}%")
print(f"Mean income (online only): {np.mean(income[has_internet == 1]):.2f}")
print(f"Mean income (offline): {np.mean(income[has_internet == 0]):.2f}")

# --- Simulation ---
B = 3000
n_prob = 500
n_conv = 5000

estimates_prob = np.zeros(B)
estimates_conv = np.zeros(B)

for b in range(B):
    # Method 1: SRS (Probability)
    idx_srs = np.random.choice(N, size=n_prob, replace=False)
    estimates_prob[b] = np.mean(income[idx_srs])

    # Method 2: Convenience (Online voluntary)
    online_idx = np.where(has_internet == 1)[0]
    response_prob = expit(-2 + 0.3 * np.log(income[online_idx]))
    responding = online_idx[np.random.binomial(1, response_prob).astype(bool)]

    if len(responding) >= n_conv:
        idx_conv = np.random.choice(responding, size=n_conv, replace=False)
    else:
        idx_conv = responding
    estimates_conv[b] = np.mean(income[idx_conv])

# --- Results ---
print("\n" + "=" * 60)
print("  COMPARISON: Probability vs Convenience Sampling")
print("=" * 60)

bias_prob = np.mean(estimates_prob) - theta
bias_conv = np.mean(estimates_conv) - theta

print(f"\n--- Probability Sampling (n = {n_prob}) ---")
print(f"  E(theta_hat) : {np.mean(estimates_prob):.2f}")
print(f"  Bias         : {bias_prob:.2f}")
print(f"  RMSE         : {np.sqrt(np.mean((estimates_prob - theta)**2)):.2f}")

print(f"\n--- Convenience Sampling (n = {n_conv}) ---")
print(f"  E(theta_hat) : {np.mean(estimates_conv):.2f}")
print(f"  Bias         : {bias_conv:.2f}")
print(f"  RMSE         : {np.sqrt(np.mean((estimates_conv - theta)**2)):.2f}")

print(f"\n  Bias ratio (Conv/Prob): {abs(bias_conv)/max(abs(bias_prob), 0.01):.1f}x")

# Assertions
assert abs(bias_prob) < 50, "Probability bias too large"
assert abs(bias_conv) > 100, "Convenience should show substantial bias"
print("\n[PASS] Probability sampling produces unbiased estimates.")
print("[PASS] Convenience sampling shows persistent bias.")
