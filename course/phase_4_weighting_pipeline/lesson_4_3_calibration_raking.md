<div dir="rtl" align="right">

# الدرس 4.3: معايرة الأوزان — ما بعد الطبقية والتوازن التكراري

[→ الدرس السابق](lesson_4_2_nonresponse_propensity.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي: المرحلة 5 ←](../phase_5_variance_estimation/lesson_5_1_taylor_linearization.md)

---

## 1. الشعار (Motto)

> **"اجعل عينتك تتحدث بلسان المجتمع — أجبر الأوزان على إعادة إنتاج الإجماليات المعروفة."**
>
> المعايرة هي الخطوة الأخيرة في خط الأوزان: تُزيل التحيز المتبقي وتُحسِّن الدقة.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

بعد تعديل عدم الاستجابة، وجد الفريق أن العينة الموزونة تُعطي:
- 52% ذكور و48% إناث — بينما الإسقاطات السكانية تقول 49% و51%
- الفئة العمرية 18-30 ممثلة بـ 18% — بينما الإسقاطات تقول 25%

**المعايرة** (*Calibration*) تُعدِّل الأوزان لتتطابق الإجماليات الموزونة مع الإجماليات المعروفة من مصادر خارجية.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 ما بعد الطبقية (Post-Stratification)

أبسط أشكال المعايرة: تعديل الأوزان داخل كل خلية (*cell*) تعريفية:

$$w_i^{cal} = w_i^{adj} \times \frac{N_c}{\sum_{j \in c, j \in s} w_j^{adj}}$$

حيث $c$ هي الخلية (مثلاً: ذكور 18-30 في الحضر) و $N_c$ هو العدد المعروف.

### 3.2 التوازن التكراري — خوارزمية IPF (Raking / Iterative Proportional Fitting)

عندما تكون الإجماليات المعروفة **هامشية** (*marginal*) فقط (مثلاً: إجمالي الذكور + إجمالي الفئة 18-30، لكن ليس إجمالي "ذكور 18-30"):

**الخوارزمية:**
1. عدِّل الأوزان لمطابقة هامش الجنس
2. عدِّل الأوزان لمطابقة هامش العمر
3. عدِّل الأوزان لمطابقة هامش المنطقة
4. كرِّر حتى التقارب (جميع الهوامش مُطابقة)

### 3.3 شرط التقارب

$$\max_c \left| \frac{\sum_{i \in s} w_i^{(t)} \cdot \mathbf{1}(i \in c)}{N_c} - 1 \right| < \epsilon$$

حيث $\epsilon$ عتبة صغيرة (مثلاً 0.001).

---

## 4. ابنِها من الصفر (Build It From Scratch)

### R — خوارزمية IPF من الصفر

```r
# ============================================================
# Lesson 4.3: Calibration / Raking via IPF
# R — From Scratch (basic matrix algebra)
# ============================================================

set.seed(2024)

# --- Generate sample with known population margins ---
n <- 3000
sample_df <- data.frame(
  sex      = sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.52, 0.48)),
  age_grp  = sample(c("18-30", "31-45", "46-60", "61+"), n, replace = TRUE,
                     prob = c(0.18, 0.32, 0.30, 0.20)),
  region   = sample(c("Urban", "Rural"), n, replace = TRUE, prob = c(0.65, 0.35)),
  income   = rlnorm(n, 7.0, 0.8),
  weight   = 200,  # Initial base weight
  stringsAsFactors = FALSE
)

N_pop <- n * 200  # Total population

# Known population margins (from census projections)
margins <- list(
  sex = c(Male = 0.49 * N_pop, Female = 0.51 * N_pop),
  age_grp = c("18-30" = 0.25 * N_pop, "31-45" = 0.30 * N_pop,
              "46-60" = 0.28 * N_pop, "61+" = 0.17 * N_pop),
  region = c(Urban = 0.58 * N_pop, Rural = 0.42 * N_pop)
)

cat("============================================================\n")
cat("  ITERATIVE PROPORTIONAL FITTING (RAKING)\n")
cat("============================================================\n\n")

# --- Show pre-calibration mismatch ---
cat("--- Before calibration ---\n")
for (var_name in names(margins)) {
  weighted_totals <- tapply(sample_df$weight, sample_df[[var_name]], sum)
  cat(sprintf("  %s:\n", var_name))
  for (cat_name in names(margins[[var_name]])) {
    wt <- weighted_totals[cat_name]
    target <- margins[[var_name]][cat_name]
    cat(sprintf("    %-8s: weighted=%8.0f, target=%8.0f, ratio=%.3f\n",
                cat_name, wt, target, wt / target))
  }
}

# ============================================================
# IPF ALGORITHM
# ============================================================

w <- sample_df$weight  # Working weights
max_iter <- 100
tol <- 0.001

cat(sprintf("\n--- Running IPF (tol=%.4f, max_iter=%d) ---\n", tol, max_iter))

for (iter in 1:max_iter) {
  max_diff <- 0

  for (var_name in names(margins)) {
    targets <- margins[[var_name]]
    variable <- sample_df[[var_name]]

    for (cat_name in names(targets)) {
      mask <- variable == cat_name
      current_total <- sum(w[mask])
      target_total <- targets[cat_name]

      if (current_total > 0) {
        factor <- target_total / current_total
        w[mask] <- w[mask] * factor
        max_diff <- max(max_diff, abs(factor - 1))
      }
    }
  }

  if (iter <= 5 || iter %% 10 == 0) {
    cat(sprintf("  Iteration %3d: max adjustment factor deviation = %.6f\n",
                iter, max_diff))
  }

  if (max_diff < tol) {
    cat(sprintf("  CONVERGED at iteration %d\n", iter))
    break
  }
}

sample_df$cal_weight <- w

# --- Verify calibration ---
cat("\n--- After calibration ---\n")
all_match <- TRUE
for (var_name in names(margins)) {
  weighted_totals <- tapply(sample_df$cal_weight, sample_df[[var_name]], sum)
  for (cat_name in names(margins[[var_name]])) {
    wt <- weighted_totals[cat_name]
    target <- margins[[var_name]][cat_name]
    ratio <- wt / target
    cat(sprintf("  %s / %-8s: ratio=%.6f\n", var_name, cat_name, ratio))
    if (abs(ratio - 1) > 0.001) all_match <- FALSE
  }
}

stopifnot(all_match)
cat("\n[PASS] All margins matched after raking.\n")

# --- Weight diagnostics ---
cat(sprintf("\n--- Weight diagnostics ---\n"))
cat(sprintf("  Original weight: %.0f (constant)\n", 200))
cat(sprintf("  Calibrated range: [%.1f, %.1f]\n",
            min(sample_df$cal_weight), max(sample_df$cal_weight)))
cat(sprintf("  Calibrated CV   : %.1f%%\n",
            sd(sample_df$cal_weight) / mean(sample_df$cal_weight) * 100))
cat(sprintf("  Weight sum      : %s (target: %s)\n",
            format(round(sum(sample_df$cal_weight)), big.mark = ","),
            format(N_pop, big.mark = ",")))

stopifnot(abs(sum(sample_df$cal_weight) - N_pop) < 1)
cat("[PASS] Total weight equals population.\n")
```

### Python — خوارزمية IPF من الصفر

```python
# ============================================================
# Lesson 4.3: Calibration / Raking via IPF
# Python — From Scratch (basic arrays)
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

n = 3000
sample_df = pd.DataFrame({
    'sex': np.random.choice(['Male', 'Female'], n, p=[0.52, 0.48]),
    'age_grp': np.random.choice(['18-30', '31-45', '46-60', '61+'], n,
                                 p=[0.18, 0.32, 0.30, 0.20]),
    'region': np.random.choice(['Urban', 'Rural'], n, p=[0.65, 0.35]),
    'income': np.random.lognormal(7.0, 0.8, n),
    'weight': 200.0
})

N_pop = n * 200

margins = {
    'sex': {'Male': 0.49 * N_pop, 'Female': 0.51 * N_pop},
    'age_grp': {'18-30': 0.25*N_pop, '31-45': 0.30*N_pop,
                '46-60': 0.28*N_pop, '61+': 0.17*N_pop},
    'region': {'Urban': 0.58 * N_pop, 'Rural': 0.42 * N_pop}
}

print("=" * 60)
print("  ITERATIVE PROPORTIONAL FITTING (RAKING)")
print("=" * 60)

# Show mismatch before
print("\n--- Before calibration ---")
for var, targets in margins.items():
    for cat, target in targets.items():
        current = sample_df.loc[sample_df[var] == cat, 'weight'].sum()
        print(f"  {var}/{cat:<8}: current={current:>10,.0f}  target={target:>10,.0f}  "
              f"ratio={current/target:.3f}")

# --- IPF ---
w = sample_df['weight'].values.copy()
max_iter = 100
tol = 0.001

print(f"\n--- Running IPF ---")

for iteration in range(1, max_iter + 1):
    max_diff = 0

    for var, targets in margins.items():
        col = sample_df[var].values
        for cat, target in targets.items():
            mask = col == cat
            current = w[mask].sum()
            if current > 0:
                factor = target / current
                w[mask] *= factor
                max_diff = max(max_diff, abs(factor - 1))

    if iteration <= 5 or iteration % 10 == 0:
        print(f"  Iter {iteration:>3}: max_diff = {max_diff:.6f}")

    if max_diff < tol:
        print(f"  CONVERGED at iteration {iteration}")
        break

sample_df['cal_weight'] = w

# Verify
print("\n--- After calibration ---")
all_ok = True
for var, targets in margins.items():
    for cat, target in targets.items():
        current = sample_df.loc[sample_df[var] == cat, 'cal_weight'].sum()
        ratio = current / target
        print(f"  {var}/{cat:<8}: ratio={ratio:.6f}")
        if abs(ratio - 1) > 0.001:
            all_ok = False

assert all_ok, "Not all margins matched!"
print("\n[PASS] All margins matched.")

# Weight diagnostics
print(f"\n--- Weight diagnostics ---")
print(f"  Range: [{w.min():.1f}, {w.max():.1f}]")
print(f"  CV   : {w.std()/w.mean()*100:.1f}%")
print(f"  Sum  : {w.sum():,.0f} (target: {N_pop:,})")

assert abs(w.sum() - N_pop) < 1
print("[PASS] Weight sum = population total.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey (calibrate)

```r
# ============================================================
# Lesson 4.3: Calibration with survey::calibrate
# ============================================================

library(survey)

# Initial design
design_init <- svydesign(id = ~1, weights = ~weight, data = sample_df)

# Population totals for calibration
pop_totals <- c(
  `(Intercept)` = N_pop,
  sexMale = 0.49 * N_pop,
  `age_grp31-45` = 0.30 * N_pop,
  `age_grp46-60` = 0.28 * N_pop,
  `age_grp61+` = 0.17 * N_pop,
  regionUrban = 0.58 * N_pop
)

design_cal <- calibrate(design_init,
                         formula = ~sex + age_grp + region,
                         population = pop_totals,
                         calfun = "raking")

# Compare estimates
est_before <- svymean(~income, design_init)
est_after  <- svymean(~income, design_cal)

cat(sprintf("Before calibration: %.2f (SE: %.2f)\n",
            coef(est_before), SE(est_before)))
cat(sprintf("After calibration : %.2f (SE: %.2f)\n",
            coef(est_after), SE(est_after)))

# Verify margins
cat("\nMargin check (sex):\n")
print(svytotal(~sex, design_cal))
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: calibrator.py
# ============================================================

import numpy as np
import pandas as pd
from typing import Dict


class SurveyCalibrator:
    """Calibrate survey weights to known population margins via IPF/raking."""

    def __init__(self, df: pd.DataFrame, weight_col: str):
        self.df = df.copy()
        self.weight_col = weight_col
        self.margins = {}
        self.converged = False
        self.iterations = 0

    def add_margin(self, variable: str, totals: Dict[str, float]):
        self.margins[variable] = totals

    def rake(self, max_iter: int = 200, tol: float = 0.001,
             trim: tuple = None) -> pd.Series:
        w = self.df[self.weight_col].values.copy()

        for it in range(1, max_iter + 1):
            max_diff = 0
            for var, targets in self.margins.items():
                col = self.df[var].values
                for cat, target in targets.items():
                    mask = col == cat
                    current = w[mask].sum()
                    if current > 0:
                        f = target / current
                        w[mask] *= f
                        max_diff = max(max_diff, abs(f - 1))

            if max_diff < tol:
                self.converged = True
                self.iterations = it
                break

        if trim:
            lo, hi = np.percentile(w, [trim[0]*100, trim[1]*100])
            w = np.clip(w, lo, hi)
            # Re-normalize
            total_target = sum(sum(t.values()) for t in self.margins.values()) / len(self.margins)
            w *= total_target / w.sum()

        self.df['calibrated_weight'] = w
        return pd.Series(w, index=self.df.index)

    def check_margins(self) -> pd.DataFrame:
        results = []
        for var, targets in self.margins.items():
            for cat, target in targets.items():
                actual = self.df.loc[
                    self.df[var] == cat, 'calibrated_weight'
                ].sum()
                results.append({
                    'variable': var, 'category': cat,
                    'target': target, 'actual': actual,
                    'ratio': actual / target if target > 0 else np.nan
                })
        return pd.DataFrame(results)
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | النقطة الجوهرية |
|-----------------|-------------------|----------------|
| المعايرة | Calibration | مطابقة الأوزان مع إجماليات معروفة |
| ما بعد الطبقية | Post-Stratification | معايرة على خلايا كاملة |
| التوازن التكراري | Raking / IPF | معايرة على هوامش تكرارياً |
| الإجماليات المعروفة | Known Margins/Benchmarks | من التعداد أو الإسقاطات السكانية |
| التقارب | Convergence | $\max|factor - 1| < \epsilon$ |

---

[→ الدرس السابق](lesson_4_2_nonresponse_propensity.md) | [العودة إلى الفهرس](../../README.md) | [المرحلة 5 ←](../phase_5_variance_estimation/lesson_5_1_taylor_linearization.md)

</div>
