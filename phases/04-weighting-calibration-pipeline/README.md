<div dir="rtl" align="right">

# المرحلة 4: منظومة الأوزان والمعايرة — Weighting & Calibration Pipeline

> تحويل الأعداد العينية إلى تقديرات وطنية.

---

## الهدف

بناء خط أنابيب الترجيح الكامل: من الأوزان القاعدية ($1/\pi_i$) إلى تعديل عدم الاستجابة بنمذجة الميل إلى المعايرة النهائية بخوارزمية IPF لمطابقة الإسقاطات السكانية المعروفة.

## الدروس

| # | الدرس | الوقت | المحور |
|---|-------|-------|--------|
| 01 | [أوزان التصميم القاعدية](01-design-weights-generation/docs/en.md) | ~35 دقيقة | $W_{base} = 1/\pi_i$ |
| 02 | [تعديل عدم الاستجابة بنمذجة الميل](02-nonresponse-propensity-adjustment/docs/en.md) | ~40 دقيقة | Logistic Regression |
| 03 | [معايرة الأوزان — IPF/Raking](03-calibration-raking-ipf/docs/en.md) | ~45 دقيقة | خوارزمية التوازن التكراري |

## المتطلبات المسبقة

المرحلة 2 + المرحلة 3

## المخرجات

- `skill-base-weight-generator` — حساب الأوزان القاعدية
- `skill-nonresponse-adjuster` — تعديل أوزان عدم الاستجابة
- `skill-raking-calibrator` — معايرة IPF

</div>
