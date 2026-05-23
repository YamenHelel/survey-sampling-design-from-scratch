<div dir="rtl" align="right">

# الدرس 2.2: السحب المنتظم بالاحتمال المتناسب مع الحجم (Systematic PPS)

[→ الدرس السابق](lesson_2_1_stratified_opt_allocation.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_2_3_multistage_engine.md)

---

## 1. الشعار (Motto)

> **"العناقيد الأكبر تحمل مسؤولية أكبر — امنحها فرصة اختيار أعلى، لكن اجعل أوزان الأسر متوازنة."**
>
> السحب المتناسب مع الحجم يضمن أن كل فرد — وليس كل عنقود — لديه نفس فرصة التمثيل.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء يختار 200 منطقة عد (*EA*) من إجمالي 4,500 منطقة لتكون المرحلة الأولى من مسح القوى العاملة. المناطق تتراوح أحجامها بين 30 و 450 أسرة.

إذا اخترنا بالاحتمال المتساوي (*Equal Probability*):
- منطقة بها 30 أسرة و منطقة بها 450 أسرة لهما نفس فرصة الاختيار
- لكن الأسرة في المنطقة الصغيرة ستكون ممثلة 15 ضعفاً مقارنة بالأسرة في المنطقة الكبيرة

**الحل:** السحب بالاحتمال المتناسب مع الحجم (*PPS*) يجعل احتمال اختيار المنطقة متناسباً مع عدد أسرها.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 احتمال الاشتمال تحت PPS

لاختيار $a$ وحدات PSU من $A$ وحدة بطريقة PPS المنتظمة:

$$\pi_i = a \times \frac{M_i}{\sum_{j=1}^{A} M_j} = a \times \frac{M_i}{M_{\cdot}}$$

حيث $M_i$ هو حجم (عدد أسر) المنطقة $i$.

### 3.2 طريقة الحجم التراكمي (Cumulative Size Method)

1. رتِّب المناطق واحسب الحجم التراكمي: $C_i = \sum_{j=1}^{i} M_j$
2. احسب فترة الاختيار: $I = M_{\cdot} / a$
3. اختر بداية عشوائية: $R \sim U(0, I)$
4. نقاط الاختيار: $S_k = R + (k-1) \times I$ حيث $k = 1, 2, ..., a$
5. اختر المنطقة $i$ إذا $C_{i-1} < S_k \leq C_i$

### 3.3 الميزة: الأوزان الذاتية التوازن

إذا سحبنا $b$ أسرة من كل PSU مختارة عبر SRS، فإن:

$$w_{ij} = \frac{1}{\pi_i} \times \frac{M_i}{b} = \frac{M_{\cdot}}{a \times M_i} \times \frac{M_i}{b} = \frac{M_{\cdot}}{a \times b}$$

**الوزن ثابت لجميع الأسر!** هذا يُسمى التصميم ذاتي الوزن (*Self-Weighting Design*).

---

## 4. ابنِها من الصفر (Build It From Scratch)

### Python — من الصفر

```python
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
```

### R — من الصفر

```r
# ============================================================
# Lesson 2.2: Systematic PPS Selection
# R — From Scratch (No sampling libraries)
# ============================================================

set.seed(2024)

# --- Generate EA frame ---
A <- 4500
a <- 200

ea_sizes <- c(
  rpois(300, lambda = 40),
  rpois(3900, lambda = 110),
  rpois(300, lambda = 350)
)
ea_sizes <- pmax(ea_sizes, 20)
ea_ids <- sprintf("EA_%04d", 1:A)

cat(sprintf("Total EAs: %d\n", A))
cat(sprintf("Size range: [%d, %d]\n", min(ea_sizes), max(ea_sizes)))
cat(sprintf("Total HH: %s\n", format(sum(ea_sizes), big.mark = ",")))

# ============================================================
# SYSTEMATIC PPS — FROM SCRATCH
# ============================================================

# Step 1: Cumulative sizes
cumulative <- cumsum(ea_sizes)
M_total <- sum(ea_sizes)

# Step 2: Interval
interval <- M_total / a

# Step 3: Random start
R <- runif(1, 0, interval)

# Step 4: Selection points
sel_points <- R + (0:(a-1)) * interval

# Step 5: Select EAs
selected <- integer(a)
for (k in 1:a) {
  selected[k] <- min(which(cumulative >= sel_points[k]))
}

# Inclusion probabilities
pi_i <- a * ea_sizes[selected] / M_total
base_weights <- 1 / pi_i

cat(sprintf("\n--- Selected Sample ---\n"))
cat(sprintf("  EAs selected: %d\n", length(selected)))
cat(sprintf("  Pi range    : [%.4f, %.4f]\n", min(pi_i), max(pi_i)))
cat(sprintf("  Weight range: [%.2f, %.2f]\n", min(base_weights), max(base_weights)))

# Self-weighting check
b <- 15
hh_weights <- base_weights * (ea_sizes[selected] / b)
expected_w <- M_total / (a * b)

cat(sprintf("\n--- Self-Weighting Check (b = %d) ---\n", b))
cat(sprintf("  Expected weight: %.2f\n", expected_w))
cat(sprintf("  Actual range   : [%.2f, %.2f]\n", min(hh_weights), max(hh_weights)))
cat(sprintf("  CV             : %.4f%%\n", sd(hh_weights) / mean(hh_weights) * 100))

stopifnot(all(abs(hh_weights - expected_w) / expected_w < 0.01))
cat("\n[PASS] Self-weighting property verified.\n")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة sampling

```r
# ============================================================
# Lesson 2.2: PPS Selection with sampling package
# ============================================================

library(sampling)

set.seed(2024)

A <- 4500
a <- 200
ea_sizes <- c(rpois(300, 40), rpois(3900, 110), rpois(300, 350))
ea_sizes <- pmax(ea_sizes, 20)

frame <- data.frame(
  ea_id = sprintf("EA_%04d", 1:A),
  size  = ea_sizes
)

# Inclusion probabilities
pik <- inclusionprobabilities(frame$size, a)

# Systematic PPS
s <- UPsystematic(pik)
selected_pkg <- frame[s == 1, ]

cat(sprintf("sampling::UPsystematic selected %d EAs\n", nrow(selected_pkg)))

# Compare with manual
# (Manual implementation already verified above)
cat(sprintf("  Size range: [%d, %d]\n",
            min(selected_pkg$size), max(selected_pkg$size)))

# Verify inclusion probabilities
manual_pi <- a * selected_pkg$size / sum(frame$size)
pkg_pi <- pik[s == 1]
max_diff <- max(abs(manual_pi - pkg_pi))
cat(sprintf("  Max pi difference (manual vs pkg): %.6f\n", max_diff))
stopifnot(max_diff < 1e-10)
cat("[PASS] Manual pi matches sampling package.\n")
```

### Python — samplics

```python
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
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
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
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الرمز |
|-----------------|-------------------|-------|
| الاحتمال المتناسب مع الحجم | Probability Proportional to Size (PPS) | $\pi_i \propto M_i$ |
| طريقة الحجم التراكمي | Cumulative Size Method | السحب المنتظم على المحور التراكمي |
| فترة الاختيار | Selection Interval | $I = M_{\cdot} / a$ |
| التصميم ذاتي الوزن | Self-Weighting Design | $w_{ij} = M_{\cdot}/(ab)$ ثابت |
| وحدات الاختيار الحتمي | Certainty Selections | $\pi_i \geq 1$ |

---

[→ الدرس السابق](lesson_2_1_stratified_opt_allocation.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_2_3_multistage_engine.md)

</div>
