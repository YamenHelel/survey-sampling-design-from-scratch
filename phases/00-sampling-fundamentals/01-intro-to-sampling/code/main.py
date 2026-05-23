# ============================================================
# Lesson 0.1: Verifying Unbiasedness via Simulation
# Python — From Scratch (No specialized libraries)
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(42)

# --- Generate a small population ---
N = 10000
population_income = np.random.lognormal(mean=7.5, sigma=0.9, size=N)

# True population parameter
theta = np.mean(population_income)
print(f"True population mean (theta): {theta:.4f}")

# --- Repeated sampling experiment ---
n = 200
B = 5000

estimates = np.zeros(B)

for b in range(B):
    idx = np.random.choice(N, size=n, replace=False)
    sample_data = population_income[idx]
    estimates[b] = np.mean(sample_data)

# --- Verify unbiasedness ---
expected_value = np.mean(estimates)
bias = expected_value - theta
variance_est = np.var(estimates, ddof=1)
mse = variance_est + bias**2

print(f"\n--- Simulation Results (B = {B}) ---")
print(f"E(theta_hat)   : {expected_value:.4f}")
print(f"theta (true)   : {theta:.4f}")
print(f"Bias           : {bias:.4f}")
print(f"Variance       : {variance_est:.4f}")
print(f"MSE            : {mse:.4f}")

# --- Theoretical variance under SRSWOR ---
S2 = np.var(population_income, ddof=1)
theoretical_var = (1 - n / N) * S2 / n
print(f"\nTheoretical Var: {theoretical_var:.4f}")
print(f"Simulated Var  : {variance_est:.4f}")
print(f"Ratio          : {variance_est / theoretical_var:.4f} (should be ~1.0)")

# Assertion
assert abs(bias) < 0.5 * np.sqrt(theoretical_var), "Bias too large!"
print("\n[PASS] Unbiasedness verified.")

# ============================================================
# Production: samplics / weighted estimation comparison
# ============================================================

population_df = pd.DataFrame({
    'id': range(1, N + 1),
    'income': population_income
})

sample_df = population_df.sample(n=n, random_state=42).copy()
sample_df['weight'] = N / n

manual_mean = sample_df['income'].mean()
weighted_mean = np.average(sample_df['income'], weights=sample_df['weight'])

print(f"\nManual mean   : {manual_mean:.4f}")
print(f"Weighted mean : {weighted_mean:.4f}")

assert abs(manual_mean - weighted_mean) < 1e-10
print("[PASS] Manual and weighted estimates match.")
