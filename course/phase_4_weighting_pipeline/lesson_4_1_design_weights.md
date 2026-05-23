<div dir="rtl" align="right">

# الدرس 4.1: أوزان التصميم (الأوزان القاعدية)

[→ الدرس السابق](../phase_3_sample_size_calibration/lesson_3_2_deff_icc_mechanics.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_4_2_nonresponse_propensity.md)

---

## 1. الشعار (Motto)

> **"كل وحدة في العينة تُمثل عدداً محدداً من الوحدات في المجتمع — هذا العدد هو وزنها."**
>
> الوزن القاعدي هو ببساطة مقلوب احتمال الاشتمال: $w_i = 1/\pi_i$.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مسح الدخل والإنفاق اكتمل جمعه: 180 منطقة عد مختارة بـ PPS، و15 أسرة من كل منطقة. الآن يحتاج الفريق لتحويل بيانات 2,700 أسرة إلى **تقديرات وطنية** تمثل 600,000 أسرة. بدون الأوزان الصحيحة، ستكون التقديرات متحيزة لأن المناطق الكبيرة لها احتمالات اشتمال أعلى.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 وزن التصميم القاعدي

$$w_i = \frac{1}{\pi_i}$$

في التصميم متعدد المراحل:

$$w_{ij} = \frac{1}{\pi_i^{(1)} \times \pi_{j|i}^{(2)}} = w_i^{(1)} \times w_{j|i}^{(2)}$$

### 3.2 المرحلة الأولى (PPS)

$$\pi_i^{(1)} = a \times \frac{M_i}{M_{\cdot}} \quad \Rightarrow \quad w_i^{(1)} = \frac{M_{\cdot}}{a \times M_i}$$

### 3.3 المرحلة الثانية (SRS داخل PSU)

$$\pi_{j|i}^{(2)} = \frac{b}{M_i} \quad \Rightarrow \quad w_{j|i}^{(2)} = \frac{M_i}{b}$$

### 3.4 خاصية التحقق الأساسية

مجموع الأوزان يجب أن يُقارب حجم المجتمع:

$$\sum_{i \in s_1} \sum_{j \in s_{2i}} w_{ij} \approx N$$

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — من الصفر

```r
# ============================================================
# Lesson 4.1: Design Weights (Base Weights)
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Setup: Two-stage sample ---
n_eas <- 3000
ea_sizes <- pmax(50, rpois(n_eas, 120))
M_total <- sum(ea_sizes)
N_total <- M_total  # Each HH is one unit

a <- 180  # PSUs selected
b <- 15   # HH per PSU

# Stage 1: PPS selection
cumulative <- cumsum(ea_sizes)
interval <- M_total / a
R <- runif(1, 0, interval)
sel_points <- R + (0:(a-1)) * interval
selected_psu <- integer(a)
for (k in 1:a) {
  selected_psu[k] <- min(which(cumulative >= sel_points[k]))
}

# Compute weights step by step
cat("============================================================\n")
cat("  DESIGN WEIGHT COMPUTATION\n")
cat("============================================================\n\n")

weight_table <- data.frame(
  psu_order = 1:a,
  ea_id     = sprintf("EA_%04d", selected_psu),
  M_i       = ea_sizes[selected_psu],
  stringsAsFactors = FALSE
)

# Stage 1 weights
weight_table$pi_1 <- a * weight_table$M_i / M_total
weight_table$w_1  <- 1 / weight_table$pi_1

# Stage 2 weights
weight_table$pi_2 <- b / weight_table$M_i
weight_table$w_2  <- 1 / weight_table$pi_2

# Overall weight
weight_table$pi_overall <- weight_table$pi_1 * weight_table$pi_2
weight_table$w_overall  <- weight_table$w_1 * weight_table$w_2

# Display first 10
cat("--- Weight decomposition (first 10 PSUs) ---\n")
cat(sprintf("%-4s | %-8s | %5s | %8s | %8s | %10s | %10s\n",
            "#", "EA", "M_i", "pi_1", "pi_2", "w_1", "w_overall"))
cat(paste(rep("-", 70), collapse = ""), "\n")
for (i in 1:min(10, a)) {
  cat(sprintf("%-4d | %-8s | %5d | %8.4f | %8.4f | %10.2f | %10.2f\n",
              i, weight_table$ea_id[i], weight_table$M_i[i],
              weight_table$pi_1[i], weight_table$pi_2[i],
              weight_table$w_1[i], weight_table$w_overall[i]))
}

# --- Verification 1: Sum of weights ≈ N ---
# Each PSU contributes b HH, each with weight w_overall
total_weight_sum <- sum(weight_table$w_overall * b)
cat(sprintf("\n--- Weight Sum Verification ---\n"))
cat(sprintf("  Sum of weights (a x b x w): %s\n",
            format(round(total_weight_sum), big.mark = ",")))
cat(sprintf("  True N                    : %s\n",
            format(N_total, big.mark = ",")))
cat(sprintf("  Ratio                     : %.4f\n",
            total_weight_sum / N_total))

stopifnot(abs(total_weight_sum / N_total - 1) < 0.01)
cat("[PASS] Weight sum matches population size.\n")

# --- Verification 2: Self-weighting ---
expected_w <- M_total / (a * b)
actual_cv <- sd(weight_table$w_overall) / mean(weight_table$w_overall)
cat(sprintf("\n--- Self-Weighting Check ---\n"))
cat(sprintf("  Expected constant weight: %.2f\n", expected_w))
cat(sprintf("  Mean actual weight      : %.2f\n", mean(weight_table$w_overall)))
cat(sprintf("  Weight CV               : %.6f\n", actual_cv))

stopifnot(actual_cv < 0.001)
cat("[PASS] Self-weighting design confirmed.\n")

# --- Weight distribution summary ---
cat(sprintf("\n--- Weight Distribution ---\n"))
cat(sprintf("  Min    : %.2f\n", min(weight_table$w_overall)))
cat(sprintf("  Q1     : %.2f\n", quantile(weight_table$w_overall, 0.25)))
cat(sprintf("  Median : %.2f\n", median(weight_table$w_overall)))
cat(sprintf("  Q3     : %.2f\n", quantile(weight_table$w_overall, 0.75)))
cat(sprintf("  Max    : %.2f\n", max(weight_table$w_overall)))
```

### Python — من الصفر

```python
# ============================================================
# Lesson 4.1: Design Weights (Base Weights)
# Python — From Scratch
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

# --- Setup ---
n_eas = 3000
ea_sizes = np.random.poisson(120, n_eas).clip(50)
M_total = ea_sizes.sum()

a = 180
b = 15

# PPS selection
cumul = np.cumsum(ea_sizes)
interval = M_total / a
R = np.random.uniform(0, interval)
sel_points = R + np.arange(a) * interval
selected_psu = np.searchsorted(cumul, sel_points).clip(0, n_eas - 1)

# Weight computation
M_i = ea_sizes[selected_psu]
pi_1 = a * M_i / M_total
w_1 = 1.0 / pi_1
pi_2 = b / M_i
w_2 = 1.0 / pi_2
w_overall = w_1 * w_2

print("=" * 60)
print("  DESIGN WEIGHT COMPUTATION")
print("=" * 60)

# Display
df = pd.DataFrame({
    'psu': range(1, a + 1),
    'M_i': M_i,
    'pi_1': np.round(pi_1, 4),
    'pi_2': np.round(pi_2, 4),
    'w_1': np.round(w_1, 2),
    'w_overall': np.round(w_overall, 2)
})
print(f"\n{df.head(10).to_string(index=False)}")

# Verification 1: weight sum
total_w = np.sum(w_overall * b)
print(f"\n--- Weight Sum ---")
print(f"  Sum of weights: {total_w:,.0f}")
print(f"  True N        : {M_total:,}")
print(f"  Ratio         : {total_w / M_total:.4f}")

assert abs(total_w / M_total - 1) < 0.01
print("[PASS] Weight sum matches N.")

# Verification 2: self-weighting
expected_w = M_total / (a * b)
cv = np.std(w_overall) / np.mean(w_overall)
print(f"\n--- Self-Weighting ---")
print(f"  Expected: {expected_w:.2f}")
print(f"  Mean    : {np.mean(w_overall):.2f}")
print(f"  CV      : {cv:.6f}")

assert cv < 0.001
print("[PASS] Self-weighting confirmed.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey

```r
# ============================================================
# Lesson 4.1: Weighted estimation with survey package
# ============================================================

library(survey)

set.seed(2024)

# Simulated sample with weights
sample_df <- data.frame(
  psu_id  = rep(1:a, each = b),
  weight  = rep(weight_table$w_overall, each = b),
  income  = rlnorm(a * b, 7.2, 0.8),
  poverty = rbinom(a * b, 1, 0.25)
)

design <- svydesign(id = ~psu_id, weights = ~weight, data = sample_df)

est_income  <- svymean(~income, design)
est_poverty <- svymean(~poverty, design)
est_total   <- svytotal(~income, design)

cat(sprintf("Mean income  : %.2f (SE: %.2f)\n", coef(est_income), SE(est_income)))
cat(sprintf("Poverty rate : %.4f (SE: %.4f)\n", coef(est_poverty), SE(est_poverty)))
cat(sprintf("Total income : %s (SE: %s)\n",
            format(round(coef(est_total)), big.mark = ","),
            format(round(SE(est_total)), big.mark = ",")))

# Verify weight sum = population
pop_est <- svytotal(~I(1), design)
cat(sprintf("\nEstimated N: %s\n", format(round(coef(pop_est)), big.mark = ",")))
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: weight_engine.py
# ============================================================

import numpy as np
from typing import Dict, List, Optional


class DesignWeightEngine:
    """Compute and validate multi-stage design weights."""

    def __init__(self, population_total: int):
        self.N = population_total
        self.stages = []

    def add_stage(self, name: str, pi_values: np.ndarray):
        """Add a sampling stage with its inclusion probabilities."""
        assert np.all(pi_values > 0), f"Stage '{name}': all pi must be > 0"
        assert np.all(pi_values <= 1.01), f"Stage '{name}': pi > 1 detected"
        self.stages.append({'name': name, 'pi': pi_values})

    def compute_weights(self) -> np.ndarray:
        """Compute overall weights as product of stage-specific inverses."""
        overall_pi = np.ones(len(self.stages[0]['pi']))
        for stage in self.stages:
            overall_pi *= stage['pi']
        return 1.0 / overall_pi

    def validate(self, weights: np.ndarray,
                 tolerance: float = 0.05) -> Dict:
        weight_sum = weights.sum()
        ratio = weight_sum / self.N
        cv = np.std(weights) / np.mean(weights)
        is_self_weighting = cv < 0.02

        return {
            'weight_sum': weight_sum,
            'population_N': self.N,
            'ratio': ratio,
            'within_tolerance': abs(ratio - 1) < tolerance,
            'cv': cv,
            'is_self_weighting': is_self_weighting,
            'min': weights.min(),
            'max': weights.max(),
            'mean': weights.mean()
        }
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الصيغة |
|-----------------|-------------------|--------|
| الوزن القاعدي | Base/Design Weight | $w_i = 1/\pi_i$ |
| احتمال الاشتمال الكلي | Overall Inclusion Probability | $\pi_{ij} = \pi_i^{(1)} \times \pi_{j|i}^{(2)}$ |
| التحقق من مجموع الأوزان | Weight Sum Check | $\sum w_{ij} \approx N$ |
| التصميم ذاتي الوزن | Self-Weighting | $w_{ij}$ ثابت لجميع الوحدات |

---

[→ الدرس السابق](../phase_3_sample_size_calibration/lesson_3_2_deff_icc_mechanics.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_4_2_nonresponse_propensity.md)

</div>
