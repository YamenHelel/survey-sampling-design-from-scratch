# ============================================================
# Lesson 5.2: Jackknife & Bootstrap from Scratch
# Python
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# --- Generate sample ---
H = 3
a_per_h = 25
b = 20
records = []
psu_counter = 0

for h in range(1, H + 1):
    for i in range(a_per_h):
        psu_counter += 1
        psu_mean = np.random.normal(1500 + h * 300, 200)
        for j in range(b):
            records.append({
                'stratum': h, 'psu_id': psu_counter,
                'income': max(100, np.random.normal(psu_mean, 400)),
                'weight': 500.0
            })

df = pd.DataFrame(records)
print(f"Sample: {len(df)} obs, {H} strata, {psu_counter} PSUs")


def weighted_gini(x, w):
    valid = ~(np.isnan(x) | np.isnan(w))
    x, w = x[valid], w[valid]
    order = np.argsort(x)
    x, w = x[order], w[order]
    cum_w = np.cumsum(w)
    cum_wx = np.cumsum(w * x)
    total_wx = np.sum(w * x)
    n_w = np.sum(w)
    return 1 - 2 * np.sum(w * cum_wx) / (n_w * total_wx) + \
           np.sum(w**2 * x) / (n_w * total_wx)


full_mean = np.average(df['income'], weights=df['weight'])
full_gini = weighted_gini(df['income'].values, df['weight'].values)
print(f"\nFull-sample: mean={full_mean:.2f}, Gini={full_gini:.4f}")

# --- Jackknife ---
print("\n" + "=" * 50)
print("  JACKKNIFE")
print("=" * 50)

jk_mean, jk_gini = [], []
a_total = H * a_per_h

for h in range(1, H + 1):
    h_psus = df[df['stratum'] == h]['psu_id'].unique()
    a_h = len(h_psus)

    for k, drop_psu in enumerate(h_psus):
        jk_df = df[df['psu_id'] != drop_psu].copy()
        # Rescale within stratum
        mask = jk_df['stratum'] == h
        jk_df.loc[mask, 'weight'] = jk_df.loc[mask, 'weight'] * a_h / (a_h - 1)

        jk_mean.append(np.average(jk_df['income'], weights=jk_df['weight']))
        jk_gini.append(weighted_gini(jk_df['income'].values, jk_df['weight'].values))

jk_mean = np.array(jk_mean)
jk_gini = np.array(jk_gini)

se_jk_mean = np.sqrt((a_total - 1) / a_total * np.sum((jk_mean - jk_mean.mean())**2))
se_jk_gini = np.sqrt((a_total - 1) / a_total * np.sum((jk_gini - jk_gini.mean())**2))

print(f"  JK SE(mean): {se_jk_mean:.4f}")
print(f"  JK SE(Gini): {se_jk_gini:.6f}")

# --- Bootstrap ---
print("\n" + "=" * 50)
print("  BOOTSTRAP")
print("=" * 50)

B_reps = 500
boot_mean = np.zeros(B_reps)
boot_gini = np.zeros(B_reps)

for r in range(B_reps):
    boot_w = df['weight'].values.copy()

    for h in range(1, H + 1):
        h_mask = df['stratum'].values == h
        h_psus = df.loc[h_mask, 'psu_id'].unique()
        a_h = len(h_psus)

        resampled = np.random.choice(h_psus, a_h - 1, replace=True)
        unique_r, counts = np.unique(resampled, return_counts=True)
        count_map = dict(zip(unique_r, counts))

        for p in h_psus:
            p_mask = h_mask & (df['psu_id'].values == p)
            m_star = count_map.get(p, 0)
            boot_w[p_mask] = df['weight'].values[p_mask] * (a_h / (a_h - 1)) * m_star

    active = boot_w > 0
    boot_mean[r] = np.average(df['income'].values[active], weights=boot_w[active])
    boot_gini[r] = weighted_gini(df['income'].values[active], boot_w[active])

se_boot_mean = np.std(boot_mean, ddof=1)
se_boot_gini = np.std(boot_gini, ddof=1)

print(f"  Boot SE(mean): {se_boot_mean:.4f}")
print(f"  Boot SE(Gini): {se_boot_gini:.6f}")

# --- Compare ---
print(f"\n--- Comparison ---")
print(f"  SE(mean) ratio JK/Boot: {se_jk_mean/se_boot_mean:.2f}")
print(f"  SE(Gini) ratio JK/Boot: {se_jk_gini/se_boot_gini:.2f}")

assert 0.5 < se_jk_mean / se_boot_mean < 2.0
print("\n[PASS] JK and Bootstrap are consistent.")
# ============================================================
# PRODUCTION: resampling_variance.py
# ============================================================

import numpy as np
from typing import Callable, Dict


class ResamplingVariance:
    """Compute variance via Jackknife or Bootstrap for survey data."""

    def __init__(self, data: np.ndarray, weights: np.ndarray,
                 psu_ids: np.ndarray, stratum_ids: np.ndarray):
        self.data = data
        self.weights = weights
        self.psu_ids = psu_ids
        self.stratum_ids = stratum_ids

    def jackknife(self, estimator_fn: Callable) -> Dict:
        strata = np.unique(self.stratum_ids)
        jk_estimates = []

        for h in strata:
            h_mask = self.stratum_ids == h
            h_psus = np.unique(self.psu_ids[h_mask])
            a_h = len(h_psus)

            for drop_psu in h_psus:
                keep = self.psu_ids != drop_psu
                jk_w = self.weights.copy()
                rescale = keep & (self.stratum_ids == h)
                jk_w[rescale] *= a_h / (a_h - 1)
                jk_w[~keep] = 0

                active = jk_w > 0
                est = estimator_fn(self.data[active], jk_w[active])
                jk_estimates.append(est)

        jk_estimates = np.array(jk_estimates)
        a_total = len(jk_estimates)
        jk_mean = jk_estimates.mean()
        var_jk = (a_total - 1) / a_total * np.sum((jk_estimates - jk_mean)**2)

        return {'se': np.sqrt(var_jk), 'variance': var_jk,
                'n_replicates': a_total}

    def bootstrap(self, estimator_fn: Callable, B: int = 500,
                  seed: int = None) -> Dict:
        if seed:
            np.random.seed(seed)

        strata = np.unique(self.stratum_ids)
        boot_estimates = np.zeros(B)

        for r in range(B):
            boot_w = self.weights.copy()
            for h in strata:
                h_mask = self.stratum_ids == h
                h_psus = np.unique(self.psu_ids[h_mask])
                a_h = len(h_psus)

                resampled = np.random.choice(h_psus, a_h - 1, replace=True)
                _, counts = np.unique(resampled, return_counts=True)
                count_map = dict(zip(*np.unique(resampled, return_counts=True)))

                for p in h_psus:
                    p_mask = h_mask & (self.psu_ids == p)
                    m = count_map.get(p, 0)
                    boot_w[p_mask] = self.weights[p_mask] * (a_h/(a_h-1)) * m

            active = boot_w > 0
            boot_estimates[r] = estimator_fn(self.data[active], boot_w[active])

        return {'se': np.std(boot_estimates, ddof=1),
                'variance': np.var(boot_estimates, ddof=1),
                'n_replicates': B,
                'ci_95': (np.percentile(boot_estimates, 2.5),
                          np.percentile(boot_estimates, 97.5))}
