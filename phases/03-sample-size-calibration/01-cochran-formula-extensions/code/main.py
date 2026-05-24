# ============================================================
# Lesson 3.1: Cochran's Formula Extensions
# Python — From Scratch
# ============================================================

import numpy as np
from math import ceil

def cochran_proportion(p, e, z=1.96, N=None, deff=1.0, nr_rate=0.0):
    """Compute sample size for estimating a proportion."""
    assert 0 < p < 1, "p must be between 0 and 1"
    assert e > 0, "Margin of error must be positive"
    assert deff >= 1, "Deff must be >= 1"
    assert 0 <= nr_rate < 1, "NR rate must be in [0, 1)"

    n0 = (z**2 * p * (1 - p)) / e**2

    if N is not None and N > 0:
        n_fpc = n0 / (1 + (n0 - 1) / N)
    else:
        n_fpc = n0

    n_deff = n_fpc * deff
    n_final = n_deff / (1 - nr_rate)

    return {
        'n0': ceil(n0),
        'n_fpc': ceil(n_fpc),
        'n_deff': ceil(n_deff),
        'n_final': ceil(n_final)
    }


def cochran_mean(sigma, e, z=1.96, N=None, deff=1.0, nr_rate=0.0):
    """Compute sample size for estimating a mean."""
    assert sigma > 0 and e > 0 and deff >= 1
    assert 0 <= nr_rate < 1

    n0 = (z**2 * sigma**2) / e**2
    if N is not None and N > 0:
        n0 = n0 / (1 + (n0 - 1) / N)
    return ceil(n0 * deff / (1 - nr_rate))


# ============================================================
# SCENARIO: National Poverty Survey
# ============================================================

print("=" * 60)
print("  SAMPLE SIZE: National Poverty Survey")
print("=" * 60)

result = cochran_proportion(
    p=0.25, e=0.02, z=1.96,
    N=2_000_000, deff=2.5, nr_rate=0.15
)

for step, key in [("Base (Cochran)", "n0"), ("After FPC", "n_fpc"),
                   ("After Deff", "n_deff"), ("After NR adj", "n_final")]:
    print(f"  {step:<20}: {result[key]:>8,}")

print(f"\n  Final sample size: {result['n_final']:,}")

# --- Sensitivity ---
print("\n--- Sensitivity to Deff ---")
for d in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0]:
    r = cochran_proportion(0.25, 0.02, N=2e6, deff=d, nr_rate=0.15)
    print(f"  Deff={d:.1f} -> n={r['n_final']:,}")

print("\n--- Sensitivity to margin of error ---")
for e in [0.01, 0.015, 0.02, 0.03, 0.05]:
    r = cochran_proportion(0.25, e, N=2e6, deff=2.5, nr_rate=0.15)
    print(f"  e={e*100:.1f}% -> n={r['n_final']:,}")

# --- Domain estimation ---
print("\n" + "=" * 60)
print("  DOMAIN-LEVEL (12 Governorates)")
print("=" * 60)

domains = [
    ('GOV_01', 500000, 0.15), ('GOV_02', 200000, 0.30),
    ('GOV_03', 180000, 0.35), ('GOV_04', 250000, 0.20),
    ('GOV_05', 150000, 0.40), ('GOV_06', 120000, 0.25),
    ('GOV_07', 100000, 0.22), ('GOV_08', 130000, 0.28),
    ('GOV_09', 90000, 0.45),  ('GOV_10', 80000, 0.50),
    ('GOV_11', 110000, 0.18), ('GOV_12', 90000, 0.38),
]

total_n = 0
print(f"{'Domain':<10} {'N_d':>10} {'p_d':>6} {'n_d':>8}")
print("-" * 40)
for name, Nd, pd in domains:
    r = cochran_proportion(pd, 0.05, N=Nd, deff=2.5, nr_rate=0.15)
    total_n += r['n_final']
    print(f"{name:<10} {Nd:>10,} {pd:>6.2f} {r['n_final']:>8,}")

print(f"\nTotal sample: {total_n:,}")

# --- Verification ---
print("\n--- Simulation verification ---")
np.random.seed(2024)
N_sim = 200000
pop = np.random.binomial(1, 0.25, N_sim)
theta = pop.mean()

r = cochran_proportion(0.25, 0.02, N=N_sim, deff=1.0, nr_rate=0.0)
n_test = r['n_final']

B = 5000
estimates = np.array([
    np.mean(pop[np.random.choice(N_sim, n_test, replace=False)])
    for _ in range(B)
])

achieved_moe = 1.96 * np.std(estimates, ddof=1)
print(f"  Target MoE  : 0.0200")
print(f"  Achieved MoE: {achieved_moe:.4f}")

assert achieved_moe <= 0.02 * 1.15, f"MoE too large: {achieved_moe}"
print("[PASS] Computed n achieves target precision.")
# ============================================================
# PRODUCTION: sample_size_calculator.py
# ============================================================

from math import ceil
from typing import Optional, Dict, List
import json


class SampleSizeCalculator:
    """Production sample size calculator for complex surveys."""

    def __init__(self, confidence: float = 0.95):
        from scipy.stats import norm
        self.z = norm.ppf(1 - (1 - confidence) / 2)
        self.confidence = confidence

    def for_proportion(self, p: float, e: float,
                       N: Optional[int] = None,
                       deff: float = 1.0,
                       nr_rate: float = 0.0) -> Dict:
        n0 = (self.z ** 2 * p * (1 - p)) / e ** 2
        n_fpc = n0 / (1 + (n0 - 1) / N) if N else n0
        n_adj = n_fpc * deff / (1 - nr_rate)
        return {
            'n_base': ceil(n0), 'n_fpc': ceil(n_fpc),
            'n_final': ceil(n_adj),
            'params': {'p': p, 'e': e, 'N': N, 'deff': deff, 'nr': nr_rate}
        }

    def for_mean(self, sigma: float, e: float,
                 N: Optional[int] = None,
                 deff: float = 1.0,
                 nr_rate: float = 0.0) -> Dict:
        n0 = (self.z ** 2 * sigma ** 2) / e ** 2
        n_fpc = n0 / (1 + (n0 - 1) / N) if N else n0
        n_adj = n_fpc * deff / (1 - nr_rate)
        return {
            'n_base': ceil(n0), 'n_fpc': ceil(n_fpc),
            'n_final': ceil(n_adj),
            'params': {'sigma': sigma, 'e': e, 'N': N, 'deff': deff, 'nr': nr_rate}
        }

    def for_domains(self, domains: List[Dict],
                    target_e: float, deff: float = 1.0,
                    nr_rate: float = 0.0) -> Dict:
        results = []
        for d in domains:
            r = self.for_proportion(
                p=d['p'], e=target_e, N=d.get('N'),
                deff=deff, nr_rate=nr_rate
            )
            r['domain'] = d['name']
            results.append(r)

        return {
            'domain_sizes': results,
            'total_n': sum(r['n_final'] for r in results)
        }

    def sensitivity_report(self, p: float, e: float,
                           N: int, nr_rate: float = 0.15) -> str:
        lines = ["=== SAMPLE SIZE SENSITIVITY REPORT ===\n"]
        lines.append(f"Base: p={p}, e={e}, N={N:,}, NR={nr_rate}\n")
        lines.append(f"{'Deff':>6} | {'n':>10}")
        lines.append("-" * 20)
        for d in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0]:
            r = self.for_proportion(p, e, N, d, nr_rate)
            lines.append(f"{d:>6.1f} | {r['n_final']:>10,}")
        return "\n".join(lines)
