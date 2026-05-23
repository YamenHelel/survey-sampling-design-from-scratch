# ============================================================
# Lesson 1.1: Frame Cleaning & Undercoverage Diagnostics
# Python — From Scratch (no specialized libraries)
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# --- Load the synthetic census frame ---
N = 50000
frame = pd.DataFrame({
    'hh_id': [f'HH_{i:06d}' for i in range(N)],
    'gov_id': np.random.choice([f'GOV_{g:02d}' for g in range(1, 7)], N),
    'ea_id': np.random.choice([f'EA_{e:04d}' for e in range(1, 501)], N),
    'hh_size': np.random.poisson(4, N).clip(1),
    'head_age': np.random.normal(42, 12, N).clip(18, 90).astype(int),
    'hh_income': np.random.lognormal(7.0, 0.9, N).round(2),
    'status': 'Occupied'
})

# Inject imperfections
# 1. Duplicates (~1%)
n_dup = int(N * 0.01)
dup_idx = np.random.choice(N, n_dup, replace=True)
duplicates = frame.iloc[dup_idx].copy()
duplicates['hh_id'] = [f'HH_{N + i:06d}' for i in range(n_dup)]
frame = pd.concat([frame, duplicates], ignore_index=True)

# 2. Out-of-scope (~2%)
n_oos = int(len(frame) * 0.02)
oos_idx = np.random.choice(len(frame), n_oos, replace=False)
frame.loc[oos_idx, 'status'] = np.random.choice(
    ['Vacant', 'Demolished', 'Under_Construction'], n_oos, p=[0.5, 0.3, 0.2]
)

# 3. Missing values (~3%)
for col in ['hh_size', 'head_age', 'hh_income']:
    na_idx = np.random.choice(len(frame), int(len(frame) * 0.03), replace=False)
    frame.loc[na_idx, col] = np.nan

print(f"Raw frame shape: {frame.shape}")
print(f"Columns: {list(frame.columns)}")

# ============================================================
# STEP 1: DUPLICATE DETECTION & REMOVAL
# ============================================================

print("\n" + "=" * 60)
print("  STEP 1: DUPLICATE DETECTION")
print("=" * 60)

key_cols = ['gov_id', 'ea_id', 'hh_size', 'head_age']
frame['is_duplicate'] = frame.duplicated(subset=key_cols, keep='first')
n_duplicates = frame['is_duplicate'].sum()

print(f"  Duplicate records found: {n_duplicates:,}")
print(f"  Duplicate rate: {n_duplicates / len(frame) * 100:.2f}%")

frame_clean = frame[~frame['is_duplicate']].copy()
frame_clean = frame_clean.drop(columns=['is_duplicate'])
print(f"  Records after deduplication: {len(frame_clean):,}")

# ============================================================
# STEP 2: OUT-OF-SCOPE IDENTIFICATION
# ============================================================

print("\n" + "=" * 60)
print("  STEP 2: OUT-OF-SCOPE RECORDS")
print("=" * 60)

status_counts = frame_clean['status'].value_counts()
print("  Status distribution:")
for status, count in status_counts.items():
    pct = count / len(frame_clean) * 100
    flag = " [OUT OF SCOPE]" if status != "Occupied" else ""
    print(f"    {status:<20}: {count:>8,} ({pct:.1f}%){flag}")

n_out_of_scope = len(frame_clean[frame_clean['status'] != 'Occupied'])
print(f"\n  Total out-of-scope: {n_out_of_scope:,}")

frame_inscope = frame_clean[frame_clean['status'] == 'Occupied'].copy()
print(f"  In-scope records: {len(frame_inscope):,}")

# ============================================================
# STEP 3: MISSING VALUE DIAGNOSTICS
# ============================================================

print("\n" + "=" * 60)
print("  STEP 3: MISSING VALUE ANALYSIS")
print("=" * 60)

print(f"  {'Column':<20} {'Missing':>8} {'Rate':>8}")
print("  " + "-" * 40)
for col in frame_inscope.columns:
    n_miss = frame_inscope[col].isna().sum()
    if n_miss > 0:
        rate = n_miss / len(frame_inscope) * 100
        print(f"  {col:<20} {n_miss:>8,} {rate:>7.1f}%")

# Impute missing values
for col in ['hh_size', 'head_age']:
    median_val = frame_inscope[col].median()
    frame_inscope[col] = frame_inscope[col].fillna(median_val)

frame_inscope['hh_income'] = frame_inscope['hh_income'].fillna(
    frame_inscope.groupby('gov_id')['hh_income'].transform('median')
)

print("\n  Missing values imputed (median by governorate for income).")

# ============================================================
# STEP 4: COVERAGE DIAGNOSTICS
# ============================================================

print("\n" + "=" * 60)
print("  STEP 4: COVERAGE ANALYSIS")
print("=" * 60)

external_totals = {
    'GOV_01': 12000, 'GOV_02': 9500, 'GOV_03': 8800,
    'GOV_04': 7200, 'GOV_05': 6500, 'GOV_06': 5500
}

frame_totals = frame_inscope.groupby('gov_id').size()

print(f"  {'Governorate':<12} {'Frame':>8} {'External':>10} {'Coverage':>10} {'Status':>10}")
print("  " + "-" * 55)

for gov_id in sorted(external_totals.keys()):
    frame_n = frame_totals.get(gov_id, 0)
    ext_n = external_totals[gov_id]
    coverage = frame_n / ext_n * 100
    status = "OK" if 90 <= coverage <= 110 else "WARNING"
    print(f"  {gov_id:<12} {frame_n:>8,} {ext_n:>10,} {coverage:>9.1f}% {status:>10}")

total_frame = len(frame_inscope)
total_external = sum(external_totals.values())
overall_coverage = total_frame / total_external * 100

print(f"\n  Overall coverage rate: {overall_coverage:.1f}%")

# ============================================================
# STEP 5: FINAL CLEAN FRAME SUMMARY
# ============================================================

print("\n" + "=" * 60)
print("  FINAL CLEAN FRAME SUMMARY")
print("=" * 60)
print(f"  Original records      : {len(frame):>10,}")
print(f"  Duplicates removed    : {n_duplicates:>10,}")
print(f"  Out-of-scope removed  : {n_out_of_scope:>10,}")
print(f"  Final clean frame     : {len(frame_inscope):>10,}")
print(f"  Missing values        : {frame_inscope.isna().sum().sum():>10,}")
print(f"  Governorates          : {frame_inscope['gov_id'].nunique():>10}")
print(f"  Enumeration Areas     : {frame_inscope['ea_id'].nunique():>10,}")

# Assertions
assert frame_inscope.isna().sum().sum() == 0, "Clean frame should have no missing values"
assert len(frame_inscope) < len(frame), "Cleaning should reduce frame size"
print("\n[PASS] Frame cleaning pipeline completed successfully.")


# ============================================================
# USE IT: Production Frame Cleaning with pandas
# ============================================================

# In production, load the full 500K frame:
# frame = pd.read_csv('census_frame.csv')

np.random.seed(42)
N_prod = 100000
frame_prod = pd.DataFrame({
    'hh_id': [f'HH_{i:07d}' for i in range(N_prod)],
    'gov_id': np.random.choice(['GOV_01','GOV_02','GOV_03'], N_prod),
    'ea_id': np.random.choice([f'EA_{e:05d}' for e in range(800)], N_prod),
    'hh_size': np.random.poisson(4, N_prod).clip(1),
    'status': np.random.choice(
        ['Occupied','Vacant','Demolished'], N_prod, p=[0.97, 0.02, 0.01])
})

pipeline_log = []

# Step 1: Deduplication
before = len(frame_prod)
frame_prod = frame_prod.drop_duplicates(subset=['gov_id', 'ea_id', 'hh_size'], keep='first')
removed = before - len(frame_prod)
pipeline_log.append(f"Deduplication: removed {removed:,}")

# Step 2: Out-of-scope
before = len(frame_prod)
frame_prod = frame_prod[frame_prod['status'] == 'Occupied']
removed = before - len(frame_prod)
pipeline_log.append(f"Out-of-scope: removed {removed:,}")

# Step 3: Validate EA sizes
ea_sizes = frame_prod.groupby('ea_id').size()
small_eas = ea_sizes[ea_sizes < 30].index
large_eas = ea_sizes[ea_sizes > 200].index
pipeline_log.append(f"Undersized EAs (<30 HH): {len(small_eas)}")
pipeline_log.append(f"Oversized EAs (>200 HH): {len(large_eas)}")

print("\n=== PRODUCTION FRAME CLEANING PIPELINE LOG ===")
for entry in pipeline_log:
    print(f"  {entry}")
print(f"\n  Final clean frame: {len(frame_prod):,} records")
