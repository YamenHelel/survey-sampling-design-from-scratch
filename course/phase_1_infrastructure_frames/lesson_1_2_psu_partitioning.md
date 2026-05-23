<div dir="rtl" align="right">

# الدرس 1.2: تقسيم وتوحيد وحدات المعاينة الأولية (PSUs)

[→ الدرس السابق](lesson_1_1_frame_diagnostics.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي: المرحلة 2 ←](../phase_2_probability_designs/lesson_2_1_stratified_opt_allocation.md)

---

## 1. الشعار (Motto)

> **"مناطق العد ليست مقدسة — إذا كانت صغيرة جداً ادمجها، وإذا كانت كبيرة جداً قسِّمها."**
>
> التحكم في حجم وحدات المعاينة الأولية هو الفرق بين عينة متوازنة وعينة مشوهة.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

فريق المعاينة في مكتب الإحصاء يراجع إطار مناطق العد (*Enumeration Areas - EAs*) استعداداً لمسح القوى العاملة. الإطار يحتوي **4,500 منطقة عد** بأحجام متفاوتة بشدة:

- **340 منطقة** تحتوي أقل من 30 أسرة (صغيرة جداً للمعاينة المنتظمة)
- **85 منطقة** تحتوي أكثر من 300 أسرة (كبيرة جداً وتخلق تجانساً مفرطاً داخل العنقود)

المطلوب: **توحيد** (*Harmonize*) أحجام PSUs بحيث تحتوي كل وحدة بين **80 و 150 أسرة**.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 لماذا التحكم في حجم PSU مهم؟

أثر التصميم (*Design Effect*) يعتمد مباشرة على حجم العنقود:

$$Deff = 1 + (\bar{m} - 1)\rho$$

حيث $\bar{m}$ هو متوسط حجم العنقود و $\rho$ هو معامل الارتباط داخل العنقود (*ICC*).

- إذا كانت PSU كبيرة جداً ($\bar{m}$ مرتفع) ← $Deff$ يرتفع ← التباين يتضخم
- إذا كانت PSU صغيرة جداً ← مشاكل تشغيلية ← لا يمكن سحب عدد كافٍ من الأسر

### 3.2 قواعد الدمج والتقسيم

**قاعدة الدمج** (*Merging*): إذا كان حجم EA < $m_{min}$:
1. ابحث عن EA مجاورة جغرافياً في نفس المنطقة الإدارية
2. ادمجهما في PSU واحدة بشرط: $m_{merged} \leq m_{max}$

**قاعدة التقسيم** (*Splitting*): إذا كان حجم EA > $m_{max}$:
$$k = \lceil m_{EA} / m_{target} \rceil$$
قسِّم EA إلى $k$ وحدات فرعية متساوية تقريباً.

### 3.3 مقياس الجودة: معامل الاختلاف لأحجام PSUs

$$CV_{size} = \frac{SD(m_i)}{\bar{m}} \times 100\%$$

الهدف: $CV_{size} < 30\%$ بعد التوحيد.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 1.2: PSU Partitioning & Harmonization
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Generate EA frame with problematic sizes ---
n_eas <- 4500
eas <- data.frame(
  ea_id   = sprintf("EA_%04d", 1:n_eas),
  dist_id = sample(sprintf("DIST_%03d", 1:120), n_eas, replace = TRUE),
  n_hh    = NA_integer_,
  stringsAsFactors = FALSE
)

# Generate sizes: mix of small, normal, and large
eas$n_hh <- c(
  rpois(340, lambda = 20),                       # Small EAs
  rpois(n_eas - 340 - 85, lambda = 110),          # Normal EAs
  rpois(85, lambda = 400)                          # Large EAs
)
eas$n_hh <- pmax(eas$n_hh, 5)  # Minimum 5 households

# --- Configuration ---
M_MIN <- 80
M_MAX <- 150
M_TARGET <- 110

cat("============================================================\n")
cat("  PSU HARMONIZATION ENGINE\n")
cat("============================================================\n\n")

cat("--- BEFORE Harmonization ---\n")
cat(sprintf("  Total EAs        : %d\n", nrow(eas)))
cat(sprintf("  Size range       : [%d, %d]\n", min(eas$n_hh), max(eas$n_hh)))
cat(sprintf("  Mean size        : %.1f\n", mean(eas$n_hh)))
cat(sprintf("  CV of sizes      : %.1f%%\n", sd(eas$n_hh) / mean(eas$n_hh) * 100))
cat(sprintf("  Undersized (<%d) : %d\n", M_MIN, sum(eas$n_hh < M_MIN)))
cat(sprintf("  Oversized (>%d)  : %d\n", M_MAX, sum(eas$n_hh > M_MAX)))

# ============================================================
# STEP 1: SPLIT OVERSIZED EAs
# ============================================================

cat("\n--- STEP 1: Splitting oversized EAs ---\n")

split_results <- data.frame()
n_splits <- 0

for (i in 1:nrow(eas)) {
  if (eas$n_hh[i] > M_MAX) {
    # Determine number of sub-units
    k <- ceiling(eas$n_hh[i] / M_TARGET)
    base_size <- floor(eas$n_hh[i] / k)
    remainder <- eas$n_hh[i] - base_size * k

    for (j in 1:k) {
      sub_size <- base_size + ifelse(j <= remainder, 1, 0)
      split_results <- rbind(split_results, data.frame(
        psu_id  = sprintf("%s_S%d", eas$ea_id[i], j),
        dist_id = eas$dist_id[i],
        n_hh    = sub_size,
        origin  = "split",
        stringsAsFactors = FALSE
      ))
    }
    n_splits <- n_splits + 1
  } else {
    split_results <- rbind(split_results, data.frame(
      psu_id  = eas$ea_id[i],
      dist_id = eas$dist_id[i],
      n_hh    = eas$n_hh[i],
      origin  = "original",
      stringsAsFactors = FALSE
    ))
  }
}

cat(sprintf("  EAs split: %d -> %d sub-units\n",
            n_splits, sum(split_results$origin == "split")))

# ============================================================
# STEP 2: MERGE UNDERSIZED PSUs
# ============================================================

cat("\n--- STEP 2: Merging undersized PSUs ---\n")

psu_frame <- split_results
psu_frame$merged_into <- NA_character_
n_merges <- 0

# Process district by district
for (d in unique(psu_frame$dist_id)) {
  dist_mask <- psu_frame$dist_id == d
  dist_psus <- which(dist_mask)

  # Find undersized PSUs in this district
  undersized <- dist_psus[psu_frame$n_hh[dist_psus] < M_MIN &
                           is.na(psu_frame$merged_into[dist_psus])]

  while (length(undersized) > 0) {
    current <- undersized[1]

    # Find best merge partner: closest in size, not already merged
    candidates <- dist_psus[is.na(psu_frame$merged_into[dist_psus]) &
                             dist_psus != current]

    if (length(candidates) == 0) break

    # Pick candidate whose combined size is closest to target
    combined_sizes <- psu_frame$n_hh[current] + psu_frame$n_hh[candidates]
    best_idx <- which.min(abs(combined_sizes - M_TARGET))
    partner <- candidates[best_idx]

    # Check if merge wouldn't exceed max
    new_size <- psu_frame$n_hh[current] + psu_frame$n_hh[partner]

    if (new_size <= M_MAX * 1.2) {  # Allow slight overshoot
      psu_frame$n_hh[partner] <- new_size
      psu_frame$merged_into[current] <- psu_frame$psu_id[partner]
      psu_frame$psu_id[partner] <- sprintf("%s+%s",
                                            psu_frame$psu_id[partner],
                                            psu_frame$psu_id[current])
      psu_frame$origin[partner] <- "merged"
      n_merges <- n_merges + 1
    }

    # Remove current from undersized list
    undersized <- undersized[-1]

    # Refresh undersized list
    undersized <- dist_psus[psu_frame$n_hh[dist_psus] < M_MIN &
                             is.na(psu_frame$merged_into[dist_psus])]
  }
}

# Remove merged-away PSUs
final_psus <- psu_frame[is.na(psu_frame$merged_into), ]
cat(sprintf("  Merges performed: %d\n", n_merges))

# ============================================================
# RESULTS
# ============================================================

cat("\n--- AFTER Harmonization ---\n")
cat(sprintf("  Total PSUs       : %d\n", nrow(final_psus)))
cat(sprintf("  Size range       : [%d, %d]\n",
            min(final_psus$n_hh), max(final_psus$n_hh)))
cat(sprintf("  Mean size        : %.1f\n", mean(final_psus$n_hh)))
cat(sprintf("  CV of sizes      : %.1f%%\n",
            sd(final_psus$n_hh) / mean(final_psus$n_hh) * 100))
cat(sprintf("  Still undersized : %d\n", sum(final_psus$n_hh < M_MIN)))
cat(sprintf("  Still oversized  : %d\n", sum(final_psus$n_hh > M_MAX)))

# Total households should be preserved
total_before <- sum(eas$n_hh)
total_after <- sum(final_psus$n_hh)
stopifnot(total_before == total_after)
cat(sprintf("\n  Total HH preserved: %s = %s [PASS]\n",
            format(total_before, big.mark = ","),
            format(total_after, big.mark = ",")))
```

### Python — من الصفر

```python
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
```

---

## 5. استخدمها (Use It — Production Frameworks)

في الممارسة الفعلية، يُستخدم نظام المعلومات الجغرافية (*GIS*) لضمان أن الدمج يحترم التجاور الجغرافي. لا توجد حزمة R/Python متخصصة لتوحيد PSUs تلقائياً — هذه العملية تبقى شبه يدوية في معظم مكاتب الإحصاء مع دعم من أدوات مثل `sf` في R أو `geopandas` في Python.

```r
# ============================================================
# Using sf package for geographic adjacency checking
# ============================================================

# library(sf)
#
# # Load EA boundary shapefile
# ea_boundaries <- st_read("ea_boundaries.shp")
#
# # Find adjacent EAs
# adjacency <- st_touches(ea_boundaries)
#
# # For each undersized EA, find adjacent candidates
# for (i in which(ea_boundaries$n_hh < M_MIN)) {
#   neighbors <- adjacency[[i]]
#   # Merge with smallest adjacent neighbor
#   ...
# }
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: psu_harmonizer.py
# Reusable PSU harmonization engine
# ============================================================

import pandas as pd
import numpy as np


def harmonize_psus(ea_frame: pd.DataFrame,
                   size_col: str = 'n_hh',
                   geo_col: str = 'dist_id',
                   id_col: str = 'ea_id',
                   m_min: int = 80,
                   m_max: int = 150,
                   m_target: int = 110) -> pd.DataFrame:
    """
    Harmonize PSU sizes by splitting oversized and merging undersized EAs.

    Parameters
    ----------
    ea_frame : DataFrame with EA-level data
    size_col : column containing household counts
    geo_col  : column for geographic grouping (merges within same group)
    id_col   : EA identifier column
    m_min    : minimum acceptable PSU size
    m_max    : maximum acceptable PSU size
    m_target : target PSU size for splitting

    Returns
    -------
    DataFrame with harmonized PSUs
    """
    total_hh_before = ea_frame[size_col].sum()

    # Step 1: Split
    records = []
    for _, row in ea_frame.iterrows():
        if row[size_col] > m_max:
            k = int(np.ceil(row[size_col] / m_target))
            base = row[size_col] // k
            rem = row[size_col] - base * k
            for j in range(k):
                records.append({
                    'psu_id': f"{row[id_col]}_S{j+1}",
                    geo_col: row[geo_col],
                    size_col: base + (1 if j < rem else 0)
                })
        else:
            records.append({
                'psu_id': row[id_col],
                geo_col: row[geo_col],
                size_col: row[size_col]
            })

    psus = pd.DataFrame(records)
    psus['active'] = True

    # Step 2: Merge within geography
    for geo in psus[geo_col].unique():
        geo_mask = (psus[geo_col] == geo) & psus['active']
        while True:
            undersized = psus.index[geo_mask & (psus[size_col] < m_min)]
            if len(undersized) == 0:
                break
            curr = undersized[0]
            cands = psus.index[
                geo_mask & (psus.index != curr) &
                (psus[size_col] + psus.loc[curr, size_col] <= m_max * 1.2)
            ]
            if len(cands) == 0:
                break
            combined = psus.loc[cands, size_col] + psus.loc[curr, size_col]
            best = cands[np.abs(combined - m_target).argmin()]
            psus.loc[best, size_col] += psus.loc[curr, size_col]
            psus.loc[best, 'psu_id'] += f"+{psus.loc[curr, 'psu_id']}"
            psus.loc[curr, 'active'] = False
            geo_mask = (psus[geo_col] == geo) & psus['active']

    result = psus[psus['active']].drop(columns=['active']).reset_index(drop=True)

    # Verify
    assert result[size_col].sum() == total_hh_before, "HH count mismatch!"
    return result
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | النقطة الجوهرية |
|-----------------|-------------------|----------------|
| وحدة المعاينة الأولية | Primary Sampling Unit (PSU) | الوحدة الأساسية في التصميم العنقودي |
| منطقة العد | Enumeration Area (EA) | الوحدة الجغرافية من التعداد |
| الدمج | Merging | توحيد EAs صغيرة في PSU واحدة |
| التقسيم | Splitting | تجزئة EAs كبيرة إلى وحدات فرعية |
| معامل الاختلاف | Coefficient of Variation | $CV < 30\%$ هدف التوحيد |

---

[→ الدرس السابق](lesson_1_1_frame_diagnostics.md) | [العودة إلى الفهرس](../../README.md) | [المرحلة 2 ←](../phase_2_probability_designs/lesson_2_1_stratified_opt_allocation.md)

</div>
