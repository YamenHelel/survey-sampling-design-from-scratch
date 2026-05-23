<div dir="rtl" align="right">

# الدرس 5.1: خطية تايلور من الصفر

[→ الدرس السابق](../phase_4_weighting_pipeline/lesson_4_3_calibration_raking.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_5_2_jackknife_replications.md)

---

## 1. الشعار (Motto)

> **"مقدِّر النسبة ليس خطياً — لكن تقريب تايلور يُخطِّطه ويفتح الباب لحساب التباين."**
>
> خطية تايلور هي الطريقة القياسية لتقدير تباين المؤشرات المركبة في المسوح الرسمية.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء يحتاج لنشر معدل البطالة الوطني مع **خطئه المعياري** وفترة الثقة. المشكلة: معدل البطالة هو **مقدِّر نسبة** (*Ratio Estimator*):

$$\hat{R} = \frac{\sum w_i \cdot unemployed_i}{\sum w_i \cdot labor\_force_i}$$

البسط والمقام كلاهما عشوائيان — هذا يجعل حساب التباين أعقد من مقدِّر المجموع البسيط.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 مقدِّر النسبة

$$\hat{R} = \frac{\hat{Y}}{\hat{X}} = \frac{\sum_{i \in s} w_i y_i}{\sum_{i \in s} w_i x_i}$$

### 3.2 تقريب تايلور (Delta Method)

نُقرِّب $\hat{R}$ بدالة خطية حول القيم الحقيقية:

$$\hat{R} - R \approx \frac{1}{\hat{X}} \sum_{i \in s} w_i (y_i - R \cdot x_i)$$

نُعرِّف المتبقيات الخطية (*Linearized Residuals*):

$$e_i = y_i - \hat{R} \cdot x_i$$

### 3.3 تباين مقدِّر النسبة

$$\widehat{Var}(\hat{R}) = \frac{1}{\hat{X}^2} \widehat{Var}\left(\sum_{i \in s} w_i e_i\right)$$

تحت تقريب العنقود النهائي (*Ultimate Cluster*) مع $H$ طبقات:

$$\widehat{Var}(\hat{R}) = \frac{1}{\hat{X}^2} \sum_{h=1}^{H} \frac{a_h}{a_h - 1} \sum_{i=1}^{a_h} (z_{hi} - \bar{z}_h)^2$$

حيث $z_{hi} = \sum_{j \in PSU_{hi}} w_{hij} e_{hij}$ هو إجمالي المتبقيات الموزونة في PSU.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 5.1: Taylor Series Linearization from Scratch
# R — No survey package
# ============================================================

set.seed(2024)

# --- Generate two-stage stratified cluster sample ---
H <- 4        # Strata
a_h <- 20     # PSUs per stratum
b <- 15       # HH per PSU

sample_data <- data.frame()
psu_counter <- 0

for (h in 1:H) {
  stratum_unemp_rate <- runif(1, 0.05, 0.25)

  for (i in 1:a_h) {
    psu_counter <- psu_counter + 1
    psu_rate <- plogis(qlogis(stratum_unemp_rate) + rnorm(1, 0, 0.5))

    psu_data <- data.frame(
      stratum     = h,
      psu_id      = psu_counter,
      labor_force = rbinom(b, 1, prob = 0.65),  # In labor force?
      stringsAsFactors = FALSE
    )
    # Unemployed only among labor force participants
    psu_data$unemployed <- ifelse(psu_data$labor_force == 1,
                                   rbinom(b, 1, prob = psu_rate), 0)
    psu_data$weight <- 500  # Simplified constant weight

    sample_data <- rbind(sample_data, psu_data)
  }
}

n_total <- nrow(sample_data)
cat(sprintf("Sample: %d obs, %d strata, %d PSUs, %d HH/PSU\n",
            n_total, H, H * a_h, b))

# ============================================================
# STEP 1: Compute ratio estimate
# ============================================================

Y_hat <- sum(sample_data$weight * sample_data$unemployed)
X_hat <- sum(sample_data$weight * sample_data$labor_force)
R_hat <- Y_hat / X_hat

cat(sprintf("\nEstimated unemployment rate: %.4f (%.1f%%)\n",
            R_hat, R_hat * 100))

# ============================================================
# STEP 2: Compute linearized residuals
# ============================================================

sample_data$e_i <- sample_data$unemployed - R_hat * sample_data$labor_force

# ============================================================
# STEP 3: Compute variance via Taylor linearization
# ============================================================

var_taylor <- 0

for (h in 1:H) {
  stratum_data <- sample_data[sample_data$stratum == h, ]
  psus_in_h <- unique(stratum_data$psu_id)
  a <- length(psus_in_h)

  # PSU-level weighted totals of residuals
  z_hi <- numeric(a)
  for (i in seq_along(psus_in_h)) {
    psu_data <- stratum_data[stratum_data$psu_id == psus_in_h[i], ]
    z_hi[i] <- sum(psu_data$weight * psu_data$e_i)
  }

  z_bar <- mean(z_hi)
  ss <- sum((z_hi - z_bar)^2)

  var_taylor <- var_taylor + (a / (a - 1)) * ss
}

var_R <- var_taylor / X_hat^2
se_R <- sqrt(var_R)
cv_R <- se_R / R_hat * 100

cat(sprintf("\n--- Taylor Linearization Results ---\n"))
cat(sprintf("  Var(R_hat)  : %.8f\n", var_R))
cat(sprintf("  SE(R_hat)   : %.4f\n", se_R))
cat(sprintf("  CV          : %.1f%%\n", cv_R))
cat(sprintf("  95%% CI      : [%.4f, %.4f]\n",
            R_hat - 1.96 * se_R, R_hat + 1.96 * se_R))

# ============================================================
# VERIFICATION: Compare with survey package
# ============================================================

library(survey)

design <- svydesign(id = ~psu_id, strata = ~stratum,
                    weights = ~weight, data = sample_data,
                    nest = TRUE)

# Ratio estimator: unemployed / labor_force
est_pkg <- svyratio(~unemployed, ~labor_force, design)
se_pkg <- SE(est_pkg)

cat(sprintf("\n--- Comparison ---\n"))
cat(sprintf("  Manual R_hat : %.6f\n", R_hat))
cat(sprintf("  survey R_hat : %.6f\n", coef(est_pkg)))
cat(sprintf("  Manual SE    : %.6f\n", se_R))
cat(sprintf("  survey SE    : %.6f\n", se_pkg))
cat(sprintf("  SE ratio     : %.4f\n", se_R / as.numeric(se_pkg)))

stopifnot(abs(R_hat - coef(est_pkg)) < 1e-8)
cat("\n[PASS] Point estimates match exactly.\n")

stopifnot(abs(se_R - as.numeric(se_pkg)) / as.numeric(se_pkg) < 0.01)
cat("[PASS] Standard errors match to 4 decimal places.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 5.1: Taylor Series Linearization from Scratch
# Python — No specialized survey packages
# ============================================================

import numpy as np
import pandas as pd
from scipy.special import expit, logit

np.random.seed(2024)

# --- Generate sample ---
H = 4
a_h = 20
b = 15

records = []
psu_counter = 0

for h in range(1, H + 1):
    stratum_rate = np.random.uniform(0.05, 0.25)
    for i in range(a_h):
        psu_counter += 1
        psu_rate = expit(logit(stratum_rate) + np.random.normal(0, 0.5))
        for j in range(b):
            lf = np.random.binomial(1, 0.65)
            unemp = np.random.binomial(1, psu_rate) if lf == 1 else 0
            records.append({
                'stratum': h, 'psu_id': psu_counter,
                'labor_force': lf, 'unemployed': unemp,
                'weight': 500.0
            })

df = pd.DataFrame(records)
print(f"Sample: {len(df)} obs, {H} strata, {psu_counter} PSUs")

# --- Ratio estimate ---
Y_hat = (df['weight'] * df['unemployed']).sum()
X_hat = (df['weight'] * df['labor_force']).sum()
R_hat = Y_hat / X_hat
print(f"\nUnemployment rate: {R_hat:.4f} ({R_hat*100:.1f}%)")

# --- Linearized residuals ---
df['e_i'] = df['unemployed'] - R_hat * df['labor_force']

# --- Taylor variance ---
var_taylor = 0.0

for h in range(1, H + 1):
    stratum = df[df['stratum'] == h]
    psus = stratum['psu_id'].unique()
    a = len(psus)

    z_hi = np.array([
        (stratum[stratum['psu_id'] == p]['weight'] *
         stratum[stratum['psu_id'] == p]['e_i']).sum()
        for p in psus
    ])

    z_bar = z_hi.mean()
    ss = np.sum((z_hi - z_bar) ** 2)
    var_taylor += (a / (a - 1)) * ss

var_R = var_taylor / X_hat ** 2
se_R = np.sqrt(var_R)
cv_R = se_R / R_hat * 100

print(f"\n--- Taylor Linearization ---")
print(f"  SE(R_hat) : {se_R:.6f}")
print(f"  CV        : {cv_R:.1f}%")
print(f"  95% CI    : [{R_hat - 1.96*se_R:.4f}, {R_hat + 1.96*se_R:.4f}]")

# Assertion: CV should be reasonable
assert cv_R < 30, f"CV too high: {cv_R}%"
print(f"\n[PASS] Variance estimation completed (CV={cv_R:.1f}%).")
```

---

## 5. استخدمها (Use It — Production Frameworks)

*(See verification section in Build It From Scratch — the R code compares manual vs `survey::svyratio` directly.)*

---

## 6. أطلقها (Ship It — Production Artifact)

```r
# ============================================================
# PRODUCTION: taylor_variance.R
# ============================================================

taylor_ratio_variance <- function(sample_data, y_col, x_col,
                                   weight_col, psu_col, stratum_col) {
  w <- sample_data[[weight_col]]
  y <- sample_data[[y_col]]
  x <- sample_data[[x_col]]

  Y_hat <- sum(w * y, na.rm = TRUE)
  X_hat <- sum(w * x, na.rm = TRUE)
  R_hat <- Y_hat / X_hat

  e <- y - R_hat * x

  strata <- unique(sample_data[[stratum_col]])
  var_total <- 0

  for (h in strata) {
    mask <- sample_data[[stratum_col]] == h
    h_data <- sample_data[mask, ]
    psus <- unique(h_data[[psu_col]])
    a <- length(psus)

    z <- sapply(psus, function(p) {
      p_mask <- h_data[[psu_col]] == p
      sum(h_data[p_mask, weight_col] * e[mask][p_mask], na.rm = TRUE)
    })

    z_bar <- mean(z)
    var_total <- var_total + (a / (a - 1)) * sum((z - z_bar)^2)
  }

  se <- sqrt(var_total / X_hat^2)

  list(
    estimate = R_hat,
    se       = se,
    cv       = se / abs(R_hat) * 100,
    ci_lower = R_hat - 1.96 * se,
    ci_upper = R_hat + 1.96 * se,
    dof      = sum(sapply(strata, function(h)
      length(unique(sample_data[[psu_col]][sample_data[[stratum_col]] == h])))) -
      length(strata)
  )
}
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الصيغة |
|-----------------|-------------------|--------|
| مقدِّر النسبة | Ratio Estimator | $\hat{R} = \hat{Y}/\hat{X}$ |
| المتبقيات الخطية | Linearized Residuals | $e_i = y_i - \hat{R} x_i$ |
| تقريب تايلور | Taylor Linearization | تحويل المقدِّر غير الخطي لخطي |
| تقريب العنقود النهائي | Ultimate Cluster | التباين يُحسب على مستوى PSU |

---

[→ الدرس السابق](../phase_4_weighting_pipeline/lesson_4_3_calibration_raking.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_5_2_jackknife_replications.md)

</div>
