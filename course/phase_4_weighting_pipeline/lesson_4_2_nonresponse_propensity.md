<div dir="rtl" align="right">

# الدرس 4.2: تعديل عدم الاستجابة بنمذجة الميل

[→ الدرس السابق](lesson_4_1_design_weights.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_4_3_calibration_raking.md)

---

## 1. الشعار (Motto)

> **"عدم الاستجابة ليس عشوائياً — والأوزان يجب أن تعكس ذلك."**
>
> نمذجة الميل تُعيد توزيع أوزان الرافضين على المستجيبين المشابهين لهم.

---

## 2. بيان المشكلة (Problem Statement)

### الأزمة التشغيلية

مسح القوى العاملة حقق معدل استجابة 82%. لكن التحليل الأولي كشف أن عدم الاستجابة **ليس عشوائياً**:
- الأسر في المناطق الحضرية رفضت بنسبة 25% مقابل 10% في الريف
- الأسر ذات الدخل المرتفع أقل استجابة
- فئة الشباب (18-30) أقل تواجداً في المنزل

إذا تجاهلنا هذا النمط واستخدمنا أوزان التصميم فقط، ستكون تقديرات البطالة والدخل **متحيزة**.

---

## 3. الحدس الرياضي (Mathematical Intuition)

### 3.1 نموذج الميل للاستجابة

نمذجة احتمال الاستجابة باستخدام الانحدار اللوجستي (*Logistic Regression*):

$$P(R_i = 1 | X_i) = \frac{1}{1 + e^{-(\beta_0 + \beta_1 x_{i1} + ... + \beta_p x_{ip})}}$$

حيث $R_i = 1$ إذا استجابت الوحدة $i$، و $X_i$ هي المتغيرات المساعدة المتاحة لجميع الوحدات المختارة.

### 3.2 الوزن المعدّل

$$w_i^{adj} = \frac{w_i^{base}}{\hat{p}_i}$$

حيث $\hat{p}_i$ هو الميل المقدَّر للاستجابة (*Propensity Score*).

### 3.3 طريقة فئات الترجيح (Weighting Classes)

بديل أبسط: تقسيم العينة إلى فئات متجانسة وتعديل الأوزان داخل كل فئة:

$$w_i^{adj} = w_i^{base} \times \frac{\sum_{j \in class} w_j^{base}}{\sum_{j \in class, R_j=1} w_j^{base}}$$

---

## 4. ابنِها من الصفر (Build It From Scratch)

### Python — من الصفر (مع scikit-learn)

```python
# ============================================================
# Lesson 4.2: Non-Response Adjustment via Propensity Modeling
# Python — Using scikit-learn for logistic regression
# ============================================================

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression

np.random.seed(2024)

# --- Generate sample with non-response ---
n_sample = 3000
sample_df = pd.DataFrame({
    'hh_id': range(n_sample),
    'urban': np.random.binomial(1, 0.6, n_sample),
    'head_age': np.random.normal(42, 12, n_sample).clip(18, 80).astype(int),
    'hh_size': np.random.poisson(4, n_sample).clip(1, 15),
    'income': np.random.lognormal(7.0, 0.9, n_sample),
    'base_weight': 200.0  # Self-weighting design
})

# Non-response mechanism (NOT random)
from scipy.special import expit
log_income_scaled = (np.log(sample_df['income']) - 7.0) / 0.9
sample_df['true_resp_prob'] = expit(
    1.0                                    # Intercept
    - 0.8 * sample_df['urban']              # Urban less likely
    + 0.02 * (sample_df['head_age'] - 42)   # Older more likely
    - 0.3 * log_income_scaled               # Higher income less likely
    + 0.1 * sample_df['hh_size']            # Larger HH more likely
)
sample_df['responded'] = np.random.binomial(1, sample_df['true_resp_prob'])

resp_rate = sample_df['responded'].mean()
print(f"Response rate: {resp_rate:.1%}")
print(f"Respondents  : {sample_df['responded'].sum():,}")

# --- Show non-response bias ---
resp = sample_df[sample_df['responded'] == 1]
nonresp = sample_df[sample_df['responded'] == 0]

print(f"\n--- Non-Response Bias (before adjustment) ---")
for col in ['urban', 'head_age', 'income']:
    r_mean = resp[col].mean()
    nr_mean = nonresp[col].mean()
    print(f"  {col:<10}: resp={r_mean:.2f}, non-resp={nr_mean:.2f}, "
          f"diff={r_mean - nr_mean:.2f}")

# ============================================================
# METHOD 1: Propensity Score Adjustment
# ============================================================

print("\n" + "=" * 60)
print("  METHOD 1: PROPENSITY SCORE ADJUSTMENT")
print("=" * 60)

# Features available for ALL sampled units (respondents + non-respondents)
X = sample_df[['urban', 'head_age', 'hh_size']].values
y_resp = sample_df['responded'].values

# Fit logistic regression
model = LogisticRegression(max_iter=1000, random_state=42)
model.fit(X, y_resp)

# Predict propensity scores
propensity = model.predict_proba(X)[:, 1]
sample_df['propensity'] = propensity

# Adjust weights for respondents only
respondents = sample_df[sample_df['responded'] == 1].copy()
respondents['adj_weight'] = respondents['base_weight'] / respondents['propensity']

print(f"  Propensity range: [{propensity.min():.3f}, {propensity.max():.3f}]")
print(f"  Base weight sum (resp)   : {respondents['base_weight'].sum():,.0f}")
print(f"  Adj weight sum (resp)    : {respondents['adj_weight'].sum():,.0f}")
print(f"  Target N                 : {n_sample * 200:,}")

# --- Compare estimates ---
true_mean_income = sample_df['income'].mean()
naive_mean = respondents['income'].mean()
weighted_naive = np.average(respondents['income'], weights=respondents['base_weight'])
weighted_adj = np.average(respondents['income'], weights=respondents['adj_weight'])

print(f"\n  True mean income    : {true_mean_income:,.2f}")
print(f"  Naive (unweighted)  : {naive_mean:,.2f} (bias: {naive_mean - true_mean_income:+.2f})")
print(f"  Base weights only   : {weighted_naive:,.2f} (bias: {weighted_naive - true_mean_income:+.2f})")
print(f"  Propensity adjusted : {weighted_adj:,.2f} (bias: {weighted_adj - true_mean_income:+.2f})")

# ============================================================
# METHOD 2: Weighting Classes
# ============================================================

print("\n" + "=" * 60)
print("  METHOD 2: WEIGHTING CLASSES")
print("=" * 60)

# Create classes based on urban x age group
sample_df['age_group'] = pd.cut(sample_df['head_age'],
                                 bins=[0, 30, 45, 60, 100],
                                 labels=['18-30', '31-45', '46-60', '61+'])
sample_df['wt_class'] = sample_df['urban'].astype(str) + '_' + sample_df['age_group'].astype(str)

respondents2 = sample_df[sample_df['responded'] == 1].copy()

# Compute class-level adjustment factors
class_factors = {}
for cls in sample_df['wt_class'].unique():
    total_w = sample_df[sample_df['wt_class'] == cls]['base_weight'].sum()
    resp_w = respondents2[respondents2['wt_class'] == cls]['base_weight'].sum()
    if resp_w > 0:
        factor = total_w / resp_w
    else:
        factor = 1.0
    class_factors[cls] = factor

respondents2['class_factor'] = respondents2['wt_class'].map(class_factors)
respondents2['adj_weight_cls'] = respondents2['base_weight'] * respondents2['class_factor']

print(f"  Weighting classes: {len(class_factors)}")
print(f"  {'Class':<15} {'Factor':>8} {'Resp Rate':>10}")
print("  " + "-" * 38)
for cls, fac in sorted(class_factors.items()):
    cls_data = sample_df[sample_df['wt_class'] == cls]
    rr = cls_data['responded'].mean()
    print(f"  {cls:<15} {fac:>8.3f} {rr:>10.1%}")

weighted_cls = np.average(respondents2['income'], weights=respondents2['adj_weight_cls'])
print(f"\n  Weighting class estimate: {weighted_cls:,.2f} (bias: {weighted_cls - true_mean_income:+.2f})")

# --- Assertions ---
bias_naive = abs(naive_mean - true_mean_income)
bias_adj = abs(weighted_adj - true_mean_income)
bias_cls = abs(weighted_cls - true_mean_income)

assert bias_adj < bias_naive, "Propensity adjustment should reduce bias"
print(f"\n[PASS] Propensity adjustment reduced bias: {bias_naive:.1f} -> {bias_adj:.1f}")
```

### R — من الصفر

```r
# ============================================================
# Lesson 4.2: Non-Response Propensity Adjustment
# R — From Scratch (using glm for logistic regression)
# ============================================================

set.seed(2024)

n_sample <- 3000

sample_df <- data.frame(
  urban    = rbinom(n_sample, 1, 0.6),
  head_age = pmin(80, pmax(18, round(rnorm(n_sample, 42, 12)))),
  hh_size  = pmax(1, pmin(15, rpois(n_sample, 4))),
  income   = rlnorm(n_sample, 7.0, 0.9),
  base_weight = 200
)

# Non-response mechanism
log_inc_scaled <- (log(sample_df$income) - 7.0) / 0.9
resp_prob <- plogis(1.0 - 0.8 * sample_df$urban +
                     0.02 * (sample_df$head_age - 42) -
                     0.3 * log_inc_scaled +
                     0.1 * sample_df$hh_size)
sample_df$responded <- rbinom(n_sample, 1, resp_prob)

cat(sprintf("Response rate: %.1f%%\n", mean(sample_df$responded) * 100))

# --- Propensity model ---
model <- glm(responded ~ urban + head_age + hh_size,
             data = sample_df, family = binomial)

sample_df$propensity <- predict(model, type = "response")

# Adjust weights
resp <- sample_df[sample_df$responded == 1, ]
resp$adj_weight <- resp$base_weight / resp$propensity

# Compare
true_mean <- mean(sample_df$income)
naive <- mean(resp$income)
base_wt <- weighted.mean(resp$income, resp$base_weight)
adj_wt <- weighted.mean(resp$income, resp$adj_weight)

cat(sprintf("\nTrue mean    : %.2f\n", true_mean))
cat(sprintf("Naive        : %.2f (bias: %+.2f)\n", naive, naive - true_mean))
cat(sprintf("Base weights : %.2f (bias: %+.2f)\n", base_wt, base_wt - true_mean))
cat(sprintf("Propensity   : %.2f (bias: %+.2f)\n", adj_wt, adj_wt - true_mean))

stopifnot(abs(adj_wt - true_mean) < abs(naive - true_mean))
cat("\n[PASS] Propensity adjustment reduces bias.\n")
```

---

## 5. استخدمها (Use It — Production Frameworks)

### R — حزمة survey مع أوزان معدّلة

```r
library(survey)

# Use adjusted weights in survey design
design_adj <- svydesign(id = ~1, weights = ~adj_weight, data = resp)
est <- svymean(~income, design_adj)
cat(sprintf("svymean (adjusted): %.2f (SE: %.2f)\n", coef(est), SE(est)))
```

---

## 6. أطلقها (Ship It — Production Artifact)

```python
# ============================================================
# PRODUCTION: nr_adjuster.py
# ============================================================

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression


class NonResponseAdjuster:
    """Adjust survey weights for non-response using propensity scores."""

    def __init__(self, sample_df: pd.DataFrame,
                 response_col: str, weight_col: str,
                 features: list):
        self.df = sample_df.copy()
        self.response_col = response_col
        self.weight_col = weight_col
        self.features = features
        self.model = None

    def fit_propensity(self, trim_bounds=(0.1, 0.9)):
        X = self.df[self.features].values
        y = self.df[self.response_col].values

        self.model = LogisticRegression(max_iter=1000)
        self.model.fit(X, y)

        self.df['_propensity'] = self.model.predict_proba(X)[:, 1]
        self.df['_propensity'] = self.df['_propensity'].clip(*trim_bounds)

        resp_mask = self.df[self.response_col] == 1
        self.df.loc[resp_mask, '_adj_weight'] = (
            self.df.loc[resp_mask, self.weight_col] /
            self.df.loc[resp_mask, '_propensity']
        )
        return self

    def get_respondents(self) -> pd.DataFrame:
        return self.df[self.df[self.response_col] == 1].copy()

    def diagnostics(self) -> dict:
        resp = self.df[self.df[self.response_col] == 1]
        return {
            'response_rate': self.df[self.response_col].mean(),
            'base_weight_sum': resp[self.weight_col].sum(),
            'adj_weight_sum': resp['_adj_weight'].sum(),
            'weight_cv': resp['_adj_weight'].std() / resp['_adj_weight'].mean(),
            'propensity_range': (
                self.df['_propensity'].min(),
                self.df['_propensity'].max()
            )
        }
```

---

## المفاهيم الأساسية المستفادة

| المفهوم بالعربية | المصطلح الإنجليزي | النقطة الجوهرية |
|-----------------|-------------------|----------------|
| درجة الميل | Propensity Score | $P(R=1|X)$ احتمال الاستجابة |
| الوزن المعدّل | Adjusted Weight | $w^{adj} = w^{base} / \hat{p}$ |
| فئات الترجيح | Weighting Classes | تجميع وتعديل داخل فئات متجانسة |
| عدم الاستجابة غير العشوائي | MNAR/MAR | الآلية تحدد طريقة التعديل |

---

[→ الدرس السابق](lesson_4_1_design_weights.md) | [العودة إلى الفهرس](../../README.md) | [الدرس التالي ←](lesson_4_3_calibration_raking.md)

</div>
