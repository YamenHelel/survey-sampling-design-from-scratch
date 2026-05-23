<div dir="rtl" align="right">

# الدرس 3.2: تفكيك أثر التصميم ومعامل الارتباط داخل العنقود

[→ الدرس السابق](lesson_3_1_cochran_extensions.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي: المرحلة 4 ←](../phase_4_weighting_pipeline/lesson_4_1_design_weights.md)

---

## 1. الشعار (Motto)

> **"أثر التصميم يخبرك بالثمن الذي تدفعه مقابل راحة العنقدة — ومعامل الارتباط داخل العنقود يخبرك لماذا."**
>
> كلما كانت الوحدات داخل العنقود متشابهة أكثر ($\rho$ أعلى)، زاد ثمن العنقدة.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

فريق التصميم في مكتب الإحصاء يقارن بين سيناريوهين لمسح القوى العاملة:
- **السيناريو أ:** 300 عنقود × 10 أسر = 3,000 أسرة (فرق ميدانية أكثر، عناقيد أصغر)
- **السيناريو ب:** 150 عنقود × 20 أسرة = 3,000 أسرة (فرق أقل، عناقيد أكبر)

نفس حجم العينة الكلي! لكن أيهما يعطي دقة أعلى؟ ذلك يعتمد على $\rho$ — معامل الارتباط داخل العنقود (*Intraclass Correlation Coefficient - ICC*).

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 أثر التصميم (Design Effect)

$$Deff = \frac{Var(\hat{\theta}_{complex})}{Var(\hat{\theta}_{SRS})}$$

تحت المعاينة العنقودية البسيطة ذات الحجم المتساوي:

$$Deff = 1 + (\bar{m} - 1)\rho$$

حيث:
- $\bar{m}$ = متوسط حجم العنقود
- $\rho$ = معامل الارتباط داخل العنقود (ICC)

### 3.2 حساب ICC عبر مكونات تباين ANOVA

من تحليل التباين أحادي الاتجاه (*One-Way ANOVA*):

$$\rho = \frac{MSB - MSW}{MSB + (\bar{m} - 1) \cdot MSW}$$

حيث:
- $MSB = \frac{SSB}{k - 1}$ — متوسط مربعات بين العناقيد (*Mean Square Between*)
- $MSW = \frac{SSW}{n - k}$ — متوسط مربعات داخل العناقيد (*Mean Square Within*)
- $k$ = عدد العناقيد، $n$ = إجمالي المشاهدات

### 3.3 مكونات التباين

$$\sigma^2_{total} = \sigma^2_{between} + \sigma^2_{within}$$

$$\sigma^2_{between} = \frac{MSB - MSW}{\bar{m}}$$

$$\sigma^2_{within} = MSW$$

$$\rho = \frac{\sigma^2_{between}}{\sigma^2_{between} + \sigma^2_{within}}$$

### 3.4 تأثير $\rho$ على Deff

| $\rho$ | $\bar{m} = 10$ | $\bar{m} = 20$ | $\bar{m} = 30$ |
|--------|----------------|----------------|----------------|
| 0.01   | 1.09           | 1.19           | 1.29           |
| 0.05   | 1.45           | 1.95           | 2.45           |
| 0.10   | 1.90           | 2.90           | 3.90           |
| 0.20   | 2.80           | 4.80           | 6.80           |

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 3.2: Design Effect & ICC from Scratch
# R — Using ANOVA variance components
# ============================================================

set.seed(2024)

# --- Compute ICC from scratch using ANOVA ---
compute_icc_scratch <- function(y, cluster) {
  stopifnot(length(y) == length(cluster))
  valid <- !is.na(y) & !is.na(cluster)
  y <- y[valid]
  cluster <- as.factor(cluster[valid])

  grand_mean <- mean(y)
  clusters <- levels(cluster)
  k <- length(clusters)
  n_total <- length(y)

  # Cluster sizes and means
  cluster_sizes <- as.numeric(table(cluster))
  cluster_means <- tapply(y, cluster, mean)
  m_bar <- mean(cluster_sizes)

  # Sum of Squares Between (SSB)
  ssb <- sum(cluster_sizes * (cluster_means - grand_mean)^2)
  msb <- ssb / (k - 1)

  # Sum of Squares Within (SSW)
  ssw <- sum((y - ave(y, cluster, FUN = mean))^2)
  msw <- ssw / (n_total - k)

  # Variance components
  sigma2_between <- (msb - msw) / m_bar
  sigma2_within <- msw

  # ICC
  rho <- sigma2_between / (sigma2_between + sigma2_within)
  rho <- max(rho, -1 / (m_bar - 1))  # Bound

  list(
    rho     = rho,
    msb     = msb,
    msw     = msw,
    sigma2_b = sigma2_between,
    sigma2_w = sigma2_within,
    k       = k,
    m_bar   = m_bar,
    deff    = 1 + (m_bar - 1) * rho
  )
}

# ============================================================
# SIMULATION: Generate clustered population
# ============================================================

k <- 500         # Number of clusters
m <- 100         # HH per cluster
rho_true <- 0.08 # True ICC

# Generate with controlled ICC
sigma2_total <- 100
sigma2_between <- rho_true * sigma2_total
sigma2_within <- (1 - rho_true) * sigma2_total

cluster_effects <- rnorm(k, mean = 0, sd = sqrt(sigma2_between))
y <- numeric(k * m)
cluster_id <- character(k * m)

for (i in 1:k) {
  idx <- ((i-1)*m + 1):(i*m)
  y[idx] <- 50 + cluster_effects[i] + rnorm(m, 0, sqrt(sigma2_within))
  cluster_id[idx] <- sprintf("CL_%03d", i)
}

cat(sprintf("Population: %d clusters x %d units = %d total\n", k, m, k*m))
cat(sprintf("True ICC (rho): %.4f\n\n", rho_true))

# --- Compute ICC ---
result <- compute_icc_scratch(y, cluster_id)

cat("--- ANOVA Decomposition ---\n")
cat(sprintf("  MSB (between)   : %.4f\n", result$msb))
cat(sprintf("  MSW (within)    : %.4f\n", result$msw))
cat(sprintf("  sigma2_between  : %.4f\n", result$sigma2_b))
cat(sprintf("  sigma2_within   : %.4f\n", result$sigma2_w))
cat(sprintf("  ICC (rho)       : %.4f (true: %.4f)\n", result$rho, rho_true))
cat(sprintf("  Deff (m=%d)     : %.2f\n", result$m_bar, result$deff))

stopifnot(abs(result$rho - rho_true) < 0.02)
cat("\n[PASS] ICC estimate within 0.02 of true value.\n")

# ============================================================
# COMPARE SCENARIOS A vs B
# ============================================================

cat("\n============================================================\n")
cat("  SCENARIO COMPARISON\n")
cat("============================================================\n")

rho_est <- result$rho

# Scenario A: 300 clusters x 10 HH
a_clusters <- 300; a_m <- 10
deff_a <- 1 + (a_m - 1) * rho_est

# Scenario B: 150 clusters x 20 HH
b_clusters <- 150; b_m <- 20
deff_b <- 1 + (b_m - 1) * rho_est

n_total <- 3000
eff_n_a <- n_total / deff_a
eff_n_b <- n_total / deff_b

cat(sprintf("  Scenario A: %d clusters x %d = %d (Deff=%.2f, eff_n=%.0f)\n",
            a_clusters, a_m, a_clusters * a_m, deff_a, eff_n_a))
cat(sprintf("  Scenario B: %d clusters x %d = %d (Deff=%.2f, eff_n=%.0f)\n",
            b_clusters, b_m, b_clusters * b_m, deff_b, eff_n_b))
cat(sprintf("  Efficiency ratio (A/B): %.2f\n", eff_n_a / eff_n_b))

stopifnot(deff_a < deff_b)
cat("\n[PASS] Smaller clusters produce lower Deff.\n")

# ============================================================
# Monte Carlo verification of Deff
# ============================================================

cat("\n--- Monte Carlo Deff Verification ---\n")

B <- 3000
n_sample <- 300  # Sample size for both

# SRS estimates
srs_est <- numeric(B)
for (b in 1:B) {
  idx <- sample(length(y), n_sample, replace = FALSE)
  srs_est[b] <- mean(y[idx])
}
var_srs <- var(srs_est)

# Cluster sample (30 clusters x 10)
clust_est <- numeric(B)
for (b in 1:B) {
  sel_cl <- sample(unique(cluster_id), 30, replace = FALSE)
  est_vals <- numeric(0)
  for (cl in sel_cl) {
    cl_vals <- y[cluster_id == cl]
    idx <- sample(length(cl_vals), min(10, length(cl_vals)))
    est_vals <- c(est_vals, cl_vals[idx])
  }
  clust_est[b] <- mean(est_vals)
}
var_clust <- var(clust_est)

deff_mc <- var_clust / var_srs
deff_formula <- 1 + (10 - 1) * rho_est

cat(sprintf("  Var(SRS)     : %.6f\n", var_srs))
cat(sprintf("  Var(Cluster) : %.6f\n", var_clust))
cat(sprintf("  Deff (MC)    : %.2f\n", deff_mc))
cat(sprintf("  Deff (formula): %.2f\n", deff_formula))
cat(sprintf("  Ratio MC/form: %.2f\n", deff_mc / deff_formula))

stopifnot(abs(deff_mc - deff_formula) / deff_formula < 0.25)
cat("[PASS] MC Deff consistent with formula.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 3.2: Design Effect & ICC from Scratch
# Python — ANOVA variance components
# ============================================================

import numpy as np

np.random.seed(2024)


def compute_icc(y, cluster_ids):
    """Compute ICC using one-way ANOVA variance components."""
    valid = ~(np.isnan(y))
    y = y[valid]
    cluster_ids = np.array(cluster_ids)[valid]

    clusters = np.unique(cluster_ids)
    k = len(clusters)
    n_total = len(y)
    grand_mean = np.mean(y)

    # Cluster sizes and means
    cluster_sizes = np.array([np.sum(cluster_ids == c) for c in clusters])
    cluster_means = np.array([np.mean(y[cluster_ids == c]) for c in clusters])
    m_bar = np.mean(cluster_sizes)

    # SSB
    ssb = np.sum(cluster_sizes * (cluster_means - grand_mean) ** 2)
    msb = ssb / (k - 1)

    # SSW
    y_cluster_means = np.zeros_like(y, dtype=float)
    for c in clusters:
        mask = cluster_ids == c
        y_cluster_means[mask] = np.mean(y[mask])
    ssw = np.sum((y - y_cluster_means) ** 2)
    msw = ssw / (n_total - k)

    # Variance components
    sigma2_b = (msb - msw) / m_bar
    sigma2_w = msw

    rho = sigma2_b / (sigma2_b + sigma2_w)
    rho = max(rho, -1 / (m_bar - 1))

    deff = 1 + (m_bar - 1) * rho

    return {
        'rho': rho, 'msb': msb, 'msw': msw,
        'sigma2_b': sigma2_b, 'sigma2_w': sigma2_w,
        'k': k, 'm_bar': m_bar, 'deff': deff
    }


# --- Simulation ---
k = 500
m = 100
rho_true = 0.08

sigma2_total = 100
sigma2_b = rho_true * sigma2_total
sigma2_w = (1 - rho_true) * sigma2_total

cluster_effects = np.random.normal(0, np.sqrt(sigma2_b), k)
y = np.zeros(k * m)
cluster_ids = np.empty(k * m, dtype='<U10')

for i in range(k):
    sl = slice(i * m, (i + 1) * m)
    y[sl] = 50 + cluster_effects[i] + np.random.normal(0, np.sqrt(sigma2_w), m)
    cluster_ids[sl] = f'CL_{i:03d}'

print(f"Population: {k} clusters x {m} = {k*m}")
print(f"True ICC: {rho_true}")

result = compute_icc(y, cluster_ids)

print(f"\n--- ANOVA ---")
print(f"  MSB       : {result['msb']:.4f}")
print(f"  MSW       : {result['msw']:.4f}")
print(f"  sigma2_b  : {result['sigma2_b']:.4f}")
print(f"  sigma2_w  : {result['sigma2_w']:.4f}")
print(f"  ICC (rho) : {result['rho']:.4f} (true: {rho_true})")
print(f"  Deff      : {result['deff']:.2f}")

assert abs(result['rho'] - rho_true) < 0.02
print("\n[PASS] ICC within 0.02 of true value.")

# --- Scenario comparison ---
rho = result['rho']

scenarios = [
    ('A: 300x10', 300, 10),
    ('B: 150x20', 150, 20),
]

print(f"\n{'Scenario':<12} {'clusters':>8} {'m':>4} {'Deff':>8} {'eff_n':>8}")
print("-" * 48)
for name, n_cl, m_cl in scenarios:
    d = 1 + (m_cl - 1) * rho
    eff = (n_cl * m_cl) / d
    print(f"{name:<12} {n_cl:>8} {m_cl:>4} {d:>8.2f} {eff:>8.0f}")

# --- Monte Carlo Deff ---
B = 3000
n_sample = 300

srs_est = np.array([
    np.mean(y[np.random.choice(len(y), n_sample, replace=False)])
    for _ in range(B)
])

unique_cl = np.unique(cluster_ids)
clust_est = np.zeros(B)
for b in range(B):
    sel = np.random.choice(unique_cl, 30, replace=False)
    vals = []
    for c in sel:
        c_vals = y[cluster_ids == c]
        idx = np.random.choice(len(c_vals), min(10, len(c_vals)), replace=False)
        vals.extend(c_vals[idx])
    clust_est[b] = np.mean(vals)

deff_mc = np.var(clust_est, ddof=1) / np.var(srs_est, ddof=1)
deff_form = 1 + (10 - 1) * rho

print(f"\n--- MC Verification ---")
print(f"  Deff (MC)     : {deff_mc:.2f}")
print(f"  Deff (formula): {deff_form:.2f}")

assert abs(deff_mc - deff_form) / deff_form < 0.25
print("[PASS] MC Deff consistent with formula.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey

```r
# ============================================================
# Lesson 3.2: Deff estimation with survey package
# ============================================================

library(survey)

# Using population from scratch code
sample_idx <- sample(length(y), 300, replace = FALSE)
sample_clusters <- cluster_id[sample_idx]
sample_y <- y[sample_idx]

# Draw a proper cluster sample: 30 clusters, 10 per cluster
sel_clusters <- sample(unique(cluster_id), 30, replace = FALSE)
cl_sample <- data.frame()
for (cl in sel_clusters) {
  cl_vals <- y[cluster_id == cl]
  idx <- sample(length(cl_vals), min(10, length(cl_vals)))
  cl_sample <- rbind(cl_sample, data.frame(
    cluster = cl,
    y_val   = cl_vals[idx],
    weight  = length(unique(cluster_id)) / 30 * length(cl_vals) / 10
  ))
}

design <- svydesign(id = ~cluster, weights = ~weight, data = cl_sample)
est <- svymean(~y_val, design)
deff_pkg <- deff(est)

cat(sprintf("survey::deff = %.2f\n", deff_pkg))

# Manual ICC for comparison
icc_manual <- compute_icc_scratch(cl_sample$y_val, cl_sample$cluster)
cat(sprintf("Manual ICC   = %.4f\n", icc_manual$rho))
cat(sprintf("Manual Deff  = %.2f\n", icc_manual$deff))
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: deff_analyzer.py
# Design Effect and ICC analysis tool
# ============================================================

import numpy as np
from typing import Dict, Optional


class DeffAnalyzer:
    """Analyze design effects and ICC for survey data."""

    def __init__(self, y: np.ndarray, cluster_ids: np.ndarray,
                 stratum_ids: Optional[np.ndarray] = None):
        self.y = np.asarray(y, dtype=float)
        self.cluster_ids = np.asarray(cluster_ids)
        self.stratum_ids = stratum_ids
        self._results = None

    def compute(self) -> Dict:
        """Compute ICC and Deff using ANOVA."""
        valid = ~np.isnan(self.y)
        y = self.y[valid]
        cl = self.cluster_ids[valid]

        clusters = np.unique(cl)
        k = len(clusters)
        n = len(y)
        grand_mean = np.mean(y)

        sizes = np.array([np.sum(cl == c) for c in clusters])
        means = np.array([np.mean(y[cl == c]) for c in clusters])
        m_bar = np.mean(sizes)

        ssb = np.sum(sizes * (means - grand_mean) ** 2)
        msb = ssb / max(k - 1, 1)

        ssw = sum(np.sum((y[cl == c] - means[i]) ** 2)
                  for i, c in enumerate(clusters))
        msw = ssw / max(n - k, 1)

        sigma2_b = max(0, (msb - msw) / m_bar)
        sigma2_w = msw
        rho = sigma2_b / (sigma2_b + sigma2_w) if (sigma2_b + sigma2_w) > 0 else 0

        self._results = {
            'rho': rho, 'deff': 1 + (m_bar - 1) * rho,
            'msb': msb, 'msw': msw,
            'sigma2_between': sigma2_b, 'sigma2_within': sigma2_w,
            'n_clusters': k, 'mean_cluster_size': m_bar,
            'n_obs': n
        }
        return self._results

    def scenario_table(self, cluster_sizes: list) -> str:
        """Compare Deff across hypothetical cluster sizes."""
        if self._results is None:
            self.compute()
        rho = self._results['rho']

        lines = [f"ICC (rho) = {rho:.4f}\n",
                 f"{'m':>6} | {'Deff':>8} | {'eff_n (n=3000)':>16}",
                 "-" * 35]
        for m in cluster_sizes:
            d = 1 + (m - 1) * rho
            lines.append(f"{m:>6} | {d:>8.2f} | {3000/d:>16.0f}")
        return "\n".join(lines)

    def report(self) -> str:
        if self._results is None:
            self.compute()
        r = self._results
        return (
            f"=== DESIGN EFFECT ANALYSIS ===\n"
            f"  Clusters        : {r['n_clusters']}\n"
            f"  Mean size (m)   : {r['mean_cluster_size']:.1f}\n"
            f"  ICC (rho)       : {r['rho']:.4f}\n"
            f"  Deff            : {r['deff']:.2f}\n"
            f"  sigma2_between  : {r['sigma2_between']:.4f}\n"
            f"  sigma2_within   : {r['sigma2_within']:.4f}\n"
        )
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الصيغة |
|-----------------|-------------------|--------|
| أثر التصميم | Design Effect (Deff) | $1 + (\bar{m}-1)\rho$ |
| معامل الارتباط داخل العنقود | ICC ($\rho$) | $(MSB - MSW) / (MSB + (\bar{m}-1) MSW)$ |
| تباين بين العناقيد | Between-Cluster Variance | $\sigma^2_B = (MSB - MSW)/\bar{m}$ |
| تباين داخل العناقيد | Within-Cluster Variance | $\sigma^2_W = MSW$ |
| حجم العينة الفعال | Effective Sample Size | $n_{eff} = n / Deff$ |

---

[→ الدرس السابق](lesson_3_1_cochran_extensions.md) | [العودة إلى الفهرس](../../README.md) | [المرحلة 4 ←](../phase_4_weighting_pipeline/lesson_4_1_design_weights.md)

</div>
