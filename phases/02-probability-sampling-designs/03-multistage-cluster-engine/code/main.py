# ============================================================
# Lesson 2.3: Two-Stage Cluster Sampling Engine
# Python — From Scratch
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# ============================================================
# STAGE 0: Population
# ============================================================

n_eas = 4500
ea_sizes = np.random.poisson(120, n_eas).clip(50)

records = []
for i in range(n_eas):
    ea_mean = np.random.normal(1500, 500)
    ea_sd = abs(np.random.normal(400, 100))
    ea_emp_rate = np.random.uniform(0.3, 0.8)
    for j in range(ea_sizes[i]):
        records.append({
            'ea_id': f'EA_{i:04d}',
            'ea_size': ea_sizes[i],
            'hh_id': f'EA_{i:04d}_HH_{j:03d}',
            'income': max(0, np.random.normal(ea_mean, ea_sd)),
            'employed': np.random.binomial(1, ea_emp_rate)
        })

population = pd.DataFrame(records)
N = len(population)
theta_income = population['income'].mean()
theta_employ = population['employed'].mean()

print(f"Population: {N:,} HH in {n_eas:,} EAs")
print(f"True mean income : {theta_income:.2f}")
print(f"True employment  : {theta_employ:.4f} ({theta_employ*100:.1f}%)")

# ============================================================
# STAGE 1: PPS Selection
# ============================================================

a = 180
b = 15

M_total = ea_sizes.sum()
cumul = np.cumsum(ea_sizes)
interval = M_total / a
R = np.random.uniform(0, interval)
sel_points = R + np.arange(a) * interval

selected_psu = np.searchsorted(cumul, sel_points).clip(0, n_eas - 1)
pi_1 = a * ea_sizes[selected_psu] / M_total

print(f"\nStage 1: {a} PSUs selected via PPS")
print(f"  Pi_1 range: [{pi_1.min():.4f}, {pi_1.max():.4f}]")

# ============================================================
# STAGE 2: Systematic within PSU
# ============================================================

sample_records = []

for k, psu_idx in enumerate(selected_psu):
    ea_id = f'EA_{psu_idx:04d}'
    psu_hh = population[population['ea_id'] == ea_id].reset_index(drop=True)
    M_i = len(psu_hh)

    # Systematic sampling
    step = M_i / b
    start = np.random.uniform(0, step)
    hh_indices = np.floor(start + np.arange(b) * step).astype(int)
    hh_indices = np.clip(hh_indices, 0, M_i - 1)

    selected_hh = psu_hh.iloc[hh_indices].copy()

    pi_2 = b / M_i
    selected_hh['pi_1'] = pi_1[k]
    selected_hh['pi_2'] = pi_2
    selected_hh['pi_overall'] = pi_1[k] * pi_2
    selected_hh['weight'] = 1.0 / (pi_1[k] * pi_2)
    selected_hh['psu_order'] = k

    sample_records.append(selected_hh)

sample_df = pd.concat(sample_records, ignore_index=True)
print(f"\nStage 2: {len(sample_df):,} HH selected ({b} per PSU)")

# ============================================================
# ESTIMATION
# ============================================================

w = sample_df['weight'].values
y_inc = sample_df['income'].values
y_emp = sample_df['employed'].values

est_income = np.sum(w * y_inc) / np.sum(w)
est_employ = np.sum(w * y_emp) / np.sum(w)

print(f"\n--- Estimates ---")
print(f"  Mean income : {est_income:.2f} (true: {theta_income:.2f})")
print(f"  Employment  : {est_employ:.4f} (true: {theta_employ:.4f})")

# Self-weighting
expected_w = M_total / (a * b)
weight_cv = sample_df['weight'].std() / sample_df['weight'].mean() * 100
print(f"\n--- Self-Weighting ---")
print(f"  Expected weight: {expected_w:.2f}")
print(f"  Weight CV      : {weight_cv:.4f}%")

assert np.allclose(sample_df['weight'].values, expected_w, rtol=0.02)
print("[PASS] Self-weighting verified.")

# ============================================================
# VARIANCE (Ultimate Cluster)
# ============================================================

z = sample_df.groupby('psu_order').apply(
    lambda g: np.sum(g['weight'] * g['income'])
).values
z_bar = z.mean()

var_total = np.sum((z - z_bar)**2) / (a * (a - 1))
se_income = np.sqrt(var_total) / np.sum(w) * N

print(f"\n--- Variance ---")
print(f"  SE(income) : {se_income:.2f}")
print(f"  CV         : {se_income / est_income * 100:.1f}%")
print(f"  95% CI     : [{est_income - 1.96*se_income:.2f}, "
      f"{est_income + 1.96*se_income:.2f}]")
# ============================================================
# PRODUCTION: two_stage_sampler.py
# Complete two-stage cluster sampling engine
# ============================================================

import numpy as np
import pandas as pd
from dataclasses import dataclass
from typing import Optional


@dataclass
class TwoStageSample:
    """Result of a two-stage cluster sampling procedure."""
    sample_data: pd.DataFrame
    n_psus: int
    n_hh_per_psu: int
    total_sample_size: int
    expected_weight: float
    is_self_weighting: bool


def two_stage_cluster_sample(
    frame: pd.DataFrame,
    ea_col: str,
    size_col: str,
    n_psus: int,
    n_hh_per_psu: int,
    seed: Optional[int] = None
) -> TwoStageSample:
    """
    Execute two-stage cluster sampling:
    Stage 1: Systematic PPS selection of PSUs
    Stage 2: Systematic random selection of HH within PSUs
    """
    if seed is not None:
        np.random.seed(seed)

    # EA-level frame
    ea_frame = frame.groupby(ea_col).agg(
        ea_size=(size_col, 'first') if size_col != ea_col else (ea_col, 'count')
    ).reset_index()

    if size_col == ea_col:
        ea_frame['ea_size'] = frame.groupby(ea_col).size().values

    sizes = ea_frame['ea_size'].values if 'ea_size' in ea_frame.columns \
        else frame.groupby(ea_col).size().values
    ea_ids = ea_frame[ea_col].values
    A = len(ea_ids)

    # Stage 1: PPS
    M_total = sizes.sum()
    cumul = np.cumsum(sizes)
    interval = M_total / n_psus
    R = np.random.uniform(0, interval)
    sel_points = R + np.arange(n_psus) * interval
    psu_indices = np.searchsorted(cumul, sel_points).clip(0, A - 1)

    selected_ea_ids = ea_ids[psu_indices]
    pi_1 = n_psus * sizes[psu_indices] / M_total

    # Stage 2: Systematic within each PSU
    all_selected = []
    for k, (ea_id, p1) in enumerate(zip(selected_ea_ids, pi_1)):
        psu_data = frame[frame[ea_col] == ea_id].reset_index(drop=True)
        M_i = len(psu_data)
        b = min(n_hh_per_psu, M_i)

        step = M_i / b
        start = np.random.uniform(0, step)
        hh_idx = np.floor(start + np.arange(b) * step).astype(int)
        hh_idx = np.clip(hh_idx, 0, M_i - 1)

        selected = psu_data.iloc[hh_idx].copy()
        p2 = b / M_i
        selected['_pi1'] = p1
        selected['_pi2'] = p2
        selected['_pi'] = p1 * p2
        selected['_weight'] = 1.0 / (p1 * p2)
        selected['_psu_order'] = k + 1
        all_selected.append(selected)

    result = pd.concat(all_selected, ignore_index=True)
    expected_w = M_total / (n_psus * n_hh_per_psu)
    w_cv = result['_weight'].std() / result['_weight'].mean()

    return TwoStageSample(
        sample_data=result,
        n_psus=n_psus,
        n_hh_per_psu=n_hh_per_psu,
        total_sample_size=len(result),
        expected_weight=expected_w,
        is_self_weighting=(w_cv < 0.02)
    )
