<div dir="rtl" align="right">

# الدرس 2.3: محرك المعاينة العنقودية متعددة المراحل

[→ الدرس السابق](lesson_2_2_systematic_pps.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي: المرحلة 3 ←](../phase_3_sample_size_calibration/lesson_3_1_cochran_extensions.md)

---

## 1. الشعار (Motto)

> **"لا تُعاين أسراً — عاين عناقيد أولاً، ثم أسراً داخل العناقيد المختارة."**
>
> المعاينة متعددة المراحل هي القلب النابض لكل مسح أسري وطني في العالم.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء ينفذ المسح العنقودي متعدد المؤشرات (*MICS*) بميزانية تغطي **180 فريقاً ميدانياً**، كل فريق يستطيع زيارة **15 أسرة** في منطقة عد واحدة. التصميم المطلوب:

- **المرحلة 1:** اختيار 180 منطقة عد (PSU) بطريقة PPS المنتظمة
- **المرحلة 2:** اختيار 15 أسرة (SSU) من كل منطقة مختارة بالمعاينة المنتظمة

إجمالي العينة: $180 \times 15 = 2,700$ أسرة.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 احتمال الاشتمال الكلي (Overall Inclusion Probability)

في التصميم ثنائي المراحل، احتمال اشتمال الأسرة $j$ في المنطقة $i$:

$$\pi_{ij} = \pi_i^{(1)} \times \pi_{j|i}^{(2)}$$

حيث:
- $\pi_i^{(1)} = a \times M_i / M_{\cdot}$ — احتمال اختيار PSU (المرحلة 1)
- $\pi_{j|i}^{(2)} = b / M_i$ — احتمال اختيار الأسرة داخل PSU المختارة (المرحلة 2)

### 3.2 الوزن الكلي

$$w_{ij} = \frac{1}{\pi_{ij}} = \frac{1}{\pi_i^{(1)}} \times \frac{1}{\pi_{j|i}^{(2)}} = \frac{M_{\cdot}}{a \times M_i} \times \frac{M_i}{b} = \frac{M_{\cdot}}{a \times b}$$

**نتيجة مذهلة:** الوزن **ثابت** لجميع الأسر — تصميم ذاتي الوزن!

### 3.3 مقدِّر المتوسط تحت التصميم ثنائي المراحل

$$\hat{\bar{Y}} = \frac{\sum_{i \in s_1} \sum_{j \in s_2} w_{ij} \cdot y_{ij}}{\sum_{i \in s_1} \sum_{j \in s_2} w_{ij}}$$

### 3.4 تباين المقدِّر (تقريب أولي)

$$Var(\hat{\bar{Y}}) \approx \frac{1}{a(a-1)} \sum_{i=1}^{a} (z_i - \bar{z})^2$$

حيث $z_i = \sum_{j \in s_{2i}} w_{ij} y_{ij}$ هو إجمالي العنقود الموزون.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 2.3: Two-Stage Cluster Sampling Engine
# R — From Scratch (No survey/sampling packages)
# ============================================================

set.seed(2024)

# ============================================================
# STAGE 0: Generate population frame
# ============================================================

n_eas <- 4500
ea_sizes <- pmax(50, rpois(n_eas, lambda = 120))

# Generate household-level data within each EA
population <- data.frame()
for (i in 1:n_eas) {
  ea_data <- data.frame(
    ea_id    = sprintf("EA_%04d", i),
    ea_size  = ea_sizes[i],
    hh_id    = sprintf("EA_%04d_HH_%03d", i, 1:ea_sizes[i]),
    income   = pmax(0, rnorm(ea_sizes[i],
                              mean = rnorm(1, 1500, 500),
                              sd = abs(rnorm(1, 400, 100)))),
    employed = rbinom(ea_sizes[i], 1, prob = runif(1, 0.3, 0.8)),
    stringsAsFactors = FALSE
  )
  population <- rbind(population, ea_data)
}

N <- nrow(population)
theta_income <- mean(population$income)
theta_employ <- mean(population$employed)

cat(sprintf("Population size (N): %s\n", format(N, big.mark = ",")))
cat(sprintf("Number of EAs     : %d\n", n_eas))
cat(sprintf("True mean income  : %.2f\n", theta_income))
cat(sprintf("True employment   : %.4f (%.1f%%)\n",
            theta_employ, theta_employ * 100))

# ============================================================
# STAGE 1: PPS Systematic Selection of PSUs
# ============================================================

a <- 180  # PSUs to select
b <- 15   # HH per PSU

cat(sprintf("\n--- Stage 1: Select %d PSUs via PPS ---\n", a))

cumulative <- cumsum(ea_sizes)
M_total <- sum(ea_sizes)
interval <- M_total / a
R <- runif(1, 0, interval)
sel_points <- R + (0:(a-1)) * interval

selected_psu_idx <- integer(a)
for (k in 1:a) {
  selected_psu_idx[k] <- min(which(cumulative >= sel_points[k]))
}

# Stage 1 inclusion probabilities
pi_1 <- a * ea_sizes[selected_psu_idx] / M_total

cat(sprintf("  PSUs selected: %d\n", a))
cat(sprintf("  Pi_1 range   : [%.4f, %.4f]\n", min(pi_1), max(pi_1)))

# ============================================================
# STAGE 2: Systematic Random Sampling of HH within PSUs
# ============================================================

cat(sprintf("\n--- Stage 2: Select %d HH per PSU ---\n", b))

sample_data <- data.frame()

for (k in 1:a) {
  psu_id <- sprintf("EA_%04d", selected_psu_idx[k])

  # Get all HH in this PSU
  psu_hh <- population[population$ea_id == psu_id, ]
  M_i <- nrow(psu_hh)

  # Systematic sampling within PSU
  step <- M_i / b
  start <- runif(1, 1, step)
  hh_indices <- floor(start + (0:(b-1)) * step)
  hh_indices <- pmin(hh_indices, M_i)

  selected_hh <- psu_hh[hh_indices, ]

  # Stage 2 inclusion probability
  pi_2 <- b / M_i

  # Overall inclusion probability and weight
  selected_hh$pi_1 <- pi_1[k]
  selected_hh$pi_2 <- pi_2
  selected_hh$pi_overall <- pi_1[k] * pi_2
  selected_hh$weight <- 1 / (pi_1[k] * pi_2)
  selected_hh$psu_order <- k

  sample_data <- rbind(sample_data, selected_hh)
}

cat(sprintf("  Total HH selected: %d\n", nrow(sample_data)))
cat(sprintf("  Weight range     : [%.2f, %.2f]\n",
            min(sample_data$weight), max(sample_data$weight)))

# ============================================================
# ESTIMATION
# ============================================================

cat("\n--- ESTIMATION ---\n")

# Weighted mean income
est_income <- sum(sample_data$weight * sample_data$income) /
              sum(sample_data$weight)

# Weighted employment rate
est_employ <- sum(sample_data$weight * sample_data$employed) /
              sum(sample_data$weight)

cat(sprintf("  Est. mean income : %.2f (true: %.2f, diff: %.2f)\n",
            est_income, theta_income, est_income - theta_income))
cat(sprintf("  Est. employment  : %.4f (true: %.4f, diff: %.4f)\n",
            est_employ, theta_employ, est_employ - theta_employ))

# Self-weighting check
expected_w <- M_total / (a * b)
cat(sprintf("\n--- Self-Weighting Check ---\n"))
cat(sprintf("  Expected constant weight: %.2f\n", expected_w))
cat(sprintf("  Actual weight CV        : %.4f%%\n",
            sd(sample_data$weight) / mean(sample_data$weight) * 100))

stopifnot(all(abs(sample_data$weight - expected_w) / expected_w < 0.02))
cat("[PASS] Self-weighting property holds.\n")

# ============================================================
# VARIANCE ESTIMATION (Ultimate Cluster Approximation)
# ============================================================

cat("\n--- VARIANCE ESTIMATION ---\n")

# Compute cluster totals
z_income <- tapply(sample_data$weight * sample_data$income,
                   sample_data$psu_order, sum)
z_bar <- mean(z_income)

# Variance of weighted total
var_total <- (1 / (a * (a - 1))) * sum((z_income - z_bar)^2)
var_mean <- var_total / (sum(sample_data$weight))^2 * N^2

se_income <- sqrt(var_mean)
cv_income <- se_income / est_income * 100

cat(sprintf("  SE(mean income)  : %.2f\n", se_income))
cat(sprintf("  CV               : %.1f%%\n", cv_income))
cat(sprintf("  95%% CI           : [%.2f, %.2f]\n",
            est_income - 1.96 * se_income,
            est_income + 1.96 * se_income))
```

### Python — من الصفر

```python
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
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey

```r
# ============================================================
# Lesson 2.3: Two-Stage Design with survey package
# ============================================================

library(survey)

# Using sample_data from the scratch code above
# sample_data has columns: ea_id, income, employed, weight, psu_order

# Define two-stage design
design <- svydesign(
  id      = ~psu_order,           # PSU identifier (cluster)
  weights = ~weight,              # Sampling weights
  data    = sample_data
)

# Estimates
est_income_pkg <- svymean(~income, design)
est_employ_pkg <- svymean(~employed, design)

cat(sprintf("\n--- survey package estimates ---\n"))
cat(sprintf("  Income : %.4f (SE: %.4f)\n", coef(est_income_pkg), SE(est_income_pkg)))
cat(sprintf("  Employ : %.4f (SE: %.4f)\n", coef(est_employ_pkg), SE(est_employ_pkg)))

# Compare with manual
cat(sprintf("\n  Manual income : %.4f\n", est_income))
cat(sprintf("  Pkg income    : %.4f\n", coef(est_income_pkg)))
stopifnot(abs(coef(est_income_pkg) - est_income) < 0.01)
cat("[PASS] Manual matches survey package estimate.\n")
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
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
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الرمز |
|-----------------|-------------------|-------|
| المعاينة متعددة المراحل | Multi-Stage Sampling | PPS + SRS/Systematic |
| وحدة المعاينة الأولية | Primary Sampling Unit (PSU) | المرحلة الأولى |
| وحدة المعاينة الثانوية | Secondary Sampling Unit (SSU) | الأسر داخل PSU |
| الاحتمال الكلي | Overall Inclusion Probability | $\pi_{ij} = \pi_i^{(1)} \times \pi_{j|i}^{(2)}$ |
| تقريب العنقود النهائي | Ultimate Cluster Approximation | التباين يُحسب على مستوى PSU |

---

[→ الدرس السابق](lesson_2_2_systematic_pps.md) | [العودة إلى الفهرس](../../README.md) | [المرحلة 3 ←](../phase_3_sample_size_calibration/lesson_3_1_cochran_extensions.md)

</div>
