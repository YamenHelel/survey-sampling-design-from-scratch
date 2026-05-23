<div dir="rtl" align="right">

# الدرس 2.1: المعاينة العشوائية الطبقية والتوزيع الأمثل

[→ الدرس السابق](../phase_1_infrastructure_frames/lesson_1_2_psu_partitioning.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_2_2_systematic_pps.md)

---

## 1. الشعار (Motto)

> **"لا توزع عينتك بالتساوي — وزعها بذكاء. الطبقات المتباينة تستحق عينات أكبر."**
>
> التوزيع الأمثل لنيمن يُعلِّمنا أن نستثمر أكثر حيث يكون التباين أعلى.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء ينفذ مسح الدخل والإنفاق (*Household Income & Expenditure Survey*) بميزانية تكفي لمعاينة $n = 3,000$ أسرة من مجتمع مُقسَّم إلى 6 محافظات (طبقات). المحافظات تختلف اختلافاً جذرياً في حجمها وتباين الدخل فيها:

- محافظة العاصمة: 2 مليون أسرة، تباين دخل مرتفع جداً
- المحافظات الريفية: 200 ألف أسرة لكل منها، تباين دخل منخفض

**السؤال:** كيف نوزع 3,000 أسرة على 6 طبقات لتحقيق أقل تباين ممكن؟

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 التوزيع التناسبي (Proportional Allocation)

كل طبقة $h$ تحصل على حصة متناسبة مع حجمها:

$$n_h = n \times \frac{N_h}{N}$$

### 3.2 التوزيع الأمثل لنيمن (Neyman/Optimum Allocation)

يُوزع العينة بما يُقلل التباين الكلي تحت قيد حجم العينة الثابت:

$$n_h = n \times \frac{N_h \sigma_h}{\sum_{h=1}^{H} N_h \sigma_h}$$

حيث $\sigma_h$ هو الانحراف المعياري داخل الطبقة $h$.

### 3.3 تباين المقدِّر تحت المعاينة الطبقية

$$Var(\hat{\bar{Y}}_{st}) = \sum_{h=1}^{H} W_h^2 \frac{S_h^2}{n_h} \left(1 - \frac{n_h}{N_h}\right)$$

حيث $W_h = N_h / N$ هو وزن الطبقة.

### 3.4 الكسب من التطبيق (Stratification Gain)

$$Gain = \frac{Var(\hat{\bar{Y}}_{SRS})}{Var(\hat{\bar{Y}}_{st})}$$

دائماً $Gain \geq 1$، ويزداد كلما كانت الطبقات أكثر تجانساً داخلياً.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 2.1: Stratified Random Sampling & Optimal Allocation
# R — From Scratch (No sampling libraries)
# ============================================================

set.seed(2024)

# --- Create stratified population ---
strata_params <- data.frame(
  stratum    = paste0("GOV_", sprintf("%02d", 1:6)),
  N_h        = c(200000, 80000, 70000, 100000, 60000, 90000),
  mean_inc   = c(2500, 1200, 1000, 1800, 900, 1500),
  sd_inc     = c(1500, 400, 300, 800, 250, 600),
  stringsAsFactors = FALSE
)

N <- sum(strata_params$N_h)
n_total <- 3000
H <- nrow(strata_params)

# Generate population
population <- data.frame()
for (h in 1:H) {
  pop_h <- data.frame(
    stratum = strata_params$stratum[h],
    income  = pmax(0, rnorm(strata_params$N_h[h],
                            strata_params$mean_inc[h],
                            strata_params$sd_inc[h])),
    stringsAsFactors = FALSE
  )
  population <- rbind(population, pop_h)
}

# True population mean
theta <- mean(population$income)
cat(sprintf("True population mean: %.2f\n", theta))

# --- Compute stratum statistics ---
stratum_stats <- data.frame(
  stratum = strata_params$stratum,
  N_h     = strata_params$N_h,
  stringsAsFactors = FALSE
)

for (h in 1:H) {
  mask <- population$stratum == strata_params$stratum[h]
  stratum_stats$mean_h[h] <- mean(population$income[mask])
  stratum_stats$var_h[h]  <- var(population$income[mask])
  stratum_stats$sd_h[h]   <- sd(population$income[mask])
}

stratum_stats$W_h <- stratum_stats$N_h / N

cat("\n--- Stratum Statistics ---\n")
print(stratum_stats[, c("stratum", "N_h", "W_h", "mean_h", "sd_h")])

# ============================================================
# ALLOCATION 1: PROPORTIONAL
# ============================================================

n_prop <- round(n_total * stratum_stats$W_h)
# Adjust to sum to n_total
n_prop[1] <- n_prop[1] + (n_total - sum(n_prop))
n_prop <- pmax(n_prop, 2)  # Minimum 2 per stratum

cat("\n--- Proportional Allocation ---\n")
cat(sprintf("  %-8s: n_h = %s\n", stratum_stats$stratum, n_prop))

# ============================================================
# ALLOCATION 2: NEYMAN OPTIMAL
# ============================================================

neyman_weights <- stratum_stats$N_h * stratum_stats$sd_h
neyman_weights <- neyman_weights / sum(neyman_weights)
n_neyman <- round(n_total * neyman_weights)
n_neyman[1] <- n_neyman[1] + (n_total - sum(n_neyman))
n_neyman <- pmax(n_neyman, 2)

cat("\n--- Neyman Optimal Allocation ---\n")
cat(sprintf("  %-8s: n_h = %s\n", stratum_stats$stratum, n_neyman))

# ============================================================
# SIMULATION: Compare allocations
# ============================================================

B <- 5000

estimate_stratified <- function(pop, strata_info, n_alloc) {
  est <- 0
  for (h in 1:nrow(strata_info)) {
    mask <- pop$stratum == strata_info$stratum[h]
    pop_h <- pop$income[mask]
    idx <- sample(length(pop_h), n_alloc[h], replace = FALSE)
    est <- est + strata_info$W_h[h] * mean(pop_h[idx])
  }
  est
}

estimates_prop   <- replicate(B, estimate_stratified(population, stratum_stats, n_prop))
estimates_neyman <- replicate(B, estimate_stratified(population, stratum_stats, n_neyman))

# SRS for comparison
estimates_srs <- replicate(B, mean(population$income[sample(N, n_total)]))

cat("\n============================================================\n")
cat("  ALLOCATION COMPARISON (B = 5000 replications)\n")
cat("============================================================\n")
cat(sprintf("  %-22s | %-12s | %-12s | %-10s\n",
            "Method", "E(estimate)", "Variance", "RMSE"))
cat(paste(rep("-", 65), collapse = ""), "\n")

methods <- list(
  list("SRS", estimates_srs),
  list("Stratified (Prop)", estimates_prop),
  list("Stratified (Neyman)", estimates_neyman)
)

for (m in methods) {
  est <- m[[2]]
  cat(sprintf("  %-22s | %12.2f | %12.2f | %10.2f\n",
              m[[1]], mean(est), var(est), sqrt(mean((est - theta)^2))))
}

# Gains
gain_prop   <- var(estimates_srs) / var(estimates_prop)
gain_neyman <- var(estimates_srs) / var(estimates_neyman)

cat(sprintf("\n  Stratification gain (Proportional): %.2fx\n", gain_prop))
cat(sprintf("  Stratification gain (Neyman)      : %.2fx\n", gain_neyman))

# Assertions
stopifnot(var(estimates_neyman) <= var(estimates_prop) * 1.05)
cat("\n[PASS] Neyman allocation achieves lower variance than proportional.\n")

stopifnot(var(estimates_prop) <= var(estimates_srs) * 1.05)
cat("[PASS] Stratification improves over SRS.\n")

stopifnot(abs(mean(estimates_neyman) - theta) < 5)
cat("[PASS] Neyman estimator is unbiased.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 2.1: Stratified Random Sampling & Optimal Allocation
# Python — From Scratch (No specialized libraries)
# ============================================================

import numpy as np

np.random.seed(2024)

# --- Stratum parameters ---
strata = {
    'GOV_01': {'N': 200000, 'mean': 2500, 'sd': 1500},
    'GOV_02': {'N': 80000,  'mean': 1200, 'sd': 400},
    'GOV_03': {'N': 70000,  'mean': 1000, 'sd': 300},
    'GOV_04': {'N': 100000, 'mean': 1800, 'sd': 800},
    'GOV_05': {'N': 60000,  'mean': 900,  'sd': 250},
    'GOV_06': {'N': 90000,  'mean': 1500, 'sd': 600},
}

n_total = 3000
N = sum(s['N'] for s in strata.values())

# Generate population
pop_values = {}
for name, params in strata.items():
    pop_values[name] = np.maximum(0, np.random.normal(
        params['mean'], params['sd'], params['N']))

all_values = np.concatenate(list(pop_values.values()))
theta = np.mean(all_values)
print(f"True population mean: {theta:.2f}")

# Compute stratum weights and actual SDs
W_h = {k: v['N'] / N for k, v in strata.items()}
sd_h = {k: np.std(pop_values[k], ddof=1) for k in strata}

# --- Proportional Allocation ---
n_prop = {k: max(2, round(n_total * W_h[k])) for k in strata}
# Adjust
diff = n_total - sum(n_prop.values())
first_key = list(n_prop.keys())[0]
n_prop[first_key] += diff

# --- Neyman Allocation ---
numer = {k: strata[k]['N'] * sd_h[k] for k in strata}
total_numer = sum(numer.values())
n_neyman = {k: max(2, round(n_total * numer[k] / total_numer)) for k in strata}
diff = n_total - sum(n_neyman.values())
n_neyman[first_key] += diff

print("\n--- Allocation Comparison ---")
print(f"{'Stratum':<10} {'N_h':>8} {'W_h':>6} {'SD_h':>8} {'n_prop':>7} {'n_neyman':>9}")
print("-" * 55)
for k in strata:
    print(f"{k:<10} {strata[k]['N']:>8,} {W_h[k]:>6.3f} {sd_h[k]:>8.1f} "
          f"{n_prop[k]:>7} {n_neyman[k]:>9}")

# --- Simulation ---
B = 5000

def stratified_estimate(pop_vals, w_h, n_alloc):
    est = 0
    for k in pop_vals:
        idx = np.random.choice(len(pop_vals[k]), size=n_alloc[k], replace=False)
        est += w_h[k] * np.mean(pop_vals[k][idx])
    return est

est_prop = np.array([stratified_estimate(pop_values, W_h, n_prop) for _ in range(B)])
est_neyman = np.array([stratified_estimate(pop_values, W_h, n_neyman) for _ in range(B)])
est_srs = np.array([np.mean(np.random.choice(all_values, n_total, replace=False))
                     for _ in range(B)])

print(f"\n{'Method':<22} | {'E(est)':>12} | {'Variance':>12} | {'RMSE':>10}")
print("-" * 65)
for name, est in [("SRS", est_srs), ("Stratified (Prop)", est_prop),
                   ("Stratified (Neyman)", est_neyman)]:
    print(f"{name:<22} | {np.mean(est):>12.2f} | {np.var(est, ddof=1):>12.2f} | "
          f"{np.sqrt(np.mean((est - theta)**2)):>10.2f}")

gain_prop = np.var(est_srs, ddof=1) / np.var(est_prop, ddof=1)
gain_neyman = np.var(est_srs, ddof=1) / np.var(est_neyman, ddof=1)
print(f"\nGain (Proportional): {gain_prop:.2f}x")
print(f"Gain (Neyman)      : {gain_neyman:.2f}x")

assert np.var(est_neyman) <= np.var(est_prop) * 1.05
print("\n[PASS] Neyman <= Proportional variance.")
assert np.var(est_prop) <= np.var(est_srs) * 1.05
print("[PASS] Stratification improves over SRS.")
assert abs(np.mean(est_neyman) - theta) < 5
print("[PASS] Neyman estimator is unbiased.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة sampling

```r
# ============================================================
# Lesson 2.1: Stratified Sampling with the sampling package
# ============================================================

library(sampling)
library(survey)

set.seed(2024)

# Use the same population from the scratch code
# ... (population generation code same as above) ...

N <- 600000
strata_N <- c(200000, 80000, 70000, 100000, 60000, 90000)
strata_names <- paste0("GOV_", sprintf("%02d", 1:6))

population <- data.frame(
  stratum = rep(strata_names, strata_N),
  income  = c(
    pmax(0, rnorm(200000, 2500, 1500)),
    pmax(0, rnorm(80000, 1200, 400)),
    pmax(0, rnorm(70000, 1000, 300)),
    pmax(0, rnorm(100000, 1800, 800)),
    pmax(0, rnorm(60000, 900, 250)),
    pmax(0, rnorm(90000, 1500, 600))
  ),
  stringsAsFactors = FALSE
)

theta <- mean(population$income)

# Neyman allocation using sampling package
stratum_sds <- tapply(population$income, population$stratum, sd)
stratum_Ns  <- tapply(population$income, population$stratum, length)

n_total <- 3000
n_neyman_pkg <- round(n_total * stratum_Ns * stratum_sds /
                        sum(stratum_Ns * stratum_sds))

# Draw stratified sample
population$row_id <- 1:nrow(population)
s <- strata(population, stratanames = "stratum",
            size = n_neyman_pkg[order(names(n_neyman_pkg))],
            method = "srswor")

sample_data <- getdata(population, s)
sample_data$fpc <- stratum_Ns[sample_data$stratum]

# Estimate with survey package
design <- svydesign(id = ~1, strata = ~stratum,
                    fpc = ~fpc, data = sample_data)
est <- svymean(~income, design)

cat(sprintf("survey::svymean  : %.4f (SE = %.4f)\n", coef(est), SE(est)))

# Manual verification
manual_est <- sum(tapply(sample_data$income, sample_data$stratum, mean) *
                    (stratum_Ns / N)[names(tapply(sample_data$income,
                                                   sample_data$stratum, mean))])

cat(sprintf("Manual estimate  : %.4f\n", manual_est))
stopifnot(abs(coef(est) - manual_est) < 0.01)
cat("[PASS] Manual matches survey package to 4 decimals.\n")
```

---

## 6. أطلقها (Ship It — Production Artifact)

```r
# ============================================================
# PRODUCTION: stratified_sampler.R
# Automated stratified sample allocation and selection
# ============================================================

stratified_sampler <- function(frame,
                                stratum_col,
                                size_col = NULL,
                                target_var = NULL,
                                n_total,
                                method = c("proportional", "neyman", "equal"),
                                min_per_stratum = 2,
                                seed = NULL) {

  method <- match.arg(method)
  if (!is.null(seed)) set.seed(seed)

  strata <- unique(frame[[stratum_col]])
  H <- length(strata)

  # Compute stratum sizes
  N_h <- table(frame[[stratum_col]])
  W_h <- N_h / sum(N_h)

  # Compute allocation
  if (method == "proportional") {
    n_h <- round(n_total * W_h)
  } else if (method == "neyman" && !is.null(target_var)) {
    sd_h <- tapply(frame[[target_var]], frame[[stratum_col]], sd, na.rm = TRUE)
    weights <- N_h * sd_h
    n_h <- round(n_total * weights / sum(weights))
  } else {
    n_h <- rep(round(n_total / H), H)
  }

  # Enforce minimum
  n_h <- pmax(n_h, min_per_stratum)
  # Enforce maximum (can't exceed stratum size)
  n_h <- pmin(n_h, N_h)
  # Adjust to hit target
  n_h[which.max(N_h)] <- n_h[which.max(N_h)] + (n_total - sum(n_h))

  # Select sample
  sample_rows <- data.frame()
  for (h in names(N_h)) {
    stratum_data <- frame[frame[[stratum_col]] == h, ]
    idx <- sample(1:nrow(stratum_data), n_h[h], replace = FALSE)
    selected <- stratum_data[idx, ]
    selected$inclusion_prob <- n_h[h] / N_h[h]
    selected$base_weight <- N_h[h] / n_h[h]
    sample_rows <- rbind(sample_rows, selected)
  }

  cat(sprintf("\nStratified Sample Selected (method = %s)\n", method))
  cat(sprintf("Total n = %d from N = %s\n",
              nrow(sample_rows), format(sum(N_h), big.mark = ",")))

  sample_rows
}
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الرمز / الصيغة |
|-----------------|-------------------|---------------|
| المعاينة الطبقية | Stratified Sampling | تقسيم المجتمع إلى طبقات متجانسة |
| التوزيع التناسبي | Proportional Allocation | $n_h = n \times N_h/N$ |
| التوزيع الأمثل | Neyman Allocation | $n_h \propto N_h \sigma_h$ |
| كسب التطبيق | Stratification Gain | $Var_{SRS} / Var_{Strat}$ |
| وزن الطبقة | Stratum Weight | $W_h = N_h / N$ |

---

[→ الدرس السابق](../phase_1_infrastructure_frames/lesson_1_2_psu_partitioning.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_2_2_systematic_pps.md)

</div>
