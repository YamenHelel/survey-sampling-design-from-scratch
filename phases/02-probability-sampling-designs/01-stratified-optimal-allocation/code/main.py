# ============================================================
# Lesson 2.1: Stratified Random Sampling & Optimal Allocation
# Python — From Scratch (No specialized libraries)
# ============================================================

import numpy as np

np.random.seed(2024)

# --- Stratum parameters ---
strata = {
    'GOV_01': {'N': 200000, 'mean': 2500, 'sd': 1500},
    'GOV_02': {'N': 80000,  'mean': 1200, 'sd': 400},
    'GOV_03': {'N': 70000,  'mean': 1000, 'sd': 300},
    'GOV_04': {'N': 100000, 'mean': 1800, 'sd': 800},
    'GOV_05': {'N': 60000,  'mean': 900,  'sd': 250},
    'GOV_06': {'N': 90000,  'mean': 1500, 'sd': 600},
}

n_total = 3000
N = sum(s['N'] for s in strata.values())

# Generate population
pop_values = {}
for name, params in strata.items():
    pop_values[name] = np.maximum(0, np.random.normal(
        params['mean'], params['sd'], params['N']))

all_values = np.concatenate(list(pop_values.values()))
theta = np.mean(all_values)
print(f"True population mean: {theta:.2f}")

# Compute stratum weights and actual SDs
W_h = {k: v['N'] / N for k, v in strata.items()}
sd_h = {k: np.std(pop_values[k], ddof=1) for k in strata}

# --- Proportional Allocation ---
n_prop = {k: max(2, round(n_total * W_h[k])) for k in strata}
# Adjust
diff = n_total - sum(n_prop.values())
first_key = list(n_prop.keys())[0]
n_prop[first_key] += diff

# --- Neyman Allocation ---
numer = {k: strata[k]['N'] * sd_h[k] for k in strata}
total_numer = sum(numer.values())
n_neyman = {k: max(2, round(n_total * numer[k] / total_numer)) for k in strata}
diff = n_total - sum(n_neyman.values())
n_neyman[first_key] += diff

print("\n--- Allocation Comparison ---")
print(f"{'Stratum':<10} {'N_h':>8} {'W_h':>6} {'SD_h':>8} {'n_prop':>7} {'n_neyman':>9}")
print("-" * 55)
for k in strata:
    print(f"{k:<10} {strata[k]['N']:>8,} {W_h[k]:>6.3f} {sd_h[k]:>8.1f} "
          f"{n_prop[k]:>7} {n_neyman[k]:>9}")

# --- Simulation ---
B = 5000

def stratified_estimate(pop_vals, w_h, n_alloc):
    est = 0
    for k in pop_vals:
        idx = np.random.choice(len(pop_vals[k]), size=n_alloc[k], replace=False)
        est += w_h[k] * np.mean(pop_vals[k][idx])
    return est

est_prop = np.array([stratified_estimate(pop_values, W_h, n_prop) for _ in range(B)])
est_neyman = np.array([stratified_estimate(pop_values, W_h, n_neyman) for _ in range(B)])
est_srs = np.array([np.mean(np.random.choice(all_values, n_total, replace=False))
                     for _ in range(B)])

print(f"\n{'Method':<22} | {'E(est)':>12} | {'Variance':>12} | {'RMSE':>10}")
print("-" * 65)
for name, est in [("SRS", est_srs), ("Stratified (Prop)", est_prop),
                   ("Stratified (Neyman)", est_neyman)]:
    print(f"{name:<22} | {np.mean(est):>12.2f} | {np.var(est, ddof=1):>12.2f} | "
          f"{np.sqrt(np.mean((est - theta)**2)):>10.2f}")

gain_prop = np.var(est_srs, ddof=1) / np.var(est_prop, ddof=1)
gain_neyman = np.var(est_srs, ddof=1) / np.var(est_neyman, ddof=1)
print(f"\nGain (Proportional): {gain_prop:.2f}x")
print(f"Gain (Neyman)      : {gain_neyman:.2f}x")

assert np.var(est_neyman) <= np.var(est_prop) * 1.05
print("\n[PASS] Neyman <= Proportional variance.")
assert np.var(est_prop) <= np.var(est_srs) * 1.05
print("[PASS] Stratification improves over SRS.")
assert abs(np.mean(est_neyman) - theta) < 5
print("[PASS] Neyman estimator is unbiased.")
