<div dir="rtl" align="right">

# الدرس 0.3: ميكانيكا خطأ المعاينة مقابل الأخطاء غير العينية

[→ الدرس السابق](lesson_0_2_probability_vs_nonprob.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي: المرحلة 1 ←](../phase_1_infrastructure_frames/lesson_1_1_frame_diagnostics.md)

---

## 1. الشعار (Motto)

> **"خطأ المعاينة هو الخطأ الوحيد الذي يمكنك التحكم فيه رياضياً — كل شيء آخر يحتاج يقظة تشغيلية."**
>
> المسح الذي يتجاهل الأخطاء غير العينية كالذي يبني بيتاً بأساسات دقيقة ثم يترك السقف مفتوحاً للمطر.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء أجرى مسحاً للقوى العاملة (*Labor Force Survey*) بحجم عينة $n = 20,000$ أسرة. الخطأ المعياري المحسوب لمعدل البطالة كان 0.3% فقط — دقة عالية جداً.

لكن عند المقارنة مع بيانات التأمينات الاجتماعية، ظهر فرق **5 نقاط مئوية** كاملة! التحقيق كشف:
- 18% من الأسر المختارة رفضت المشاركة (*Non-Response*)
- العاطلون عن العمل كانوا أكثر تواجداً في المنزل وبالتالي أكثر استجابة
- سؤال "هل عملت ساعة واحدة على الأقل الأسبوع الماضي؟" فُسِّر بشكل مختلف في المناطق الريفية

**الدرس:** خطأ المعاينة الصغير (0.3%) كان يُخفي أخطاءً غير عينية ضخمة (5%).

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 تشريح الخطأ الكلي للمسح (Total Survey Error)

الخطأ الكلي (*Total Survey Error - TSE*) هو المسافة بين القيمة المقدَّرة والقيمة الحقيقية:

$$TSE = \hat{\theta} - \theta = \underbrace{(\hat{\theta} - E(\hat{\theta}))}_{\text{خطأ المعاينة}} + \underbrace{(E(\hat{\theta}) - \theta)}_{\text{التحيز (أخطاء غير عينية)}}$$

### 3.2 خطأ المعاينة (Sampling Error)

خطأ المعاينة (*Sampling Error*) هو التباين العشوائي الناتج عن اختيار عينة بدلاً من مسح المجتمع بأكمله. تحت المعاينة العشوائية البسيطة (*SRS*):

$$Var(\hat{\bar{Y}}_{SRS}) = \left(1 - \frac{n}{N}\right) \frac{S^2}{n}$$

**الخصائص الحاسمة:**
- يتقلص بزيادة $n$ (بمعدل $1/n$)
- يمكن **قياسه** من بيانات العينة نفسها
- يمكن **التحكم فيه** عبر تصميم العينة وحجمها
- يُصبح صفراً إذا $n = N$ (التعداد الشامل)

### 3.3 الأخطاء غير العينية (Non-Sampling Errors)

| النوع | المصدر | السلوك مع زيادة $n$ |
|-------|--------|---------------------|
| خطأ التغطية (*Coverage Error*) | الفجوة بين الإطار والمجتمع | لا يتأثر |
| خطأ عدم الاستجابة (*Non-Response Error*) | عدم جمع بيانات من وحدات مختارة | قد يتفاقم |
| خطأ القياس (*Measurement Error*) | أخطاء في الاستبيان أو الإجابات | قد يتفاقم |
| خطأ المعالجة (*Processing Error*) | أخطاء إدخال وترميز البيانات | قد يتفاقم |

### 3.4 نموذج تحيز عدم الاستجابة

إذا كان المجتمع ينقسم إلى مستجيبين (*Respondents*) ورافضين (*Non-Respondents*):

$$Bias_{NR} = (1 - r) \cdot (\bar{Y}_R - \bar{Y}_{NR})$$

حيث:
- $r$ = معدل الاستجابة
- $\bar{Y}_R$ = متوسط المستجيبين
- $\bar{Y}_{NR}$ = متوسط الرافضين

**الملاحظة المهمة:** حتى لو كان معدل الاستجابة 90% ($r = 0.9$)، فإن فرقاً بمقدار 10 وحدات بين المستجيبين والرافضين يُنتج تحيزاً = $0.1 \times 10 = 1.0$ — وهو تحيز **ثابت** لا يتأثر بحجم العينة.

### 3.5 المقايضة الحاسمة

$$MSE = \underbrace{Var(\hat{\theta})}_{\propto 1/n} + \underbrace{Bias^2}_{\text{ثابت أو يزداد مع } n}$$

عند نقطة معينة، زيادة $n$ لا تُحسِّن الدقة لأن التحيز يُهيمن على MSE.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### المهمة

محاكاة تُظهر بصرياً كيف يتصرف خطأ المعاينة مقابل تحيز عدم الاستجابة عند زيادة حجم العينة.

### R — من الصفر

```r
# ============================================================
# Lesson 0.3: Sampling Error vs Non-Sampling Error Mechanics
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Population setup ---
N <- 200000
income <- rlnorm(N, meanlog = 7.2, sdlog = 0.9)

# Non-response mechanism: lower income = less likely to respond
response_propensity <- plogis(-1.5 + 0.3 * scale(income))

theta <- mean(income)
cat(sprintf("True population mean: %.2f\n", theta))

# --- Experiment: vary sample size ---
sample_sizes <- c(100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000)
B <- 1000  # Replications per sample size

results <- data.frame(
  n             = integer(0),
  sampling_rmse = numeric(0),
  nr_bias       = numeric(0),
  total_rmse    = numeric(0)
)

for (n in sample_sizes) {
  srs_estimates  <- numeric(B)
  nr_estimates   <- numeric(B)

  for (b in 1:B) {
    # Draw SRS
    idx <- sample(1:N, n, replace = FALSE)

    # --- Scenario A: Full response (pure sampling error) ---
    srs_estimates[b] <- mean(income[idx])

    # --- Scenario B: Non-response mechanism ---
    responds <- rbinom(n, 1, response_propensity[idx])
    if (sum(responds) > 0) {
      nr_estimates[b] <- mean(income[idx[responds == 1]])
    } else {
      nr_estimates[b] <- NA
    }
  }

  nr_estimates <- nr_estimates[!is.na(nr_estimates)]

  results <- rbind(results, data.frame(
    n             = n,
    sampling_rmse = sqrt(mean((srs_estimates - theta)^2)),
    nr_bias       = abs(mean(nr_estimates) - theta),
    total_rmse    = sqrt(mean((nr_estimates - theta)^2))
  ))
}

# --- Display results ---
cat("\n============================================================\n")
cat("  SAMPLING ERROR vs NON-RESPONSE BIAS by Sample Size\n")
cat("============================================================\n")
cat(sprintf("%-10s | %-14s | %-14s | %-14s\n",
            "n", "Sampling RMSE", "NR Bias", "Total RMSE"))
cat(paste(rep("-", 60), collapse = ""), "\n")

for (i in 1:nrow(results)) {
  cat(sprintf("%-10s | %-14.2f | %-14.2f | %-14.2f\n",
              format(results$n[i], big.mark = ","),
              results$sampling_rmse[i],
              results$nr_bias[i],
              results$total_rmse[i]))
}

# --- Key assertions ---
# Sampling error should decrease with n
for (i in 2:nrow(results)) {
  stopifnot(results$sampling_rmse[i] <= results$sampling_rmse[i-1] * 1.1)
}
cat("\n[PASS] Sampling error decreases with n.\n")

# NR bias should remain roughly constant
nr_bias_range <- range(results$nr_bias)
stopifnot(nr_bias_range[2] / nr_bias_range[1] < 3)
cat("[PASS] Non-response bias remains persistent across sample sizes.\n")

# At large n, total RMSE is dominated by bias
large_n_row <- results[results$n == max(results$n), ]
stopifnot(large_n_row$nr_bias > large_n_row$sampling_rmse)
cat("[PASS] At large n, bias dominates total error.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 0.3: Sampling Error vs Non-Sampling Error Mechanics
# Python — From Scratch
# ============================================================

import numpy as np
from scipy.special import expit

np.random.seed(2024)

# --- Population setup ---
N = 200000
income = np.random.lognormal(mean=7.2, sigma=0.9, size=N)

# Non-response: higher income = more likely to respond
response_propensity = expit(-1.5 + 0.3 * (income - income.mean()) / income.std())

theta = np.mean(income)
print(f"True population mean: {theta:.2f}")

# --- Experiment ---
sample_sizes = [100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000]
B = 1000

print(f"\n{'n':>10} | {'Sampling RMSE':>14} | {'NR Bias':>14} | {'Total RMSE':>14}")
print("-" * 60)

prev_rmse = float('inf')
results = []

for n in sample_sizes:
    srs_est = np.zeros(B)
    nr_est = []

    for b in range(B):
        idx = np.random.choice(N, size=n, replace=False)

        # Scenario A: Full response
        srs_est[b] = np.mean(income[idx])

        # Scenario B: Non-response
        responds = np.random.binomial(1, response_propensity[idx])
        if responds.sum() > 0:
            nr_est.append(np.mean(income[idx[responds == 1]]))

    nr_est = np.array(nr_est)

    sampling_rmse = np.sqrt(np.mean((srs_est - theta)**2))
    nr_bias = abs(np.mean(nr_est) - theta)
    total_rmse = np.sqrt(np.mean((nr_est - theta)**2))

    print(f"{n:>10,} | {sampling_rmse:>14.2f} | {nr_bias:>14.2f} | {total_rmse:>14.2f}")

    results.append({
        'n': n, 'sampling_rmse': sampling_rmse,
        'nr_bias': nr_bias, 'total_rmse': total_rmse
    })

    # Assert sampling error decreases
    assert sampling_rmse <= prev_rmse * 1.1, \
        f"Sampling RMSE should decrease: {sampling_rmse} vs {prev_rmse}"
    prev_rmse = sampling_rmse

print("\n[PASS] Sampling error decreases with n.")

# Assert bias persistence
biases = [r['nr_bias'] for r in results]
assert max(biases) / min(biases) < 3, "NR bias should be persistent"
print("[PASS] Non-response bias remains persistent across sample sizes.")

# At large n, bias dominates
last = results[-1]
assert last['nr_bias'] > last['sampling_rmse'], \
    "At large n, bias should dominate"
print("[PASS] At large n, bias dominates total error.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### أدوات رصد جودة البيانات في R

```r
# ============================================================
# Lesson 0.3: Non-Response Analysis with survey package
# ============================================================

library(survey)

set.seed(2024)

# Simulate a completed survey with non-response info
N <- 50000
n <- 2000

population <- data.frame(
  id       = 1:N,
  income   = rlnorm(N, 7.2, 0.9),
  age      = sample(18:75, N, replace = TRUE),
  urban    = rbinom(N, 1, 0.6)
)

# Draw SRS
idx <- sample(1:N, n, replace = FALSE)
sample_df <- population[idx, ]

# Simulate non-response (income-dependent)
sample_df$response_prob <- plogis(-0.5 + 0.2 * scale(sample_df$income))
sample_df$responded <- rbinom(n, 1, sample_df$response_prob)

response_rate <- mean(sample_df$responded)
cat(sprintf("Response rate: %.1f%%\n", response_rate * 100))

# Respondents only
respondents <- sample_df[sample_df$responded == 1, ]
respondents$weight <- N / nrow(respondents)

# Design without non-response adjustment
design_naive <- svydesign(
  id = ~1, weights = ~weight, data = respondents
)

est_naive <- svymean(~income, design_naive)
cat(sprintf("\nNaive estimate (respondents only): %.2f\n", coef(est_naive)))
cat(sprintf("True population mean            : %.2f\n", mean(population$income)))
cat(sprintf("Difference                      : %.2f\n",
            coef(est_naive) - mean(population$income)))
```

### Python — تحليل أنماط عدم الاستجابة

```python
# ============================================================
# Lesson 0.3: Non-Response Pattern Analysis
# Python — Using pandas for diagnostics
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(2024)

N = 50000
n = 2000

population = pd.DataFrame({
    'id': range(N),
    'income': np.random.lognormal(7.2, 0.9, N),
    'age': np.random.randint(18, 76, N),
    'urban': np.random.binomial(1, 0.6, N)
})

# Draw SRS
sample_df = population.sample(n=n, random_state=2024).copy()

# Non-response mechanism
from scipy.special import expit
sample_df['resp_prob'] = expit(-0.5 + 0.2 *
    (sample_df['income'] - sample_df['income'].mean()) /
    sample_df['income'].std())
sample_df['responded'] = np.random.binomial(1, sample_df['resp_prob'])

print(f"Response rate: {sample_df['responded'].mean()*100:.1f}%")

# Compare respondents vs non-respondents
resp = sample_df[sample_df['responded'] == 1]
non_resp = sample_df[sample_df['responded'] == 0]

print(f"\n{'Variable':<15} {'Respondents':>12} {'Non-Resp':>12} {'Difference':>12}")
print("-" * 55)
for col in ['income', 'age', 'urban']:
    r_mean = resp[col].mean()
    nr_mean = non_resp[col].mean()
    print(f"{col:<15} {r_mean:>12.2f} {nr_mean:>12.2f} {r_mean - nr_mean:>12.2f}")

true_mean = population['income'].mean()
naive_mean = resp['income'].mean()
print(f"\nTrue population mean : {true_mean:.2f}")
print(f"Naive (resp only)    : {naive_mean:.2f}")
print(f"Bias                 : {naive_mean - true_mean:.2f}")
```

---

## 6. أطلقها (Ship It — Production Artifact)

### لوحة مراقبة جودة المسح (Survey Quality Dashboard)

```r
# ============================================================
# PRODUCTION: survey_quality_dashboard.R
# Automated Total Survey Error diagnostic report
# ============================================================

generate_tse_report <- function(sample_data,
                                 response_col,
                                 weight_col,
                                 key_variables,
                                 frame_size,
                                 known_totals = NULL) {

  cat("============================================================\n")
  cat("  TOTAL SURVEY ERROR (TSE) DIAGNOSTIC REPORT\n")
  cat("============================================================\n\n")

  n_selected <- nrow(sample_data)
  n_responded <- sum(sample_data[[response_col]] == 1, na.rm = TRUE)
  resp_rate <- n_responded / n_selected

  cat("--- 1. RESPONSE ANALYSIS ---\n")
  cat(sprintf("  Selected sample   : %s\n", format(n_selected, big.mark = ",")))
  cat(sprintf("  Respondents       : %s\n", format(n_responded, big.mark = ",")))
  cat(sprintf("  Response rate     : %.1f%%\n", resp_rate * 100))

  if (resp_rate < 0.70) {
    cat("  [ALERT] Response rate below 70%% threshold!\n")
  } else if (resp_rate < 0.85) {
    cat("  [WARNING] Response rate below 85%% — monitor closely\n")
  } else {
    cat("  [OK] Response rate acceptable\n")
  }

  # Non-response bias indicators
  cat("\n--- 2. NON-RESPONSE BIAS INDICATORS ---\n")
  resp_data <- sample_data[sample_data[[response_col]] == 1, ]
  nonresp_data <- sample_data[sample_data[[response_col]] == 0, ]

  cat(sprintf("  %-20s | %-12s | %-12s | %-10s\n",
              "Variable", "Respondents", "Non-Resp", "Diff"))
  cat(paste(rep("-", 62), collapse = ""), "\n")

  for (var in key_variables) {
    if (is.numeric(sample_data[[var]])) {
      r_mean <- mean(resp_data[[var]], na.rm = TRUE)
      nr_mean <- mean(nonresp_data[[var]], na.rm = TRUE)
      diff_val <- r_mean - nr_mean
      cat(sprintf("  %-20s | %12.2f | %12.2f | %10.2f\n",
                  var, r_mean, nr_mean, diff_val))
    }
  }

  # Sampling error
  cat("\n--- 3. SAMPLING ERROR INDICATORS ---\n")
  for (var in key_variables) {
    if (is.numeric(resp_data[[var]])) {
      w <- resp_data[[weight_col]]
      y <- resp_data[[var]]
      valid <- !is.na(y) & !is.na(w)
      est <- sum(y[valid] * w[valid]) / sum(w[valid])
      # Approximate SE (SRS approximation)
      se_approx <- sqrt((1 - n_responded / frame_size) *
                        var(y[valid], na.rm = TRUE) / n_responded)
      cv <- (se_approx / abs(est)) * 100
      cat(sprintf("  %-20s: Est = %.2f, SE ~ %.2f, CV ~ %.1f%%\n",
                  var, est, se_approx, cv))
    }
  }

  # Coverage check
  if (!is.null(known_totals)) {
    cat("\n--- 4. COVERAGE CHECK ---\n")
    for (var_name in names(known_totals)) {
      if (var_name %in% names(resp_data)) {
        weighted_total <- sum(resp_data[[var_name]] *
                             resp_data[[weight_col]], na.rm = TRUE)
        known <- known_totals[[var_name]]
        coverage_ratio <- weighted_total / known
        cat(sprintf("  %-20s: Weighted = %s, Known = %s, Ratio = %.3f\n",
                    var_name,
                    format(round(weighted_total), big.mark = ","),
                    format(known, big.mark = ","),
                    coverage_ratio))
      }
    }
  }

  cat("\n============================================================\n")
  cat("  END OF TSE DIAGNOSTIC REPORT\n")
  cat("============================================================\n")
}
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | النقطة الجوهرية |
|-----------------|-------------------|----------------|
| الخطأ الكلي للمسح | Total Survey Error (TSE) | مجموع خطأ المعاينة والأخطاء غير العينية |
| خطأ المعاينة | Sampling Error | يتقلص بمعدل $1/\sqrt{n}$ |
| تحيز عدم الاستجابة | Non-Response Bias | ثابت مع زيادة $n$ |
| خطأ القياس | Measurement Error | ناتج عن تصميم الاستبيان |
| خطأ التغطية | Coverage Error | الفجوة بين الإطار والمجتمع |
| معدل الاستجابة | Response Rate | مؤشر جودة تشغيلي حاسم |

---

[→ الدرس السابق](lesson_0_2_probability_vs_nonprob.md) | [العودة إلى الفهرس](../../README.md) | [المرحلة 1 ←](../phase_1_infrastructure_frames/lesson_1_1_frame_diagnostics.md)

</div>
