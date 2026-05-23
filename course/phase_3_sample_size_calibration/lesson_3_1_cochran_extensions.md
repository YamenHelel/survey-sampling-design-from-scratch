<div dir="rtl" align="right">

# الدرس 3.1: امتدادات معادلة كوكران للمسوح المركبة

[→ الدرس السابق](../phase_2_probability_designs/lesson_2_3_multistage_engine.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_3_2_deff_icc_mechanics.md)

---

## 1. الشعار (Motto)

> **"حجم العينة ليس رقماً تختاره — إنه معادلة توازن بين الدقة المطلوبة والميزانية المتاحة والتصميم المستخدم."**
>
> معادلة كوكران هي نقطة البداية، لكن المسوح الحقيقية تحتاج ثلاثة تعديلات إضافية على الأقل.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء يخطط لمسح الفقر متعدد الأبعاد (*Multidimensional Poverty Survey*). المطلوب:
- تقدير نسبة الفقر على المستوى الوطني بهامش خطأ $\pm 2\%$ عند مستوى ثقة 95%
- التصميم عنقودي متعدد المراحل (أثر تصميم متوقع $Deff = 2.5$)
- معدل عدم الاستجابة المتوقع 15%
- حجم المجتمع $N = 2,000,000$ أسرة

ما هو حجم العينة المطلوب؟ وكيف يتغير إذا أردنا تقديرات على مستوى كل محافظة (12 محافظة)؟

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 معادلة كوكران الأساسية للنسب

الصيغة الأولية لعينة عشوائية بسيطة (*SRS*) ومجتمع لانهائي:

$$n_0 = \frac{z^2 \cdot p(1-p)}{e^2}$$

حيث:
- $z$ = القيمة المعيارية لمستوى الثقة (1.96 لـ 95%)
- $p$ = النسبة المتوقعة
- $e$ = هامش الخطأ المطلوب

### 3.2 تصحيح المجتمع المحدود (Finite Population Correction)

عندما يكون المجتمع محدوداً ($N$ معروف):

$$n_{fpc} = \frac{n_0}{1 + \frac{n_0 - 1}{N}}$$

### 3.3 المعادلة الكاملة للمسوح المركبة

$$n = \frac{n_0}{1 + \frac{n_0 - 1}{N}} \times Deff \times \frac{1}{1 - r_{nr}}$$

حيث:
- $Deff$ = أثر التصميم (*Design Effect*)
- $r_{nr}$ = معدل عدم الاستجابة المتوقع (*Non-Response Rate*)

### 3.4 معادلة كوكران للمتوسطات

$$n_0 = \frac{z^2 \cdot \sigma^2}{e^2}$$

ثم تُطبَّق نفس التعديلات الثلاثة (FPC, Deff, عدم الاستجابة).

### 3.5 حجم العينة للتقديرات دون الوطنية (Domain Estimates)

إذا أردنا تقديرات لكل منطقة $d$ من $D$ منطقة:

$$n_{total} = \sum_{d=1}^{D} n_d$$

حيث $n_d$ يُحسب بنفس المعادلة لكن باستخدام $N_d$ و $p_d$ الخاصة بكل منطقة.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 3.1: Cochran's Formula Extensions
# R — From Scratch (No specialized packages)
# ============================================================

# --- Core function: sample size for proportions ---
cochran_proportion <- function(p, e, z = 1.96, N = NULL,
                                deff = 1, nr_rate = 0) {
  stopifnot(p > 0 && p < 1)
  stopifnot(e > 0)
  stopifnot(deff >= 1)
  stopifnot(nr_rate >= 0 && nr_rate < 1)

  # Step 1: Base (infinite population)
  n0 <- (z^2 * p * (1 - p)) / e^2

  # Step 2: Finite population correction
  if (!is.null(N) && N > 0) {
    n_fpc <- n0 / (1 + (n0 - 1) / N)
  } else {
    n_fpc <- n0
  }

  # Step 3: Design effect adjustment
  n_deff <- n_fpc * deff

  # Step 4: Non-response adjustment
  n_final <- n_deff / (1 - nr_rate)

  list(
    n0      = ceiling(n0),
    n_fpc   = ceiling(n_fpc),
    n_deff  = ceiling(n_deff),
    n_final = ceiling(n_final),
    components = data.frame(
      step = c("Base (Cochran)", "After FPC", "After Deff", "After NR"),
      n    = ceiling(c(n0, n_fpc, n_deff, n_final))
    )
  )
}

# --- Core function: sample size for means ---
cochran_mean <- function(sigma, e, z = 1.96, N = NULL,
                          deff = 1, nr_rate = 0) {
  stopifnot(sigma > 0 && e > 0 && deff >= 1)
  stopifnot(nr_rate >= 0 && nr_rate < 1)

  n0 <- (z^2 * sigma^2) / e^2

  if (!is.null(N) && N > 0) {
    n_fpc <- n0 / (1 + (n0 - 1) / N)
  } else {
    n_fpc <- n0
  }

  n_final <- ceiling(n_fpc * deff / (1 - nr_rate))
  n_final
}

# ============================================================
# SCENARIO: National Poverty Survey
# ============================================================

cat("============================================================\n")
cat("  SAMPLE SIZE CALCULATION: National Poverty Survey\n")
cat("============================================================\n\n")

result <- cochran_proportion(
  p       = 0.25,      # Expected poverty rate ~25%
  e       = 0.02,      # Margin of error ±2%
  z       = 1.96,      # 95% confidence
  N       = 2000000,   # Population size
  deff    = 2.5,        # Cluster design effect
  nr_rate = 0.15        # 15% non-response
)

cat("--- Step-by-step computation ---\n")
print(result$components)
cat(sprintf("\nFinal required sample size: %s households\n",
            format(result$n_final, big.mark = ",")))

# ============================================================
# SENSITIVITY ANALYSIS
# ============================================================

cat("\n--- Sensitivity to key parameters ---\n\n")

# Vary Deff
cat("Effect of Design Effect (Deff):\n")
for (d in c(1.0, 1.5, 2.0, 2.5, 3.0, 4.0)) {
  r <- cochran_proportion(0.25, 0.02, N = 2e6, deff = d, nr_rate = 0.15)
  cat(sprintf("  Deff = %.1f -> n = %s\n", d,
              format(r$n_final, big.mark = ",")))
}

# Vary margin of error
cat("\nEffect of margin of error (e):\n")
for (e in c(0.01, 0.015, 0.02, 0.03, 0.05)) {
  r <- cochran_proportion(0.25, e, N = 2e6, deff = 2.5, nr_rate = 0.15)
  cat(sprintf("  e = %.1f%% -> n = %s\n", e * 100,
              format(r$n_final, big.mark = ",")))
}

# Vary non-response rate
cat("\nEffect of non-response rate:\n")
for (nr in c(0.05, 0.10, 0.15, 0.20, 0.30)) {
  r <- cochran_proportion(0.25, 0.02, N = 2e6, deff = 2.5, nr_rate = nr)
  cat(sprintf("  NR = %.0f%% -> n = %s\n", nr * 100,
              format(r$n_final, big.mark = ",")))
}

# ============================================================
# DOMAIN-LEVEL ESTIMATION
# ============================================================

cat("\n============================================================\n")
cat("  DOMAIN-LEVEL SAMPLE SIZE (12 Governorates)\n")
cat("============================================================\n\n")

domains <- data.frame(
  domain = paste0("GOV_", sprintf("%02d", 1:12)),
  N_d    = c(500000, 200000, 180000, 250000, 150000,
             120000, 100000, 130000, 90000, 80000, 110000, 90000),
  p_d    = c(0.15, 0.30, 0.35, 0.20, 0.40,
             0.25, 0.22, 0.28, 0.45, 0.50, 0.18, 0.38),
  stringsAsFactors = FALSE
)

domains$n_d <- NA
for (i in 1:nrow(domains)) {
  r <- cochran_proportion(
    p = domains$p_d[i], e = 0.05, N = domains$N_d[i],
    deff = 2.5, nr_rate = 0.15
  )
  domains$n_d[i] <- r$n_final
}

cat(sprintf("%-8s | %10s | %6s | %8s\n", "Domain", "N_d", "p_d", "n_d"))
cat(paste(rep("-", 42), collapse = ""), "\n")
for (i in 1:nrow(domains)) {
  cat(sprintf("%-8s | %10s | %6.2f | %8s\n",
              domains$domain[i],
              format(domains$N_d[i], big.mark = ","),
              domains$p_d[i],
              format(domains$n_d[i], big.mark = ",")))
}

cat(sprintf("\nTotal sample (all domains): %s\n",
            format(sum(domains$n_d), big.mark = ",")))

# ============================================================
# VERIFICATION via simulation
# ============================================================

cat("\n--- Verification: does the computed n achieve target precision? ---\n")

set.seed(2024)
N_sim <- 200000
pop <- rbinom(N_sim, 1, 0.25)  # 25% poverty rate
theta <- mean(pop)

n_calc <- cochran_proportion(0.25, 0.02, N = N_sim, deff = 1, nr_rate = 0)
n_test <- n_calc$n_final

B <- 5000
estimates <- numeric(B)
for (b in 1:B) {
  idx <- sample(N_sim, n_test, replace = FALSE)
  estimates[b] <- mean(pop[idx])
}

achieved_se <- sd(estimates)
achieved_moe <- 1.96 * achieved_se
target_moe <- 0.02

cat(sprintf("  Target MoE      : %.4f\n", target_moe))
cat(sprintf("  Achieved MoE    : %.4f\n", achieved_moe))
cat(sprintf("  n used          : %d\n", n_test))

stopifnot(achieved_moe <= target_moe * 1.15)
cat("[PASS] Computed n achieves target precision (within 15% tolerance).\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 3.1: Cochran's Formula Extensions
# Python — From Scratch
# ============================================================

import numpy as np
from math import ceil

def cochran_proportion(p, e, z=1.96, N=None, deff=1.0, nr_rate=0.0):
    """Compute sample size for estimating a proportion."""
    assert 0 < p < 1, "p must be between 0 and 1"
    assert e > 0, "Margin of error must be positive"
    assert deff >= 1, "Deff must be >= 1"
    assert 0 <= nr_rate < 1, "NR rate must be in [0, 1)"

    n0 = (z**2 * p * (1 - p)) / e**2

    if N is not None and N > 0:
        n_fpc = n0 / (1 + (n0 - 1) / N)
    else:
        n_fpc = n0

    n_deff = n_fpc * deff
    n_final = n_deff / (1 - nr_rate)

    return {
        'n0': ceil(n0),
        'n_fpc': ceil(n_fpc),
        'n_deff': ceil(n_deff),
        'n_final': ceil(n_final)
    }


def cochran_mean(sigma, e, z=1.96, N=None, deff=1.0, nr_rate=0.0):
    """Compute sample size for estimating a mean."""
    assert sigma > 0 and e > 0 and deff >= 1
    assert 0 <= nr_rate < 1

    n0 = (z**2 * sigma**2) / e**2
    if N is not None and N > 0:
        n0 = n0 / (1 + (n0 - 1) / N)
    return ceil(n0 * deff / (1 - nr_rate))


# ============================================================
# SCENARIO: National Poverty Survey
# ============================================================

print("=" * 60)
print("  SAMPLE SIZE: National Poverty Survey")
print("=" * 60)

result = cochran_proportion(
    p=0.25, e=0.02, z=1.96,
    N=2_000_000, deff=2.5, nr_rate=0.15
)

for step, key in [("Base (Cochran)", "n0"), ("After FPC", "n_fpc"),
                   ("After Deff", "n_deff"), ("After NR adj", "n_final")]:
    print(f"  {step:<20}: {result[key]:>8,}")

print(f"\n  Final sample size: {result['n_final']:,}")

# --- Sensitivity ---
print("\n--- Sensitivity to Deff ---")
for d in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0]:
    r = cochran_proportion(0.25, 0.02, N=2e6, deff=d, nr_rate=0.15)
    print(f"  Deff={d:.1f} -> n={r['n_final']:,}")

print("\n--- Sensitivity to margin of error ---")
for e in [0.01, 0.015, 0.02, 0.03, 0.05]:
    r = cochran_proportion(0.25, e, N=2e6, deff=2.5, nr_rate=0.15)
    print(f"  e={e*100:.1f}% -> n={r['n_final']:,}")

# --- Domain estimation ---
print("\n" + "=" * 60)
print("  DOMAIN-LEVEL (12 Governorates)")
print("=" * 60)

domains = [
    ('GOV_01', 500000, 0.15), ('GOV_02', 200000, 0.30),
    ('GOV_03', 180000, 0.35), ('GOV_04', 250000, 0.20),
    ('GOV_05', 150000, 0.40), ('GOV_06', 120000, 0.25),
    ('GOV_07', 100000, 0.22), ('GOV_08', 130000, 0.28),
    ('GOV_09', 90000, 0.45),  ('GOV_10', 80000, 0.50),
    ('GOV_11', 110000, 0.18), ('GOV_12', 90000, 0.38),
]

total_n = 0
print(f"{'Domain':<10} {'N_d':>10} {'p_d':>6} {'n_d':>8}")
print("-" * 40)
for name, Nd, pd in domains:
    r = cochran_proportion(pd, 0.05, N=Nd, deff=2.5, nr_rate=0.15)
    total_n += r['n_final']
    print(f"{name:<10} {Nd:>10,} {pd:>6.2f} {r['n_final']:>8,}")

print(f"\nTotal sample: {total_n:,}")

# --- Verification ---
print("\n--- Simulation verification ---")
np.random.seed(2024)
N_sim = 200000
pop = np.random.binomial(1, 0.25, N_sim)
theta = pop.mean()

r = cochran_proportion(0.25, 0.02, N=N_sim, deff=1.0, nr_rate=0.0)
n_test = r['n_final']

B = 5000
estimates = np.array([
    np.mean(pop[np.random.choice(N_sim, n_test, replace=False)])
    for _ in range(B)
])

achieved_moe = 1.96 * np.std(estimates, ddof=1)
print(f"  Target MoE  : 0.0200")
print(f"  Achieved MoE: {achieved_moe:.4f}")

assert achieved_moe <= 0.02 * 1.15, f"MoE too large: {achieved_moe}"
print("[PASS] Computed n achieves target precision.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey

```r
# ============================================================
# Lesson 3.1: Power analysis verification with survey package
# ============================================================

library(survey)

set.seed(2024)

# Simulate a clustered population to verify Deff-adjusted sample size
N_pop <- 200000
n_clusters <- 2000
cluster_size <- N_pop / n_clusters

# Generate clustered data (poverty indicator)
cluster_rates <- rbeta(n_clusters, 2, 6)  # Varying cluster poverty rates
pop_data <- data.frame(
  cluster_id = rep(1:n_clusters, each = cluster_size),
  poverty    = unlist(lapply(cluster_rates, function(p)
    rbinom(cluster_size, 1, p)))
)

true_rate <- mean(pop_data$poverty)

# Draw two-stage sample
a <- 100  # PSUs
b <- 15   # HH per PSU
selected_clusters <- sample(1:n_clusters, a, replace = FALSE)

sample_list <- list()
for (i in seq_along(selected_clusters)) {
  cl <- selected_clusters[i]
  cl_data <- pop_data[pop_data$cluster_id == cl, ]
  idx <- sample(1:nrow(cl_data), min(b, nrow(cl_data)))
  s <- cl_data[idx, ]
  s$weight <- (n_clusters / a) * (cluster_size / b)
  s$psu_id <- i
  sample_list[[i]] <- s
}
sample_df <- do.call(rbind, sample_list)

# Survey design
design <- svydesign(id = ~psu_id, weights = ~weight, data = sample_df)
est <- svymean(~poverty, design)
deff_est <- deff(svymean(~poverty, design))

cat(sprintf("True poverty rate : %.4f\n", true_rate))
cat(sprintf("Estimated rate    : %.4f (SE: %.4f)\n", coef(est), SE(est)))
cat(sprintf("Estimated Deff    : %.2f\n", deff_est))

# Verify our formula gives adequate n
our_n <- cochran_proportion(
  p = coef(est), e = 0.02, N = N_pop,
  deff = as.numeric(deff_est), nr_rate = 0.15
)
cat(sprintf("Required n (our formula): %s\n",
            format(our_n$n_final, big.mark = ",")))
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: sample_size_calculator.py
# ============================================================

from math import ceil
from typing import Optional, Dict, List
import json


class SampleSizeCalculator:
    """Production sample size calculator for complex surveys."""

    def __init__(self, confidence: float = 0.95):
        from scipy.stats import norm
        self.z = norm.ppf(1 - (1 - confidence) / 2)
        self.confidence = confidence

    def for_proportion(self, p: float, e: float,
                       N: Optional[int] = None,
                       deff: float = 1.0,
                       nr_rate: float = 0.0) -> Dict:
        n0 = (self.z ** 2 * p * (1 - p)) / e ** 2
        n_fpc = n0 / (1 + (n0 - 1) / N) if N else n0
        n_adj = n_fpc * deff / (1 - nr_rate)
        return {
            'n_base': ceil(n0), 'n_fpc': ceil(n_fpc),
            'n_final': ceil(n_adj),
            'params': {'p': p, 'e': e, 'N': N, 'deff': deff, 'nr': nr_rate}
        }

    def for_mean(self, sigma: float, e: float,
                 N: Optional[int] = None,
                 deff: float = 1.0,
                 nr_rate: float = 0.0) -> Dict:
        n0 = (self.z ** 2 * sigma ** 2) / e ** 2
        n_fpc = n0 / (1 + (n0 - 1) / N) if N else n0
        n_adj = n_fpc * deff / (1 - nr_rate)
        return {
            'n_base': ceil(n0), 'n_fpc': ceil(n_fpc),
            'n_final': ceil(n_adj),
            'params': {'sigma': sigma, 'e': e, 'N': N, 'deff': deff, 'nr': nr_rate}
        }

    def for_domains(self, domains: List[Dict],
                    target_e: float, deff: float = 1.0,
                    nr_rate: float = 0.0) -> Dict:
        results = []
        for d in domains:
            r = self.for_proportion(
                p=d['p'], e=target_e, N=d.get('N'),
                deff=deff, nr_rate=nr_rate
            )
            r['domain'] = d['name']
            results.append(r)

        return {
            'domain_sizes': results,
            'total_n': sum(r['n_final'] for r in results)
        }

    def sensitivity_report(self, p: float, e: float,
                           N: int, nr_rate: float = 0.15) -> str:
        lines = ["=== SAMPLE SIZE SENSITIVITY REPORT ===\n"]
        lines.append(f"Base: p={p}, e={e}, N={N:,}, NR={nr_rate}\n")
        lines.append(f"{'Deff':>6} | {'n':>10}")
        lines.append("-" * 20)
        for d in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0]:
            r = self.for_proportion(p, e, N, d, nr_rate)
            lines.append(f"{d:>6.1f} | {r['n_final']:>10,}")
        return "\n".join(lines)
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الصيغة |
|-----------------|-------------------|--------|
| معادلة كوكران | Cochran's Formula | $n_0 = z^2 p(1-p)/e^2$ |
| تصحيح المجتمع المحدود | Finite Population Correction | $n_0 / (1 + (n_0-1)/N)$ |
| أثر التصميم | Design Effect (Deff) | مضاعف يعكس تأثير العنقدة |
| تعديل عدم الاستجابة | Non-Response Adjustment | $n / (1 - r_{nr})$ |
| التقدير دون الوطني | Domain Estimation | حجم عينة مستقل لكل منطقة |

---

[→ الدرس السابق](../phase_2_probability_designs/lesson_2_3_multistage_engine.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_3_2_deff_icc_mechanics.md)

</div>
