# ============================================================
# Lesson 4.3: Calibration / Raking via IPF
# Python — From Scratch (basic arrays)
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

n = 3000
sample_df = pd.DataFrame({
    'sex': np.random.choice(['Male', 'Female'], n, p=[0.52, 0.48]),
    'age_grp': np.random.choice(['18-30', '31-45', '46-60', '61+'], n,
                                 p=[0.18, 0.32, 0.30, 0.20]),
    'region': np.random.choice(['Urban', 'Rural'], n, p=[0.65, 0.35]),
    'income': np.random.lognormal(7.0, 0.8, n),
    'weight': 200.0
})

N_pop = n * 200

margins = {
    'sex': {'Male': 0.49 * N_pop, 'Female': 0.51 * N_pop},
    'age_grp': {'18-30': 0.25*N_pop, '31-45': 0.30*N_pop,
                '46-60': 0.28*N_pop, '61+': 0.17*N_pop},
    'region': {'Urban': 0.58 * N_pop, 'Rural': 0.42 * N_pop}
}

print("=" * 60)
print("  ITERATIVE PROPORTIONAL FITTING (RAKING)")
print("=" * 60)

# Show mismatch before
print("\n--- Before calibration ---")
for var, targets in margins.items():
    for cat, target in targets.items():
        current = sample_df.loc[sample_df[var] == cat, 'weight'].sum()
        print(f"  {var}/{cat:<8}: current={current:>10,.0f}  target={target:>10,.0f}  "
              f"ratio={current/target:.3f}")

# --- IPF ---
w = sample_df['weight'].values.copy()
max_iter = 100
tol = 0.001

print(f"\n--- Running IPF ---")

for iteration in range(1, max_iter + 1):
    max_diff = 0

    for var, targets in margins.items():
        col = sample_df[var].values
        for cat, target in targets.items():
            mask = col == cat
            current = w[mask].sum()
            if current > 0:
                factor = target / current
                w[mask] *= factor
                max_diff = max(max_diff, abs(factor - 1))

    if iteration <= 5 or iteration % 10 == 0:
        print(f"  Iter {iteration:>3}: max_diff = {max_diff:.6f}")

    if max_diff < tol:
        print(f"  CONVERGED at iteration {iteration}")
        break

sample_df['cal_weight'] = w

# Verify
print("\n--- After calibration ---")
all_ok = True
for var, targets in margins.items():
    for cat, target in targets.items():
        current = sample_df.loc[sample_df[var] == cat, 'cal_weight'].sum()
        ratio = current / target
        print(f"  {var}/{cat:<8}: ratio={ratio:.6f}")
        if abs(ratio - 1) > 0.001:
            all_ok = False

assert all_ok, "Not all margins matched!"
print("\n[PASS] All margins matched.")

# Weight diagnostics
print(f"\n--- Weight diagnostics ---")
print(f"  Range: [{w.min():.1f}, {w.max():.1f}]")
print(f"  CV   : {w.std()/w.mean()*100:.1f}%")
print(f"  Sum  : {w.sum():,.0f} (target: {N_pop:,})")

assert abs(w.sum() - N_pop) < 1
print("[PASS] Weight sum = population total.")
# ============================================================
# PRODUCTION: calibrator.py
# ============================================================

import numpy as np
import pandas as pd
from typing import Dict


class SurveyCalibrator:
    """Calibrate survey weights to known population margins via IPF/raking."""

    def __init__(self, df: pd.DataFrame, weight_col: str):
        self.df = df.copy()
        self.weight_col = weight_col
        self.margins = {}
        self.converged = False
        self.iterations = 0

    def add_margin(self, variable: str, totals: Dict[str, float]):
        self.margins[variable] = totals

    def rake(self, max_iter: int = 200, tol: float = 0.001,
             trim: tuple = None) -> pd.Series:
        w = self.df[self.weight_col].values.copy()

        for it in range(1, max_iter + 1):
            max_diff = 0
            for var, targets in self.margins.items():
                col = self.df[var].values
                for cat, target in targets.items():
                    mask = col == cat
                    current = w[mask].sum()
                    if current > 0:
                        f = target / current
                        w[mask] *= f
                        max_diff = max(max_diff, abs(f - 1))

            if max_diff < tol:
                self.converged = True
                self.iterations = it
                break

        if trim:
            lo, hi = np.percentile(w, [trim[0]*100, trim[1]*100])
            w = np.clip(w, lo, hi)
            # Re-normalize
            total_target = sum(sum(t.values()) for t in self.margins.values()) / len(self.margins)
            w *= total_target / w.sum()

        self.df['calibrated_weight'] = w
        return pd.Series(w, index=self.df.index)

    def check_margins(self) -> pd.DataFrame:
        results = []
        for var, targets in self.margins.items():
            for cat, target in targets.items():
                actual = self.df.loc[
                    self.df[var] == cat, 'calibrated_weight'
                ].sum()
                results.append({
                    'variable': var, 'category': cat,
                    'target': target, 'actual': actual,
                    'ratio': actual / target if target > 0 else np.nan
                })
        return pd.DataFrame(results)
