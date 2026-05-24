# ============================================================
# Lesson 4.1: Design Weights (Base Weights)
# Python — From Scratch
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# --- Setup ---
n_eas = 3000
ea_sizes = np.random.poisson(120, n_eas).clip(50)
M_total = ea_sizes.sum()

a = 180
b = 15

# PPS selection
cumul = np.cumsum(ea_sizes)
interval = M_total / a
R = np.random.uniform(0, interval)
sel_points = R + np.arange(a) * interval
selected_psu = np.searchsorted(cumul, sel_points).clip(0, n_eas - 1)

# Weight computation
M_i = ea_sizes[selected_psu]
pi_1 = a * M_i / M_total
w_1 = 1.0 / pi_1
pi_2 = b / M_i
w_2 = 1.0 / pi_2
w_overall = w_1 * w_2

print("=" * 60)
print("  DESIGN WEIGHT COMPUTATION")
print("=" * 60)

# Display
df = pd.DataFrame({
    'psu': range(1, a + 1),
    'M_i': M_i,
    'pi_1': np.round(pi_1, 4),
    'pi_2': np.round(pi_2, 4),
    'w_1': np.round(w_1, 2),
    'w_overall': np.round(w_overall, 2)
})
print(f"\n{df.head(10).to_string(index=False)}")

# Verification 1: weight sum
total_w = np.sum(w_overall * b)
print(f"\n--- Weight Sum ---")
print(f"  Sum of weights: {total_w:,.0f}")
print(f"  True N        : {M_total:,}")
print(f"  Ratio         : {total_w / M_total:.4f}")

assert abs(total_w / M_total - 1) < 0.01
print("[PASS] Weight sum matches N.")

# Verification 2: self-weighting
expected_w = M_total / (a * b)
cv = np.std(w_overall) / np.mean(w_overall)
print(f"\n--- Self-Weighting ---")
print(f"  Expected: {expected_w:.2f}")
print(f"  Mean    : {np.mean(w_overall):.2f}")
print(f"  CV      : {cv:.6f}")

assert cv < 0.001
print("[PASS] Self-weighting confirmed.")
# ============================================================
# PRODUCTION: weight_engine.py
# ============================================================

import numpy as np
from typing import Dict, List, Optional


class DesignWeightEngine:
    """Compute and validate multi-stage design weights."""

    def __init__(self, population_total: int):
        self.N = population_total
        self.stages = []

    def add_stage(self, name: str, pi_values: np.ndarray):
        """Add a sampling stage with its inclusion probabilities."""
        assert np.all(pi_values > 0), f"Stage '{name}': all pi must be > 0"
        assert np.all(pi_values <= 1.01), f"Stage '{name}': pi > 1 detected"
        self.stages.append({'name': name, 'pi': pi_values})

    def compute_weights(self) -> np.ndarray:
        """Compute overall weights as product of stage-specific inverses."""
        overall_pi = np.ones(len(self.stages[0]['pi']))
        for stage in self.stages:
            overall_pi *= stage['pi']
        return 1.0 / overall_pi

    def validate(self, weights: np.ndarray,
                 tolerance: float = 0.05) -> Dict:
        weight_sum = weights.sum()
        ratio = weight_sum / self.N
        cv = np.std(weights) / np.mean(weights)
        is_self_weighting = cv < 0.02

        return {
            'weight_sum': weight_sum,
            'population_N': self.N,
            'ratio': ratio,
            'within_tolerance': abs(ratio - 1) < tolerance,
            'cv': cv,
            'is_self_weighting': is_self_weighting,
            'min': weights.min(),
            'max': weights.max(),
            'mean': weights.mean()
        }
