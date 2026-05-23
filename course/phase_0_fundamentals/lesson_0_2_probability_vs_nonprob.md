<div dir="rtl" align="right">

# الدرس 0.2: الخط الفاصل — المعاينة الاحتمالية مقابل غير الاحتمالية

[→ الدرس السابق](lesson_0_1_intro_sampling.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_0_3_sampling_error_mechanics.md)

---

## 1. الشعار (Motto)

> **"إذا لم تستطع حساب احتمال اختيار كل وحدة، فأنت لا تُعاين — أنت تتخمّن."**
>
> الفرق بين المعاينة الاحتمالية وغير الاحتمالية ليس فرقاً أكاديمياً — إنه الخط الذي يفصل بين الاستدلال الإحصائي المشروع والحدس غير الموثوق.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

وزارة التخطيط تلقت تقريرين متناقضين عن معدل الفقر:

- **التقرير الأول** (مكتب الإحصاء): 23.7% — مبني على مسح عنقودي متعدد المراحل شمل 12,000 أسرة مختارة باحتمالات معروفة.
- **التقرير الثاني** (منظمة محلية): 41.2% — مبني على استبيان إلكتروني أجاب عنه 50,000 شخص طوعياً عبر وسائل التواصل.

التقرير الثاني لديه عينة أكبر بأربع مرات! فلماذا يعتمد صانع القرار على التقرير الأول ذي العينة الأصغر؟

**الجواب:** لأن حجم العينة وحده لا يضمن شيئاً بدون **آلية اختيار احتمالية**.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 التعريف الصارم: المعاينة الاحتمالية

المعاينة تكون **احتمالية** (*Probability Sampling*) إذا وفقط إذا تحقق شرطان:

**الشرط الأول:** لكل وحدة $i$ في المجتمع، يوجد **احتمال اشتمال** (*Inclusion Probability*) معروف ومحسوب مسبقاً:

$$\pi_i = P(\text{الوحدة } i \text{ مُختارة في العينة}) > 0$$

**الشرط الثاني:** يمكن حساب احتمالات الاشتمال المشتركة (*Joint Inclusion Probabilities*):

$$\pi_{ij} = P(\text{الوحدتان } i \text{ و } j \text{ مختارتان معاً})$$

### 3.2 لماذا $\pi_i > 0$ ضرورة مطلقة؟

لأن مقدِّر **هورفيتز-تومبسون** (*Horvitz-Thompson Estimator*) — الأساس الرياضي لكل التقديرات المسحية — يعتمد على القسمة على $\pi_i$:

$$\hat{Y}_{HT} = \sum_{i \in s} \frac{y_i}{\pi_i}$$

إذا كان $\pi_i = 0$ لأي وحدة، فهذه الوحدة **مستحيلة الاختيار**، وبالتالي لا يمكن تمثيلها في التقدير. إذا كان $\pi_i$ **مجهولاً**، فلا يمكن حساب الوزن $w_i = 1/\pi_i$، وينهار الاستدلال بالكامل.

### 3.3 طرق المعاينة غير الاحتمالية — ولماذا تفشل

| الطريقة | الآلية | لماذا تكسر الاستدلال |
|---------|--------|---------------------|
| معاينة الملاءمة (*Convenience*) | اختيار من هو متاح | $\pi_i$ مجهول ومتحيز نحو المتاحين |
| معاينة الحصص (*Quota*) | ملء حصص محددة | ضمن كل حصة، الاختيار غير عشوائي |
| معاينة كرة الثلج (*Snowball*) | المستجيبون يرشحون آخرين | $\pi_i$ يعتمد على الشبكة الاجتماعية |
| المعاينة الهادفة (*Purposive*) | اختيار بناء على حكم الباحث | ذاتية كاملة، لا آلية احتمالية |

### 3.4 التحيز بسبب الاختيار الذاتي (Self-Selection Bias)

في الاستبيانات الإلكترونية الطوعية، من يستجيب ليس عشوائياً. إذا كانت خاصية الاهتمام $Y$ مرتبطة بالميل للاستجابة $R$:

$$E(\hat{\bar{Y}}_{vol}) = \bar{Y}_{population} + \underbrace{\frac{Cov(Y_i, R_i)}{P(R_i = 1)}}_{Bias}$$

هذا التحيز **لا يتقلص بزيادة حجم العينة** — على عكس خطأ المعاينة الاحتمالية.

---

## 4. ابنِها من الصفر (Build It From Scratch)

### المهمة

محاكاة تُظهر أن المعاينة الاحتمالية تنتج تقديرات غير متحيزة بينما معاينة الملاءمة تنتج تحيزاً منهجياً — حتى مع عينات أكبر بكثير.

### R — من الصفر

```r
# ============================================================
# Lesson 0.2: Probability vs Non-Probability Sampling
# R — Simulation demonstrating bias in convenience sampling
# ============================================================

set.seed(2024)

# --- Create population with selection bias mechanism ---
N <- 100000

population <- data.frame(
  id           = 1:N,
  income       = rlnorm(N, meanlog = 7.0, sdlog = 1.0),
  has_internet = NA,
  stringsAsFactors = FALSE
)

# Internet access correlates with income (higher income = more likely online)
population$prob_online <- plogis(-3 + 0.5 * log(population$income))
population$has_internet <- rbinom(N, 1, population$prob_online)

# True population mean
theta <- mean(population$income)
cat(sprintf("True population mean income: %.2f\n", theta))
cat(sprintf("Internet access rate: %.1f%%\n",
            mean(population$has_internet) * 100))
cat(sprintf("Mean income (online only): %.2f\n",
            mean(population$income[population$has_internet == 1])))
cat(sprintf("Mean income (offline): %.2f\n",
            mean(population$income[population$has_internet == 0])))

# --- Simulation parameters ---
B <- 3000
n_prob <- 500      # Probability sample size
n_conv <- 5000     # Convenience sample size (10x larger!)

estimates_prob <- numeric(B)
estimates_conv <- numeric(B)

for (b in 1:B) {
  # --- Method 1: Simple Random Sampling (Probability) ---
  idx_srs <- sample(1:N, n_prob, replace = FALSE)
  estimates_prob[b] <- mean(population$income[idx_srs])

  # --- Method 2: Convenience / Online-only (Non-Probability) ---
  # Only people with internet can respond, and response is voluntary
  online_pop <- which(population$has_internet == 1)
  # Among online users, higher income = more likely to respond
  response_prob <- plogis(-2 + 0.3 * log(population$income[online_pop]))
  respondents <- online_pop[rbinom(length(online_pop), 1, response_prob) == 1]

  if (length(respondents) >= n_conv) {
    idx_conv <- sample(respondents, n_conv, replace = FALSE)
  } else {
    idx_conv <- respondents
  }
  estimates_conv[b] <- mean(population$income[idx_conv])
}

# --- Results ---
cat("\n============================================================\n")
cat("  COMPARISON: Probability vs Convenience Sampling\n")
cat("============================================================\n")

cat(sprintf("\n--- Probability Sampling (n = %d) ---\n", n_prob))
cat(sprintf("  E(theta_hat) : %.2f\n", mean(estimates_prob)))
cat(sprintf("  Bias         : %.2f\n", mean(estimates_prob) - theta))
cat(sprintf("  RMSE         : %.2f\n", sqrt(mean((estimates_prob - theta)^2))))

cat(sprintf("\n--- Convenience Sampling (n = %d) ---\n", n_conv))
cat(sprintf("  E(theta_hat) : %.2f\n", mean(estimates_conv)))
cat(sprintf("  Bias         : %.2f\n", mean(estimates_conv) - theta))
cat(sprintf("  RMSE         : %.2f\n", sqrt(mean((estimates_conv - theta)^2))))

# The key insight: convenience has LARGER error despite 10x sample
bias_prob <- abs(mean(estimates_prob) - theta)
bias_conv <- abs(mean(estimates_conv) - theta)

cat(sprintf("\n  Bias ratio (Conv/Prob): %.1fx\n", bias_conv / max(bias_prob, 0.01)))

# Assertions
stopifnot(bias_prob < 50)   # Probability sample should have negligible bias
stopifnot(bias_conv > 100)  # Convenience sample should show substantial bias
cat("\n[PASS] Probability sampling produces unbiased estimates.\n")
cat("[PASS] Convenience sampling shows persistent bias.\n")
```

### Python — من الصفر

```python
# ============================================================
# Lesson 0.2: Probability vs Non-Probability Sampling
# Python — Simulation demonstrating bias in convenience sampling
# ============================================================

import numpy as np
from scipy.special import expit  # Logistic function

np.random.seed(2024)

# --- Create population with selection bias mechanism ---
N = 100000

income = np.random.lognormal(mean=7.0, sigma=1.0, size=N)

# Internet access correlates with income
prob_online = expit(-3 + 0.5 * np.log(income))
has_internet = np.random.binomial(1, prob_online)

theta = np.mean(income)
print(f"True population mean income: {theta:.2f}")
print(f"Internet access rate: {np.mean(has_internet)*100:.1f}%")
print(f"Mean income (online only): {np.mean(income[has_internet == 1]):.2f}")
print(f"Mean income (offline): {np.mean(income[has_internet == 0]):.2f}")

# --- Simulation ---
B = 3000
n_prob = 500
n_conv = 5000

estimates_prob = np.zeros(B)
estimates_conv = np.zeros(B)

for b in range(B):
    # Method 1: SRS (Probability)
    idx_srs = np.random.choice(N, size=n_prob, replace=False)
    estimates_prob[b] = np.mean(income[idx_srs])

    # Method 2: Convenience (Online voluntary)
    online_idx = np.where(has_internet == 1)[0]
    response_prob = expit(-2 + 0.3 * np.log(income[online_idx]))
    responding = online_idx[np.random.binomial(1, response_prob).astype(bool)]

    if len(responding) >= n_conv:
        idx_conv = np.random.choice(responding, size=n_conv, replace=False)
    else:
        idx_conv = responding
    estimates_conv[b] = np.mean(income[idx_conv])

# --- Results ---
print("\n" + "=" * 60)
print("  COMPARISON: Probability vs Convenience Sampling")
print("=" * 60)

bias_prob = np.mean(estimates_prob) - theta
bias_conv = np.mean(estimates_conv) - theta

print(f"\n--- Probability Sampling (n = {n_prob}) ---")
print(f"  E(theta_hat) : {np.mean(estimates_prob):.2f}")
print(f"  Bias         : {bias_prob:.2f}")
print(f"  RMSE         : {np.sqrt(np.mean((estimates_prob - theta)**2)):.2f}")

print(f"\n--- Convenience Sampling (n = {n_conv}) ---")
print(f"  E(theta_hat) : {np.mean(estimates_conv):.2f}")
print(f"  Bias         : {bias_conv:.2f}")
print(f"  RMSE         : {np.sqrt(np.mean((estimates_conv - theta)**2)):.2f}")

print(f"\n  Bias ratio (Conv/Prob): {abs(bias_conv)/max(abs(bias_prob), 0.01):.1f}x")

# Assertions
assert abs(bias_prob) < 50, "Probability bias too large"
assert abs(bias_conv) > 100, "Convenience should show substantial bias"
print("\n[PASS] Probability sampling produces unbiased estimates.")
print("[PASS] Convenience sampling shows persistent bias.")
```

---

## 5. استخدمها (Use It — Production Frameworks)

هذا الدرس مفاهيمي بالدرجة الأولى. لا توجد حزمة إنتاجية "تصلح" المعاينة غير الاحتمالية — لأن المشكلة ليست في الحساب بل في **آلية الاختيار ذاتها**.

ومع ذلك، يمكن استخدام تقنيات **ما بعد التصحيح** (*Post-hoc Adjustments*) للتخفيف من التحيز في البيانات غير الاحتمالية — مثل المعايرة (*Calibration*) ونمذجة الميل (*Propensity Score Modeling*) — وهي مواضيع ستُغطى في المرحلة 4.

### ملخص مقارن

```
┌───────────────────────┬─────────────────────┬─────────────────────┐
│        المعيار        │  معاينة احتمالية    │ معاينة غير احتمالية │
├───────────────────────┼─────────────────────┼─────────────────────┤
│ π_i معروف؟           │       نعم ✓         │      لا ✗           │
│ π_i > 0 لكل وحدة؟   │       نعم ✓         │     غير مضمون       │
│ التحيز يتقلص مع n?  │       نعم ✓         │      لا ✗           │
│ حسابات التباين صحيحة?│       نعم ✓         │      لا ✗           │
│ مقبول في الإحصاء الرسمي│     نعم ✓         │      نادراً ✗       │
│ التكلفة              │     أعلى عادة       │     أقل عادة        │
└───────────────────────┴─────────────────────┴─────────────────────┘
```

---

## 6. أطلقها (Ship It — Production Artifact)

### أداة تشخيص نوع المعاينة

سكربت إنتاجي يُقيِّم ما إذا كان مسح معين يحقق شروط المعاينة الاحتمالية:

```r
# ============================================================
# PRODUCTION: sampling_design_audit.R
# Diagnostic tool to evaluate if a survey meets probability
# sampling requirements
# ============================================================

audit_sampling_design <- function(sample_data,
                                  frame_size,
                                  inclusion_prob_col = NULL,
                                  cluster_col = NULL,
                                  stratum_col = NULL) {

  cat("============================================================\n")
  cat("  SAMPLING DESIGN AUDIT REPORT\n")
  cat("============================================================\n\n")

  n <- nrow(sample_data)
  cat(sprintf("Sample size       : %s\n", format(n, big.mark = ",")))
  cat(sprintf("Frame size (N)    : %s\n", format(frame_size, big.mark = ",")))
  cat(sprintf("Sampling fraction : %.4f%%\n", (n / frame_size) * 100))

  issues <- character(0)
  warnings_list <- character(0)

  # Check 1: Inclusion probabilities exist
  cat("\n--- Check 1: Inclusion Probabilities ---\n")
  if (is.null(inclusion_prob_col) ||
      !inclusion_prob_col %in% names(sample_data)) {
    issues <- c(issues, "No inclusion probability column found")
    cat("  [FAIL] Inclusion probabilities not available\n")
  } else {
    pi_vals <- sample_data[[inclusion_prob_col]]

    # Check for missing values
    n_missing <- sum(is.na(pi_vals))
    if (n_missing > 0) {
      issues <- c(issues,
                  sprintf("%d missing inclusion probabilities", n_missing))
      cat(sprintf("  [FAIL] %d missing values in pi_i\n", n_missing))
    }

    # Check pi_i > 0
    n_zero <- sum(pi_vals <= 0, na.rm = TRUE)
    if (n_zero > 0) {
      issues <- c(issues, sprintf("%d zero/negative pi_i values", n_zero))
      cat(sprintf("  [FAIL] %d zero or negative pi_i\n", n_zero))
    }

    # Check pi_i <= 1
    n_over <- sum(pi_vals > 1, na.rm = TRUE)
    if (n_over > 0) {
      warnings_list <- c(warnings_list,
                         sprintf("%d pi_i values > 1", n_over))
      cat(sprintf("  [WARN] %d pi_i values exceed 1.0\n", n_over))
    }

    if (n_missing == 0 && n_zero == 0) {
      cat("  [PASS] All inclusion probabilities are known and positive\n")
      cat(sprintf("  Range: [%.6f, %.6f]\n", min(pi_vals, na.rm = TRUE),
                  max(pi_vals, na.rm = TRUE)))
    }
  }

  # Check 2: Weight variability
  cat("\n--- Check 2: Weight Distribution ---\n")
  if (!is.null(inclusion_prob_col) &&
      inclusion_prob_col %in% names(sample_data)) {
    weights <- 1 / sample_data[[inclusion_prob_col]]
    weights <- weights[!is.na(weights) & is.finite(weights)]
    cv_w <- sd(weights) / mean(weights) * 100

    cat(sprintf("  Weight range : [%.2f, %.2f]\n", min(weights), max(weights)))
    cat(sprintf("  Weight CV    : %.1f%%\n", cv_w))

    if (cv_w > 200) {
      warnings_list <- c(warnings_list, "Extreme weight variability (CV > 200%)")
      cat("  [WARN] High weight variability — consider trimming\n")
    } else {
      cat("  [PASS] Weight variability acceptable\n")
    }
  }

  # Final verdict
  cat("\n============================================================\n")
  if (length(issues) == 0) {
    cat("  VERDICT: PROBABILITY SAMPLING REQUIREMENTS MET\n")
  } else {
    cat("  VERDICT: DOES NOT MEET PROBABILITY SAMPLING REQUIREMENTS\n")
    cat("  Issues found:\n")
    for (issue in issues) cat(sprintf("    - %s\n", issue))
  }
  cat("============================================================\n")

  invisible(list(
    is_probability = length(issues) == 0,
    issues = issues,
    warnings = warnings_list
  ))
}
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | النقطة الجوهرية |
|-----------------|-------------------|----------------|
| احتمال الاشتمال | Inclusion Probability ($\pi_i$) | يجب أن يكون معروفاً و > 0 |
| مقدِّر هورفيتز-تومبسون | Horvitz-Thompson Estimator | يعتمد على $w_i = 1/\pi_i$ |
| تحيز الاختيار الذاتي | Self-Selection Bias | لا يتقلص بزيادة $n$ |
| المعاينة غير الاحتمالية | Non-Probability Sampling | احتمالات اشتمال مجهولة |
| الإحصاءات الرسمية | Official Statistics | تشترط معاينة احتمالية |

---

[→ الدرس السابق](lesson_0_1_intro_sampling.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_0_3_sampling_error_mechanics.md)

</div>
