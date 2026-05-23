# ============================================================
# Lesson 1.2: PSU Partitioning & Harmonization
# Python — From Scratch
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# --- Generate EA frame ---
n_eas = 4500
eas = pd.DataFrame({
    'ea_id': [f'EA_{i:04d}' for i in range(n_eas)],
    'dist_id': np.random.choice([f'DIST_{d:03d}' for d in range(120)], n_eas),
    'n_hh': np.concatenate([
        np.random.poisson(20, 340).clip(5),
        np.random.poisson(110, n_eas - 340 - 85).clip(5),
        np.random.poisson(400, 85).clip(5)
    ])
})

M_MIN, M_MAX, M_TARGET = 80, 150, 110

print("=" * 60)
print("  PSU HARMONIZATION ENGINE")
print("=" * 60)

print(f"\n--- BEFORE ---")
print(f"  Total EAs     : {len(eas):,}")
print(f"  Size range    : [{eas['n_hh'].min()}, {eas['n_hh'].max()}]")
print(f"  Mean size     : {eas['n_hh'].mean():.1f}")
cv_before = eas['n_hh'].std() / eas['n_hh'].mean() * 100
print(f"  CV            : {cv_before:.1f}%")
print(f"  Undersized    : {(eas['n_hh'] < M_MIN).sum()}")
print(f"  Oversized     : {(eas['n_hh'] > M_MAX).sum()}")

# --- STEP 1: Split oversized ---
print(f"\n--- STEP 1: Splitting ---")
records = []
n_splits = 0

for _, row in eas.iterrows():
    if row['n_hh'] > M_MAX:
        k = int(np.ceil(row['n_hh'] / M_TARGET))
        base = row['n_hh'] // k
        remainder = row['n_hh'] - base * k
        for j in range(k):
            sub_size = base + (1 if j < remainder else 0)
            records.append({
                'psu_id': f"{row['ea_id']}_S{j+1}",
                'dist_id': row['dist_id'],
                'n_hh': sub_size,
                'origin': 'split'
            })
        n_splits += 1
    else:
        records.append({
            'psu_id': row['ea_id'],
            'dist_id': row['dist_id'],
            'n_hh': row['n_hh'],
            'origin': 'original'
        })

psus = pd.DataFrame(records)
print(f"  EAs split: {n_splits}")

# --- STEP 2: Merge undersized ---
print(f"\n--- STEP 2: Merging ---")
psus['active'] = True
n_merges = 0

for dist in psus['dist_id'].unique():
    dist_mask = (psus['dist_id'] == dist) & psus['active']

    while True:
        undersized = psus.index[dist_mask & (psus['n_hh'] < M_MIN)]
        if len(undersized) == 0:
            break

        current = undersized[0]
        candidates = psus.index[
            dist_mask &
            (psus.index != current) &
            (psus['n_hh'] + psus.loc[current, 'n_hh'] <= M_MAX * 1.2)
        ]

        if len(candidates) == 0:
            break

        # Best partner: combined size closest to target
        combined = psus.loc[candidates, 'n_hh'] + psus.loc[current, 'n_hh']
        best = candidates[np.abs(combined - M_TARGET).argmin()]

        # Merge
        psus.loc[best, 'n_hh'] += psus.loc[current, 'n_hh']
        psus.loc[best, 'psu_id'] += f"+{psus.loc[current, 'psu_id']}"
        psus.loc[best, 'origin'] = 'merged'
        psus.loc[current, 'active'] = False
        n_merges += 1

        # Refresh mask
        dist_mask = (psus['dist_id'] == dist) & psus['active']

print(f"  Merges performed: {n_merges}")

# Final frame
final = psus[psus['active']].drop(columns=['active']).reset_index(drop=True)

print(f"\n--- AFTER ---")
print(f"  Total PSUs    : {len(final):,}")
print(f"  Size range    : [{final['n_hh'].min()}, {final['n_hh'].max()}]")
print(f"  Mean size     : {final['n_hh'].mean():.1f}")
cv_after = final['n_hh'].std() / final['n_hh'].mean() * 100
print(f"  CV            : {cv_after:.1f}%")
print(f"  Undersized    : {(final['n_hh'] < M_MIN).sum()}")
print(f"  Oversized     : {(final['n_hh'] > M_MAX).sum()}")

# Verify household count preserved
assert eas['n_hh'].sum() == final['n_hh'].sum(), "Total HH must be preserved!"
print(f"\n  Total HH preserved: {eas['n_hh'].sum():,} [PASS]")
assert cv_after < cv_before, "CV should improve after harmonization"
print(f"  CV improved: {cv_before:.1f}% -> {cv_after:.1f}% [PASS]")


# ============================================================
# USE IT: Geographic adjacency with geopandas
# ============================================================

# In production, use GIS for geographic adjacency:
# import geopandas as gpd
#
# ea_boundaries = gpd.read_file("ea_boundaries.shp")
#
# # Build spatial adjacency
# from shapely.ops import unary_union
# # For each undersized EA, find touching neighbors
# for idx, row in ea_boundaries[ea_boundaries['n_hh'] < M_MIN].iterrows():
#     neighbors = ea_boundaries[ea_boundaries.touches(row.geometry)]
#     # Merge with best adjacent neighbor
#     ...
