# ============================================================
# Lesson 3.2: Design Effect & ICC from Scratch
# Python — ANOVA variance components
# ============================================================

import numpy as np

np.random.seed(2024)


def compute_icc(y, cluster_ids):
    """Compute ICC using one-way ANOVA variance components."""
    valid = ~(np.isnan(y))
    y = y[valid]
    cluster_ids = np.array(cluster_ids)[valid]

    clusters = np.unique(cluster_ids)
    k = len(clusters)
    n_total = len(y)
    grand_mean = np.mean(y)

    # Cluster sizes and means
    cluster_sizes = np.array([np.sum(cluster_ids == c) for c in clusters])
    cluster_means = np.array([np.mean(y[cluster_ids == c]) for c in clusters])
    m_bar = np.mean(cluster_sizes)

    # SSB
    ssb = np.sum(cluster_sizes * (cluster_means - grand_mean) ** 2)
    msb = ssb / (k - 1)

    # SSW
    y_cluster_means = np.zeros_like(y, dtype=float)
    for c in clusters:
        mask = cluster_ids == c
        y_cluster_means[mask] = np.mean(y[mask])
    ssw = np.sum((y - y_cluster_means) ** 2)
    msw = ssw / (n_total - k)

    # Variance components
    sigma2_b = (msb - msw) / m_bar
    sigma2_w = msw

    rho = sigma2_b / (sigma2_b + sigma2_w)
    rho = max(rho, -1 / (m_bar - 1))

    deff = 1 + (m_bar - 1) * rho

    return {
        'rho': rho, 'msb': msb, 'msw': msw,
        'sigma2_b': sigma2_b, 'sigma2_w': sigma2_w,
        'k': k, 'm_bar': m_bar, 'deff': deff
    }


# --- Simulation ---
k = 500
m = 100
rho_true = 0.08

sigma2_total = 100
sigma2_b = rho_true * sigma2_total
sigma2_w = (1 - rho_true) * sigma2_total

cluster_effects = np.random.normal(0, np.sqrt(sigma2_b), k)
y = np.zeros(k * m)
cluster_ids = np.empty(k * m, dtype='<U10')

for i in range(k):
    sl = slice(i * m, (i + 1) * m)
    y[sl] = 50 + cluster_effects[i] + np.random.normal(0, np.sqrt(sigma2_w), m)
    cluster_ids[sl] = f'CL_{i:03d}'

print(f"Population: {k} clusters x {m} = {k*m}")
print(f"True ICC: {rho_true}")

result = compute_icc(y, cluster_ids)

print(f"\n--- ANOVA ---")
print(f"  MSB       : {result['msb']:.4f}")
print(f"  MSW       : {result['msw']:.4f}")
print(f"  sigma2_b  : {result['sigma2_b']:.4f}")
print(f"  sigma2_w  : {result['sigma2_w']:.4f}")
print(f"  ICC (rho) : {result['rho']:.4f} (true: {rho_true})")
print(f"  Deff      : {result['deff']:.2f}")

assert abs(result['rho'] - rho_true) < 0.02
print("\n[PASS] ICC within 0.02 of true value.")

# --- Scenario comparison ---
rho = result['rho']

scenarios = [
    ('A: 300x10', 300, 10),
    ('B: 150x20', 150, 20),
]

print(f"\n{'Scenario':<12} {'clusters':>8} {'m':>4} {'Deff':>8} {'eff_n':>8}")
print("-" * 48)
for name, n_cl, m_cl in scenarios:
    d = 1 + (m_cl - 1) * rho
    eff = (n_cl * m_cl) / d
    print(f"{name:<12} {n_cl:>8} {m_cl:>4} {d:>8.2f} {eff:>8.0f}")

# --- Monte Carlo Deff ---
B = 3000
n_sample = 300

srs_est = np.array([
    np.mean(y[np.random.choice(len(y), n_sample, replace=False)])
    for _ in range(B)
])

unique_cl = np.unique(cluster_ids)
clust_est = np.zeros(B)
for b in range(B):
    sel = np.random.choice(unique_cl, 30, replace=False)
    vals = []
    for c in sel:
        c_vals = y[cluster_ids == c]
        idx = np.random.choice(len(c_vals), min(10, len(c_vals)), replace=False)
        vals.extend(c_vals[idx])
    clust_est[b] = np.mean(vals)

deff_mc = np.var(clust_est, ddof=1) / np.var(srs_est, ddof=1)
deff_form = 1 + (10 - 1) * rho

print(f"\n--- MC Verification ---")
print(f"  Deff (MC)     : {deff_mc:.2f}")
print(f"  Deff (formula): {deff_form:.2f}")

assert abs(deff_mc - deff_form) / deff_form < 0.25
print("[PASS] MC Deff consistent with formula.")
# ============================================================
# PRODUCTION: deff_analyzer.py
# Design Effect and ICC analysis tool
# ============================================================

import numpy as np
from typing import Dict, Optional


class DeffAnalyzer:
    """Analyze design effects and ICC for survey data."""

    def __init__(self, y: np.ndarray, cluster_ids: np.ndarray,
                 stratum_ids: Optional[np.ndarray] = None):
        self.y = np.asarray(y, dtype=float)
        self.cluster_ids = np.asarray(cluster_ids)
        self.stratum_ids = stratum_ids
        self._results = None

    def compute(self) -> Dict:
        """Compute ICC and Deff using ANOVA."""
        valid = ~np.isnan(self.y)
        y = self.y[valid]
        cl = self.cluster_ids[valid]

        clusters = np.unique(cl)
        k = len(clusters)
        n = len(y)
        grand_mean = np.mean(y)

        sizes = np.array([np.sum(cl == c) for c in clusters])
        means = np.array([np.mean(y[cl == c]) for c in clusters])
        m_bar = np.mean(sizes)

        ssb = np.sum(sizes * (means - grand_mean) ** 2)
        msb = ssb / max(k - 1, 1)

        ssw = sum(np.sum((y[cl == c] - means[i]) ** 2)
                  for i, c in enumerate(clusters))
        msw = ssw / max(n - k, 1)

        sigma2_b = max(0, (msb - msw) / m_bar)
        sigma2_w = msw
        rho = sigma2_b / (sigma2_b + sigma2_w) if (sigma2_b + sigma2_w) > 0 else 0

        self._results = {
            'rho': rho, 'deff': 1 + (m_bar - 1) * rho,
            'msb': msb, 'msw': msw,
            'sigma2_between': sigma2_b, 'sigma2_within': sigma2_w,
            'n_clusters': k, 'mean_cluster_size': m_bar,
            'n_obs': n
        }
        return self._results

    def scenario_table(self, cluster_sizes: list) -> str:
        """Compare Deff across hypothetical cluster sizes."""
        if self._results is None:
            self.compute()
        rho = self._results['rho']

        lines = [f"ICC (rho) = {rho:.4f}\n",
                 f"{'m':>6} | {'Deff':>8} | {'eff_n (n=3000)':>16}",
                 "-" * 35]
        for m in cluster_sizes:
            d = 1 + (m - 1) * rho
            lines.append(f"{m:>6} | {d:>8.2f} | {3000/d:>16.0f}")
        return "\n".join(lines)

    def report(self) -> str:
        if self._results is None:
            self.compute()
        r = self._results
        return (
            f"=== DESIGN EFFECT ANALYSIS ===\n"
            f"  Clusters        : {r['n_clusters']}\n"
            f"  Mean size (m)   : {r['mean_cluster_size']:.1f}\n"
            f"  ICC (rho)       : {r['rho']:.4f}\n"
            f"  Deff            : {r['deff']:.2f}\n"
            f"  sigma2_between  : {r['sigma2_between']:.4f}\n"
            f"  sigma2_within   : {r['sigma2_within']:.4f}\n"
        )
