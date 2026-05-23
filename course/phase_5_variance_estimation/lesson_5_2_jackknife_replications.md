<div dir="rtl" align="right">

# الدرس 5.2: محركات إعادة المعاينة — جاكنايف وبوتستراب

[→ الدرس السابق](lesson_5_1_taylor_linearization.md) | [العودة إلى الفهرس](../../README.md)

---

## 1. الشعار (Motto)

> **"عندما لا تستطيع اشتقاق صيغة رياضية للتباين — اترك البيانات تحسبه بنفسها."**
>
> إعادة المعاينة تُقدِّر التباين لأي مؤشر مهما كان تعقيده — بما في ذلك الوسيط ومعامل جيني.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء يحتاج لنشر **معامل جيني** (*Gini Coefficient*) و **الوسيط** (*Median*) للدخل مع أخطائها المعيارية. المشكلة:
- معامل جيني دالة **غير قابلة للاشتقاق** بالطريقة التقليدية (لا يمكن تطبيق تايلور مباشرة)
- الوسيط دالة **غير ملساء** (*Non-Smooth Function*)

الحل: استخدام طرق **إعادة المعاينة** (*Resampling Methods*) التي لا تحتاج لصيغة رياضية صريحة.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 جاكنايف الحذف الواحد (Delete-One Jackknife)

لمسح عنقودي بـ $a$ وحدة PSU:
1. كرِّر $a$ مرة: في كل مرة $k$، احذف PSU رقم $k$ وأعِد حساب المقدِّر $\hat{\theta}_{(k)}$
2. تباين جاكنايف:

$$\widehat{Var}_{JK}(\hat{\theta}) = \frac{a - 1}{a} \sum_{k=1}^{a} (\hat{\theta}_{(k)} - \bar{\hat{\theta}})^2$$

حيث $\bar{\hat{\theta}} = \frac{1}{a} \sum_{k=1}^{a} \hat{\theta}_{(k)}$

### 3.2 جاكنايف مع طبقات (Stratified Jackknife)

لكل طبقة $h$ بها $a_h$ وحدات PSU:

$$\widehat{Var}_{JK} = \sum_{h=1}^{H} \frac{a_h - 1}{a_h} \sum_{k=1}^{a_h} (\hat{\theta}_{(hk)} - \bar{\hat{\theta}}_h)^2$$

### 3.3 بوتستراب المسوح (Survey Bootstrap)

1. داخل كل طبقة: أعِد معاينة $a_h - 1$ وحدة PSU مع الإرجاع من $a_h$ وحدة
2. عدِّل الأوزان: $w_i^{(r)} = w_i \times \frac{a_h}{a_h - 1} \times m_i^{(r)}$
   حيث $m_i^{(r)}$ = عدد مرات ظهور PSU $i$ في العينة المعادة $r$
3. كرِّر $B$ مرة (عادة 200-500)
4. التباين = تباين التقديرات عبر التكرارات

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 5.2: Jackknife & Bootstrap Variance Estimation
# R — From Scratch (No survey package)
# ============================================================

set.seed(2024)

# --- Generate stratified cluster sample ---
H <- 3
a_per_h <- 25
b <- 20

sample_data <- data.frame()
psu_counter <- 0

for (h in 1:H) {
  for (i in 1:a_per_h) {
    psu_counter <- psu_counter + 1
    psu_mean <- rnorm(1, mean = 1500 + h * 300, sd = 200)
    psu_data <- data.frame(
      stratum = h,
      psu_id  = psu_counter,
      income  = pmax(100, rnorm(b, psu_mean, 400)),
      weight  = 500,
      stringsAsFactors = FALSE
    )
    sample_data <- rbind(sample_data, psu_data)
  }
}

n <- nrow(sample_data)
cat(sprintf("Sample: %d obs, %d strata, %d PSUs\n",
            n, H, H * a_per_h))

# Full-sample estimates
full_mean   <- weighted.mean(sample_data$income, sample_data$weight)
full_median <- median(rep(sample_data$income,
                          round(sample_data$weight / min(sample_data$weight))))

# Gini coefficient (weighted)
weighted_gini <- function(x, w) {
  valid <- !is.na(x) & !is.na(w)
  x <- x[valid]; w <- w[valid]
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  n_w <- sum(w)
  cum_w <- cumsum(w)
  cum_wx <- cumsum(w * x)
  total_wx <- sum(w * x)
  1 - 2 * sum(w * cum_wx) / (n_w * total_wx) +
    sum(w * w * x) / (n_w * total_wx)
}

full_gini <- weighted_gini(sample_data$income, sample_data$weight)

cat(sprintf("\nFull-sample estimates:\n"))
cat(sprintf("  Mean   : %.2f\n", full_mean))
cat(sprintf("  Gini   : %.4f\n", full_gini))

# ============================================================
# DELETE-ONE JACKKNIFE (stratified)
# ============================================================

cat("\n============================================================\n")
cat("  DELETE-ONE JACKKNIFE\n")
cat("============================================================\n")

jk_mean <- numeric(0)
jk_gini <- numeric(0)

for (h in 1:H) {
  h_data <- sample_data[sample_data$stratum == h, ]
  psus <- unique(h_data$psu_id)
  a_h <- length(psus)

  for (k in seq_along(psus)) {
    # Delete PSU k, rescale remaining weights
    keep <- sample_data$psu_id != psus[k]

    # Rescale weights within this stratum
    jk_data <- sample_data[keep, ]
    jk_data$jk_weight <- jk_data$weight
    remaining_h <- jk_data$stratum == h
    jk_data$jk_weight[remaining_h] <- jk_data$jk_weight[remaining_h] *
      a_h / (a_h - 1)

    jk_mean <- c(jk_mean, weighted.mean(jk_data$income, jk_data$jk_weight))
    jk_gini <- c(jk_gini, weighted_gini(jk_data$income, jk_data$jk_weight))
  }
}

a_total <- H * a_per_h

# Jackknife variance (stratified formula)
var_jk_mean <- ((a_total - 1) / a_total) * sum((jk_mean - mean(jk_mean))^2)
var_jk_gini <- ((a_total - 1) / a_total) * sum((jk_gini - mean(jk_gini))^2)

se_jk_mean <- sqrt(var_jk_mean)
se_jk_gini <- sqrt(var_jk_gini)

cat(sprintf("\n  Jackknife SE(mean): %.4f (CV: %.1f%%)\n",
            se_jk_mean, se_jk_mean / full_mean * 100))
cat(sprintf("  Jackknife SE(Gini): %.6f (CV: %.1f%%)\n",
            se_jk_gini, se_jk_gini / full_gini * 100))

# ============================================================
# SURVEY BOOTSTRAP
# ============================================================

cat("\n============================================================\n")
cat("  SURVEY BOOTSTRAP\n")
cat("============================================================\n")

B <- 500  # Bootstrap replications
boot_mean <- numeric(B)
boot_gini <- numeric(B)

for (r in 1:B) {
  boot_data <- sample_data
  boot_data$boot_weight <- boot_data$weight

  for (h in 1:H) {
    h_mask <- boot_data$stratum == h
    h_data <- boot_data[h_mask, ]
    psus <- unique(h_data$psu_id)
    a_h <- length(psus)

    # Resample a_h - 1 PSUs with replacement
    resampled <- sample(psus, a_h - 1, replace = TRUE)

    # Count occurrences
    counts <- table(factor(resampled, levels = psus))

    for (p in psus) {
      p_mask <- h_mask & boot_data$psu_id == p
      m_star <- as.numeric(counts[as.character(p)])
      boot_data$boot_weight[p_mask] <- boot_data$weight[p_mask] *
        (a_h / (a_h - 1)) * m_star
    }
  }

  # Keep only units with positive weight
  boot_active <- boot_data[boot_data$boot_weight > 0, ]

  boot_mean[r] <- weighted.mean(boot_active$income, boot_active$boot_weight)
  boot_gini[r] <- weighted_gini(boot_active$income, boot_active$boot_weight)
}

se_boot_mean <- sd(boot_mean)
se_boot_gini <- sd(boot_gini)

cat(sprintf("\n  Bootstrap SE(mean) [B=%d]: %.4f (CV: %.1f%%)\n",
            B, se_boot_mean, se_boot_mean / full_mean * 100))
cat(sprintf("  Bootstrap SE(Gini) [B=%d]: %.6f (CV: %.1f%%)\n",
            B, se_boot_gini, se_boot_gini / full_gini * 100))

# ============================================================
# COMPARISON
# ============================================================

cat("\n============================================================\n")
cat("  COMPARISON: Jackknife vs Bootstrap\n")
cat("============================================================\n")
cat(sprintf("  %-20s | %-15s | %-15s\n", "Statistic", "JK SE", "Boot SE"))
cat(paste(rep("-", 55), collapse = ""), "\n")
cat(sprintf("  %-20s | %15.4f | %15.4f\n", "Mean", se_jk_mean, se_boot_mean))
cat(sprintf("  %-20s | %15.6f | %15.6f\n", "Gini", se_jk_gini, se_boot_gini))

# They should be in the same ballpark
ratio_mean <- se_jk_mean / se_boot_mean
ratio_gini <- se_jk_gini / se_boot_gini
cat(sprintf("\n  SE ratio (JK/Boot) for mean: %.2f\n", ratio_mean))
cat(sprintf("  SE ratio (JK/Boot) for Gini: %.2f\n", ratio_gini))

stopifnot(ratio_mean > 0.5 && ratio_mean < 2.0)
cat("\n[PASS] JK and Bootstrap SEs are consistent.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 5.2: Jackknife & Bootstrap from Scratch
# Python
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# --- Generate sample ---
H = 3
a_per_h = 25
b = 20
records = []
psu_counter = 0

for h in range(1, H + 1):
    for i in range(a_per_h):
        psu_counter += 1
        psu_mean = np.random.normal(1500 + h * 300, 200)
        for j in range(b):
            records.append({
                'stratum': h, 'psu_id': psu_counter,
                'income': max(100, np.random.normal(psu_mean, 400)),
                'weight': 500.0
            })

df = pd.DataFrame(records)
print(f"Sample: {len(df)} obs, {H} strata, {psu_counter} PSUs")


def weighted_gini(x, w):
    valid = ~(np.isnan(x) | np.isnan(w))
    x, w = x[valid], w[valid]
    order = np.argsort(x)
    x, w = x[order], w[order]
    cum_w = np.cumsum(w)
    cum_wx = np.cumsum(w * x)
    total_wx = np.sum(w * x)
    n_w = np.sum(w)
    return 1 - 2 * np.sum(w * cum_wx) / (n_w * total_wx) + \
           np.sum(w**2 * x) / (n_w * total_wx)


full_mean = np.average(df['income'], weights=df['weight'])
full_gini = weighted_gini(df['income'].values, df['weight'].values)
print(f"\nFull-sample: mean={full_mean:.2f}, Gini={full_gini:.4f}")

# --- Jackknife ---
print("\n" + "=" * 50)
print("  JACKKNIFE")
print("=" * 50)

jk_mean, jk_gini = [], []
a_total = H * a_per_h

for h in range(1, H + 1):
    h_psus = df[df['stratum'] == h]['psu_id'].unique()
    a_h = len(h_psus)

    for k, drop_psu in enumerate(h_psus):
        jk_df = df[df['psu_id'] != drop_psu].copy()
        # Rescale within stratum
        mask = jk_df['stratum'] == h
        jk_df.loc[mask, 'weight'] = jk_df.loc[mask, 'weight'] * a_h / (a_h - 1)

        jk_mean.append(np.average(jk_df['income'], weights=jk_df['weight']))
        jk_gini.append(weighted_gini(jk_df['income'].values, jk_df['weight'].values))

jk_mean = np.array(jk_mean)
jk_gini = np.array(jk_gini)

se_jk_mean = np.sqrt((a_total - 1) / a_total * np.sum((jk_mean - jk_mean.mean())**2))
se_jk_gini = np.sqrt((a_total - 1) / a_total * np.sum((jk_gini - jk_gini.mean())**2))

print(f"  JK SE(mean): {se_jk_mean:.4f}")
print(f"  JK SE(Gini): {se_jk_gini:.6f}")

# --- Bootstrap ---
print("\n" + "=" * 50)
print("  BOOTSTRAP")
print("=" * 50)

B_reps = 500
boot_mean = np.zeros(B_reps)
boot_gini = np.zeros(B_reps)

for r in range(B_reps):
    boot_w = df['weight'].values.copy()

    for h in range(1, H + 1):
        h_mask = df['stratum'].values == h
        h_psus = df.loc[h_mask, 'psu_id'].unique()
        a_h = len(h_psus)

        resampled = np.random.choice(h_psus, a_h - 1, replace=True)
        unique_r, counts = np.unique(resampled, return_counts=True)
        count_map = dict(zip(unique_r, counts))

        for p in h_psus:
            p_mask = h_mask & (df['psu_id'].values == p)
            m_star = count_map.get(p, 0)
            boot_w[p_mask] = df['weight'].values[p_mask] * (a_h / (a_h - 1)) * m_star

    active = boot_w > 0
    boot_mean[r] = np.average(df['income'].values[active], weights=boot_w[active])
    boot_gini[r] = weighted_gini(df['income'].values[active], boot_w[active])

se_boot_mean = np.std(boot_mean, ddof=1)
se_boot_gini = np.std(boot_gini, ddof=1)

print(f"  Boot SE(mean): {se_boot_mean:.4f}")
print(f"  Boot SE(Gini): {se_boot_gini:.6f}")

# --- Compare ---
print(f"\n--- Comparison ---")
print(f"  SE(mean) ratio JK/Boot: {se_jk_mean/se_boot_mean:.2f}")
print(f"  SE(Gini) ratio JK/Boot: {se_jk_gini/se_boot_gini:.2f}")

assert 0.5 < se_jk_mean / se_boot_mean < 2.0
print("\n[PASS] JK and Bootstrap are consistent.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey

```r
library(survey)

design <- svydesign(id = ~psu_id, strata = ~stratum,
                    weights = ~weight, data = sample_data, nest = TRUE)

# Jackknife replicate design
jk_design <- as.svrepdesign(design, type = "JK1")

est_mean_jk <- svymean(~income, jk_design)
cat(sprintf("JK svymean: %.4f (SE: %.4f)\n", coef(est_mean_jk), SE(est_mean_jk)))

# Compare
cat(sprintf("Manual JK SE: %.4f\n", se_jk_mean))
stopifnot(abs(SE(est_mean_jk) - se_jk_mean) / se_jk_mean < 0.15)
cat("[PASS] Manual JK consistent with survey package.\n")
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: resampling_variance.py
# ============================================================

import numpy as np
from typing import Callable, Dict


class ResamplingVariance:
    """Compute variance via Jackknife or Bootstrap for survey data."""

    def __init__(self, data: np.ndarray, weights: np.ndarray,
                 psu_ids: np.ndarray, stratum_ids: np.ndarray):
        self.data = data
        self.weights = weights
        self.psu_ids = psu_ids
        self.stratum_ids = stratum_ids

    def jackknife(self, estimator_fn: Callable) -> Dict:
        strata = np.unique(self.stratum_ids)
        jk_estimates = []

        for h in strata:
            h_mask = self.stratum_ids == h
            h_psus = np.unique(self.psu_ids[h_mask])
            a_h = len(h_psus)

            for drop_psu in h_psus:
                keep = self.psu_ids != drop_psu
                jk_w = self.weights.copy()
                rescale = keep & (self.stratum_ids == h)
                jk_w[rescale] *= a_h / (a_h - 1)
                jk_w[~keep] = 0

                active = jk_w > 0
                est = estimator_fn(self.data[active], jk_w[active])
                jk_estimates.append(est)

        jk_estimates = np.array(jk_estimates)
        a_total = len(jk_estimates)
        jk_mean = jk_estimates.mean()
        var_jk = (a_total - 1) / a_total * np.sum((jk_estimates - jk_mean)**2)

        return {'se': np.sqrt(var_jk), 'variance': var_jk,
                'n_replicates': a_total}

    def bootstrap(self, estimator_fn: Callable, B: int = 500,
                  seed: int = None) -> Dict:
        if seed:
            np.random.seed(seed)

        strata = np.unique(self.stratum_ids)
        boot_estimates = np.zeros(B)

        for r in range(B):
            boot_w = self.weights.copy()
            for h in strata:
                h_mask = self.stratum_ids == h
                h_psus = np.unique(self.psu_ids[h_mask])
                a_h = len(h_psus)

                resampled = np.random.choice(h_psus, a_h - 1, replace=True)
                _, counts = np.unique(resampled, return_counts=True)
                count_map = dict(zip(*np.unique(resampled, return_counts=True)))

                for p in h_psus:
                    p_mask = h_mask & (self.psu_ids == p)
                    m = count_map.get(p, 0)
                    boot_w[p_mask] = self.weights[p_mask] * (a_h/(a_h-1)) * m

            active = boot_w > 0
            boot_estimates[r] = estimator_fn(self.data[active], boot_w[active])

        return {'se': np.std(boot_estimates, ddof=1),
                'variance': np.var(boot_estimates, ddof=1),
                'n_replicates': B,
                'ci_95': (np.percentile(boot_estimates, 2.5),
                          np.percentile(boot_estimates, 97.5))}
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | النقطة الجوهرية |
|-----------------|-------------------|----------------|
| جاكنايف الحذف الواحد | Delete-One Jackknife | حذف PSU واحد في كل مرة |
| بوتستراب المسوح | Survey Bootstrap | إعادة معاينة PSUs مع الإرجاع |
| التقدير المتكرر | Replicate Estimation | لا تحتاج صيغة تحليلية |
| معامل جيني | Gini Coefficient | مؤشر غير قابل للتخطيط بتايلور |
| الوسيط | Median | دالة غير ملساء |

---

[→ الدرس السابق](lesson_5_1_taylor_linearization.md) | [العودة إلى الفهرس](../../README.md)

</div>
