<div dir="rtl" align="right">

# الدرس 0.1: مقدمة في مفاهيم معاينة المسوح

[العودة إلى الفهرس الرئيسي](../../README.md) | [الدرس التالي ←](lesson_0_2_probability_vs_nonprob.md)

---

## 1. الشعار (Motto)

> **"لا تحتاج أن تشرب البحر كله لتعرف أنه مالح."**
>
> المعاينة الإحصائية هي علم الاستدلال على الكل من الجزء — بشرط أن يكون الجزء مختاراً بذكاء رياضي.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مكتب الإحصاء الوطني في بلد يضم **8 ملايين أسرة** يحتاج إلى تقدير معدل البطالة الوطني (*National Unemployment Rate*) قبل اجتماع مجلس الوزراء بـ 45 يوماً. الميزانية المتاحة تكفي لزيارة **15,000 أسرة** فقط. التعداد الشامل (*Census*) مستحيل: يحتاج 18 شهراً و200 مليون وحدة نقدية.

**السؤال المحوري:** كيف يمكن أن نستدل على 8 ملايين أسرة من 15,000 فقط — وأن نضع حدوداً رياضية دقيقة لمقدار خطأ هذا الاستدلال؟

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 المجتمع المستهدف والمعلمة

**المجتمع المستهدف** (*Target Population*) هو المجموعة الكاملة من الوحدات التي نريد الاستدلال عنها. نرمز لحجمه بـ $N$.

**المعلمة** (*Parameter*) هي الكمية المجهولة التي نريد تقديرها في المجتمع. نرمز لها بـ $\theta$.

مثال: متوسط الدخل الشهري لجميع الأسر:

$$\theta = \bar{Y} = \frac{1}{N}\sum_{i=1}^{N} Y_i$$

### 3.2 العينة والمقدِّر

**العينة** (*Sample*) هي مجموعة جزئية من المجتمع حجمها $n$ حيث $n \ll N$.

**المقدِّر** (*Estimator*) هو دالة حسابية تُطبَّق على بيانات العينة لتقدير المعلمة. نرمز له بـ $\hat{\theta}$.

$$\hat{\bar{Y}} = \frac{1}{n}\sum_{i=1}^{n} y_i$$

### 3.3 عدم التحيز (Unbiasedness)

المقدِّر **غير متحيز** (*Unbiased*) إذا وفقط إذا كانت قيمته المتوقعة تساوي المعلمة الحقيقية عبر جميع العينات الممكنة:

$$E(\hat{\theta}) = \theta$$

هذا يعني أننا لو سحبنا آلاف العينات وحسبنا المقدِّر في كل مرة، فإن **متوسط جميع التقديرات** سيساوي القيمة الحقيقية.

### 3.4 متوسط مربع الخطأ (MSE)

**متوسط مربع الخطأ** (*Mean Squared Error*) يقيس الدقة الكلية للمقدِّر بجمع مكونَيْن:

$$MSE(\hat{\theta}) = Var(\hat{\theta}) + [Bias(\hat{\theta})]^2$$

حيث:
- **التباين** (*Variance*): مقدار تشتت المقدِّر حول قيمته المتوقعة
- **التحيز** (*Bias*): الانحراف المنهجي $Bias = E(\hat{\theta}) - \theta$

> **القاعدة الذهبية:** المقدِّر المثالي يحقق $MSE = 0$، وهذا يستلزم أن يكون غير متحيز ($Bias = 0$) وأن تباينه صفر — وهو مستحيل عملياً. هدفنا هو **تقليل MSE** إلى أدنى حد ممكن.

### 3.5 إطار المعاينة (Sampling Frame)

**إطار المعاينة** (*Sampling Frame*) هو القائمة الفعلية التي نسحب منها العينة. نادراً ما يتطابق تماماً مع المجتمع المستهدف:

```
المجتمع المستهدف (Target Population)
        ⊇
إطار المعاينة (Sampling Frame)
        ⊇
العينة المسحوبة (Selected Sample)
        ⊇
العينة المستجيبة (Responding Sample)
```

كل فجوة بين هذه المستويات تُولِّد نوعاً مختلفاً من الخطأ.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### المهمة

توليد مجتمع صغير، سحب عدة عينات عشوائية بسيطة، وحساب المقدِّر وتباينه يدوياً للتحقق من خاصية عدم التحيز تجريبياً.

### R — من الصفر

```r
# ============================================================
# Lesson 0.1: Verifying Unbiasedness via Simulation
# R — From Scratch (No survey packages)
# ============================================================

set.seed(42)

# --- Generate a small population ---
N <- 10000
population <- data.frame(
  id     = 1:N,
  income = rlnorm(N, meanlog = 7.5, sdlog = 0.9)
)

# True population parameter (theta)
theta <- mean(population$income)
cat(sprintf("True population mean (theta): %.4f\n", theta))

# --- Repeated sampling experiment ---
n <- 200           # Sample size
B <- 5000          # Number of replications

estimates <- numeric(B)

for (b in 1:B) {
  # Simple Random Sampling Without Replacement
  idx <- sample(1:N, n, replace = FALSE)
  sample_data <- population$income[idx]

  # Sample mean as estimator
  estimates[b] <- mean(sample_data)
}

# --- Verify unbiasedness ---
expected_value <- mean(estimates)
bias <- expected_value - theta
variance_est <- var(estimates)
mse <- variance_est + bias^2

cat(sprintf("\n--- Simulation Results (B = %d) ---\n", B))
cat(sprintf("E(theta_hat)   : %.4f\n", expected_value))
cat(sprintf("theta (true)   : %.4f\n", theta))
cat(sprintf("Bias           : %.4f\n", bias))
cat(sprintf("Variance       : %.4f\n", variance_est))
cat(sprintf("MSE            : %.4f\n", mse))

# --- Theoretical variance under SRSWOR ---
S2 <- var(population$income)  # Population variance (using N-1)
theoretical_var <- (1 - n/N) * S2 / n
cat(sprintf("\nTheoretical Var: %.4f\n", theoretical_var))
cat(sprintf("Simulated Var  : %.4f\n", variance_est))
cat(sprintf("Ratio          : %.4f (should be ~1.0)\n",
            variance_est / theoretical_var))

# Assertion: bias should be negligible
stopifnot(abs(bias) < 0.5 * sqrt(theoretical_var))
cat("\n[PASS] Unbiasedness verified.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 0.1: Verifying Unbiasedness via Simulation
# Python — From Scratch (No specialized libraries)
# ============================================================

import numpy as np

np.random.seed(42)

# --- Generate a small population ---
N = 10000
population_income = np.random.lognormal(mean=7.5, sigma=0.9, size=N)

# True population parameter
theta = np.mean(population_income)
print(f"True population mean (theta): {theta:.4f}")

# --- Repeated sampling experiment ---
n = 200
B = 5000

estimates = np.zeros(B)

for b in range(B):
    # Simple Random Sampling Without Replacement
    idx = np.random.choice(N, size=n, replace=False)
    sample_data = population_income[idx]
    estimates[b] = np.mean(sample_data)

# --- Verify unbiasedness ---
expected_value = np.mean(estimates)
bias = expected_value - theta
variance_est = np.var(estimates, ddof=1)
mse = variance_est + bias**2

print(f"\n--- Simulation Results (B = {B}) ---")
print(f"E(theta_hat)   : {expected_value:.4f}")
print(f"theta (true)   : {theta:.4f}")
print(f"Bias           : {bias:.4f}")
print(f"Variance       : {variance_est:.4f}")
print(f"MSE            : {mse:.4f}")

# --- Theoretical variance under SRSWOR ---
S2 = np.var(population_income, ddof=1)
theoretical_var = (1 - n / N) * S2 / n
print(f"\nTheoretical Var: {theoretical_var:.4f}")
print(f"Simulated Var  : {variance_est:.4f}")
print(f"Ratio          : {variance_est / theoretical_var:.4f} (should be ~1.0)")

# Assertion
assert abs(bias) < 0.5 * np.sqrt(theoretical_var), "Bias too large!"
print("\n[PASS] Unbiasedness verified.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

في هذا الدرس التأسيسي، الحزم الإنتاجية ليست ضرورية بعد لأننا نتعامل مع مفاهيم أساسية. لكن يمكن استخدام حزمة `survey` في R لتوضيح كيف تُعرَّف تصاميم المعاينة:

### R — حزمة survey

```r
# ============================================================
# Lesson 0.1: Introduction to the survey package design object
# ============================================================

library(survey)

set.seed(42)

# Generate population and draw one SRS sample
N <- 10000
population <- data.frame(
  id     = 1:N,
  income = rlnorm(N, meanlog = 7.5, sdlog = 0.9)
)

n <- 200
idx <- sample(1:N, n, replace = FALSE)
sample_data <- population[idx, ]

# Define survey design (SRS without replacement)
design <- svydesign(
  id      = ~1,          # No clusters (element-level sampling)
  fpc     = rep(N, n),   # Finite Population Correction
  data    = sample_data
)

# Estimate mean
est <- svymean(~income, design)
print(est)

# Compare with manual calculation
manual_mean <- mean(sample_data$income)
cat(sprintf("\nManual mean : %.4f\n", manual_mean))
cat(sprintf("svymean     : %.4f\n", coef(est)))

stopifnot(abs(coef(est) - manual_mean) < 1e-10)
cat("[PASS] Manual and survey package estimates match.\n")
```

### Python — samplics

```python
# ============================================================
# Lesson 0.1: Introduction to samplics estimation
# ============================================================

import numpy as np
import pandas as pd

np.random.seed(42)

N = 10000
population = pd.DataFrame({
    'id': range(1, N + 1),
    'income': np.random.lognormal(mean=7.5, sigma=0.9, size=N)
})

n = 200
sample_df = population.sample(n=n, random_state=42).copy()
sample_df['weight'] = N / n  # Base weight for SRS

# Manual estimate
manual_mean = sample_df['income'].mean()
weighted_mean = np.average(sample_df['income'], weights=sample_df['weight'])

print(f"Manual mean   : {manual_mean:.4f}")
print(f"Weighted mean : {weighted_mean:.4f}")

assert abs(manual_mean - weighted_mean) < 1e-10
print("[PASS] Manual and weighted estimates match.")
```

---

## 6. أطلقها (Ship It — Production Artifact)

### سكربت تقييم جودة المقدِّر

هذا السكربت الإنتاجي يُجري محاكاة مونت كارلو (*Monte Carlo Simulation*) لتقييم خصائص أي مقدِّر ويُنتج تقريراً موجزاً:

```r
# ============================================================
# PRODUCTION: estimator_quality_assessment.R
# Monte Carlo evaluation of estimator properties
# ============================================================

estimator_quality_report <- function(population_values,
                                     sample_size,
                                     n_simulations = 10000,
                                     estimator_fn = mean,
                                     seed = 2024) {
  set.seed(seed)

  N <- length(population_values)
  n <- sample_size
  theta <- estimator_fn(population_values)

  stopifnot(n < N, n > 0, N > 0)

  estimates <- numeric(n_simulations)
  for (b in 1:n_simulations) {
    idx <- sample(N, n, replace = FALSE)
    estimates[b] <- estimator_fn(population_values[idx])
  }

  # Compute quality metrics
  e_hat     <- mean(estimates)
  bias      <- e_hat - theta
  variance  <- var(estimates)
  mse       <- variance + bias^2
  rmse      <- sqrt(mse)
  cv        <- (sqrt(variance) / abs(e_hat)) * 100
  ci_lower  <- quantile(estimates, 0.025)
  ci_upper  <- quantile(estimates, 0.975)
  coverage  <- mean(estimates >= ci_lower & estimates <= ci_upper)

  # Report
  cat("============================================================\n")
  cat("  ESTIMATOR QUALITY ASSESSMENT REPORT\n")
  cat("============================================================\n")
  cat(sprintf("  Population size (N)    : %s\n", format(N, big.mark = ",")))
  cat(sprintf("  Sample size (n)        : %s\n", format(n, big.mark = ",")))
  cat(sprintf("  Sampling fraction      : %.4f%%\n", (n / N) * 100))
  cat(sprintf("  Simulations (B)        : %s\n", format(n_simulations, big.mark = ",")))
  cat("------------------------------------------------------------\n")
  cat(sprintf("  True parameter (theta) : %.6f\n", theta))
  cat(sprintf("  E(theta_hat)           : %.6f\n", e_hat))
  cat(sprintf("  Bias                   : %.6f\n", bias))
  cat(sprintf("  Variance               : %.6f\n", variance))
  cat(sprintf("  MSE                    : %.6f\n", mse))
  cat(sprintf("  RMSE                   : %.6f\n", rmse))
  cat(sprintf("  CV                     : %.2f%%\n", cv))
  cat(sprintf("  95%% Empirical CI       : [%.4f, %.4f]\n", ci_lower, ci_upper))
  cat("============================================================\n")

  invisible(list(
    theta = theta, e_hat = e_hat, bias = bias,
    variance = variance, mse = mse, cv = cv,
    estimates = estimates
  ))
}

# --- Example Usage ---
# pop <- rlnorm(50000, 7, 1)
# result <- estimator_quality_report(pop, sample_size = 500)
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | الرمز |
|-----------------|-------------------|-------|
| المجتمع المستهدف | Target Population | $N$ |
| المعلمة | Parameter | $\theta$ |
| المقدِّر | Estimator | $\hat{\theta}$ |
| عدم التحيز | Unbiasedness | $E(\hat{\theta}) = \theta$ |
| متوسط مربع الخطأ | Mean Squared Error | $MSE = Var + Bias^2$ |
| إطار المعاينة | Sampling Frame | — |
| تصحيح المجتمع المحدود | Finite Population Correction | $1 - n/N$ |

---

[العودة إلى الفهرس الرئيسي](../../README.md) | [الدرس التالي: المعاينة الاحتمالية مقابل غير الاحتمالية ←](lesson_0_2_probability_vs_nonprob.md)

</div>
