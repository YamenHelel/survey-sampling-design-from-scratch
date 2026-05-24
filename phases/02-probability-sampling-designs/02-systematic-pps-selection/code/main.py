# ============================================================
# Lesson 2.2: Systematic PPS Selection
# Python — From Scratch (loops + standard random only)
# ============================================================

import numpy as np

np.random.seed(2024)

# --- Generate EA frame ---
A = 4500  # Total EAs
a = 200   # EAs to select

ea_sizes = np.concatenate([
    np.random.poisson(40, 300).clip(20),    # Small EAs
    np.random.poisson(110, 3900).clip(50),   # Normal EAs
    np.random.poisson(350, 300).clip(200)    # Large EAs
])

ea_ids = [f"EA_{i:04d}" for i in range(A)]

print(f"Total EAs: {A}")
print(f"Size range: [{ea_sizes.min()}, {ea_sizes.max()}]")
print(f"Total households: {ea_sizes.sum():,}")
print(f"EAs to select: {a}")

# ============================================================
# SYSTEMATIC PPS SELECTION — FROM SCRATCH
# ============================================================

# Step 1: Compute cumulative sizes
cumulative = np.cumsum(ea_sizes)
M_total = cumulative[-1]

print(f"\nTotal size (M.): {M_total:,}")

# Step 2: Selection interval
interval = M_total / a
print(f"Selection interval (I): {interval:.2f}")

# Step 3: Random start
random_start = np.random.uniform(0, interval)
print(f"Random start (R): {random_start:.2f}")

# Step 4: Selection points
selection_points = random_start + np.arange(a) * interval

# Step 5: Identify selected EAs
selected_indices = []
for sp in selection_points:
    # Find first cumulative value >= selection point
    idx = 0
    while idx < A and cumulative[idx] < sp:
        idx += 1
    selected_indices.append(idx)

selected_indices = np.array(selected_indices)

# Check for certainty selections (pi_i > 1)
pi_i = a * ea_sizes / M_total
certainty_mask = pi_i >= 1.0
n_certainty = certainty_mask.sum()
print(f"\nCertainty selections (pi >= 1): {n_certainty}")

# ============================================================
# COMPUTE INCLUSION PROBABILITIES AND WEIGHTS
# ============================================================

selected_ids = [ea_ids[i] for i in selected_indices]
selected_sizes = ea_sizes[selected_indices]
selected_pi = a * selected_sizes / M_total

# Base weights (inverse of inclusion probability)
base_weights = 1.0 / selected_pi

print(f"\n--- Selected Sample Summary ---")
print(f"  EAs selected: {len(selected_indices)}")
print(f"  Unique EAs  : {len(set(selected_indices))}")
print(f"  Size range  : [{selected_sizes.min()}, {selected_sizes.max()}]")
print(f"  Pi range    : [{selected_pi.min():.4f}, {selected_pi.max():.4f}]")
print(f"  Weight range: [{base_weights.min():.2f}, {base_weights.max():.2f}]")

# ============================================================
# SELF-WEIGHTING VERIFICATION
# ============================================================

# If we select b=15 HH per EA via SRS:
b = 15
hh_weights = base_weights * (selected_sizes / b)

print(f"\n--- Self-Weighting Check (b = {b} HH/EA) ---")
print(f"  HH weight range: [{hh_weights.min():.2f}, {hh_weights.max():.2f}]")
print(f"  HH weight mean : {hh_weights.mean():.2f}")
print(f"  HH weight CV   : {hh_weights.std() / hh_weights.mean() * 100:.1f}%")
print(f"  Expected weight : {M_total / (a * b):.2f}")

# Assertion: self-weighting property
expected_w = M_total / (a * b)
assert np.allclose(hh_weights, expected_w, rtol=0.01), \
    f"Weights should be constant: {hh_weights[:5]} vs {expected_w}"
print(f"\n[PASS] Self-weighting property verified!")

# Verify estimated total
estimated_N = np.sum(base_weights)
print(f"\n  Estimated N (sum of weights): {estimated_N:,.0f}")
print(f"  True N                      : {A:,}")
# ============================================================
# Lesson 2.2: PPS verification with numpy
# Python — comparing manual vs vectorized
# ============================================================

import numpy as np

np.random.seed(2024)

A = 4500
a = 200
ea_sizes = np.concatenate([
    np.random.poisson(40, 300).clip(20),
    np.random.poisson(110, 3900).clip(50),
    np.random.poisson(350, 300).clip(200)
])

# Vectorized PPS (for verification)
M_total = ea_sizes.sum()
pi_all = a * ea_sizes / M_total

# Check: sum of pi should equal a
print(f"Sum of pi_i: {pi_all.sum():.4f} (should be {a})")
assert abs(pi_all.sum() - a) < 0.01
print("[PASS] Sum of inclusion probabilities equals sample size.")

# HT estimator of total number of EAs (should = A)
# This is a trivial check: sum(1/pi_i) for selected units
cumul = np.cumsum(ea_sizes)
interval = M_total / a
R = np.random.uniform(0, interval)
sel_points = R + np.arange(a) * interval
selected = np.searchsorted(cumul, sel_points, side='left')
selected = np.clip(selected, 0, A - 1)

ht_total_N = np.sum(1.0 / (a * ea_sizes[selected] / M_total))
print(f"\nHT estimate of N: {ht_total_N:,.0f}")
print(f"True N          : {A:,}")
# ============================================================
# PRODUCTION: pps_selector.py
# Systematic PPS selection engine
# ============================================================

import numpy as np
from typing import Tuple


def systematic_pps_select(sizes: np.ndarray,
                          n_select: int,
                          seed: int = None) -> Tuple[np.ndarray, np.ndarray]:
    """
    Systematic PPS (Probability Proportional to Size) selection.

    Parameters
    ----------
    sizes : array of size measures for each unit
    n_select : number of units to select
    seed : random seed

    Returns
    -------
    selected_indices : indices of selected units
    inclusion_probs  : inclusion probabilities for selected units
    """
    if seed is not None:
        np.random.seed(seed)

    A = len(sizes)
    assert n_select <= A, f"Cannot select {n_select} from {A} units"
    assert np.all(sizes > 0), "All sizes must be positive"

    M_total = sizes.sum()
    pi = n_select * sizes / M_total

    # Handle certainty selections (pi >= 1)
    certainty = np.where(pi >= 1.0)[0]
    if len(certainty) > 0:
        # Remove certainty units, adjust remaining
        remaining_mask = pi < 1.0
        remaining_sizes = sizes[remaining_mask]
        n_remaining = n_select - len(certainty)

        if n_remaining > 0 and len(remaining_sizes) > 0:
            sub_selected, sub_pi = systematic_pps_select(
                remaining_sizes, n_remaining, seed
            )
            # Map back to original indices
            original_idx = np.where(remaining_mask)[0]
            selected = np.concatenate([certainty, original_idx[sub_selected]])
            probs = np.concatenate([np.ones(len(certainty)), sub_pi])
        else:
            selected = certainty
            probs = np.ones(len(certainty))

        return selected, probs

    # Cumulative sizes
    cumul = np.cumsum(sizes)
    interval = M_total / n_select
    start = np.random.uniform(0, interval)
    sel_points = start + np.arange(n_select) * interval

    # Select
    selected = np.searchsorted(cumul, sel_points, side='left')
    selected = np.clip(selected, 0, A - 1)

    inclusion_probs = n_select * sizes[selected] / M_total

    return selected, inclusion_probs


# --- Usage ---
# selected_idx, pi = systematic_pps_select(ea_sizes, n_select=200, seed=42)
# base_weights = 1.0 / pi
