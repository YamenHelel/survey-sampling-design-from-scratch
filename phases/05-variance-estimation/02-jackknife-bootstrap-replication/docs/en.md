<div dir="rtl" align="right">

# الدرس 5.2: محركات إعادة المعاينة — جاكنايف وبوتستراب

> **Motto**: "عندما لا تستطيع اشتقاق صيغة رياضية للتباين — اترك البيانات تحسبه بنفسها."

**Type**: Build
**Languages**: R, Python
**Prerequisites**: Lesson 5.1
**Time**: ~40 minutes

---

## The Problem — بيان المشكلة

### الأزمة التشغيلية

مكتب الإحصاء يحتاج لنشر **معامل جيني** (*Gini Coefficient*) و **الوسيط** (*Median*) للدخل مع أخطائها المعيارية. المشكلة:
- معامل جيني دالة **غير قابلة للاشتقاق** بالطريقة التقليدية (لا يمكن تطبيق تايلور مباشرة)
- الوسيط دالة **غير ملساء** (*Non-Smooth Function*)

الحل: استخدام طرق **إعادة المعاينة** (*Resampling Methods*) التي لا تحتاج لصيغة رياضية صريحة.

---

## The Concept — الحدس الرياضي

### 3.1 جاكنايف الحذف الواحد (Delete-One Jackknife)

لمسح عنقودي بـ $a$ وحدة PSU:
1. كرِّر $a$ مرة: في كل مرة $k$، احذف PSU رقم $k$ وأعِد حساب المقدِّر $\hat{\theta}_{(k)}$
2. تباين جاكنايف:

$$\widehat{Var}_{JK}(\hat{\theta}) = \frac{a - 1}{a} \sum_{k=1}^{a} (\hat{\theta}_{(k)} - \bar{\hat{\theta}})^2$$

حيث $\bar{\hat{\theta}} = \frac{1}{a} \sum_{k=1}^{a} \hat{\theta}_{(k)}$

### 3.2 جاكنايف مع طبقات (Stratified Jackknife)

لكل طبقة $h$ بها $a_h$ وحدات PSU:

$$\widehat{Var}_{JK} = \sum_{h=1}^{H} \frac{a_h - 1}{a_h} \sum_{k=1}^{a_h} (\hat{\theta}_{(hk)} - \bar{\hat{\theta}}_h)^2$$

### 3.3 بوتستراب المسوح (Survey Bootstrap)

1. داخل كل طبقة: أعِد معاينة $a_h - 1$ وحدة PSU مع الإرجاع من $a_h$ وحدة
2. عدِّل الأوزان: $w_i^{(r)} = w_i \times \frac{a_h}{a_h - 1} \times m_i^{(r)}$
   حيث $m_i^{(r)}$ = عدد مرات ظهور PSU $i$ في العينة المعادة $r$
3. كرِّر $B$ مرة (عادة 200-500)
4. التباين = تباين التقديرات عبر التكرارات

---

## Build It — ابنِها من الصفر

الكود الكامل في:
- **R**: [`../code/main.R`](../code/main.R)
- **Python**: [`../code/main.py`](../code/main.py)

نقاط التأكيد (`stopifnot` / `assert`) تضمن تطابق النتائج اليدوية مع المكتبات الإنتاجية حتى 4 خانات عشرية.

---

## Use It — استخدمها

الجزء الإنتاجي في ملفات الكود يُظهر نفس العمليات باستخدام الحزم المعتمدة (`survey`, `sampling` في R؛ `samplics`, `scipy` في Python) مع مقارنة مباشرة بالنتائج اليدوية.

---

## Ship It — أطلقها

المخرج الإنتاجي متاح في: [`../outputs/skill-jackknife-replication-engine.md`](../outputs/skill-jackknife-replication-engine.md)

---

## Exercises — تمارين

1. **Easy**: طبّق Delete-One Jackknife على مقدِّر المتوسط البسيط مع 20 PSU. قارن مع الخطأ المعياري النظري.

2. **Medium**: طبّق Bootstrap (500 تكرار) على مقدِّر النسبة وقارن مع نتائج خطية تايلور من الدرس السابق. هل يتطابقان؟

3. **Hard**: احسب تباين الوسيط (*Median*) باستخدام Jackknife و Bootstrap. لماذا لا يمكن استخدام خطية تايلور هنا؟ قارن النتائج.

---

## Key Terms — المصطلحات الأساسية


| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Jackknife | "احذف واحد وأعد الحساب" | Delete-one-PSU: إسقاط PSU واحد في كل تكرار وإعادة حساب المقدِّر — التباين من توزيع المقدِّرات الجزئية |
| Bootstrap | "إعادة المعاينة" | سحب عينات جديدة بالإرجاع من PSUs الأصلية — مرن جداً لكن أبطأ حسابياً |
| Replication Weights | "أوزان مكررة" | مجموعة أوزان (واحدة لكل تكرار) تُمكّن من حساب التباين بدون الصيغة المباشرة |
| Non-Smooth Statistic | "إحصاء غير أملس" | الوسيط، معامل جيني — لا يمكن اشتقاقه بسهولة، لذا نحتاج إعادة المعاينة بدلاً من تايلور |

---

## Further Reading — مراجع إضافية


- Wolter, K.M. (2007). *Introduction to Variance Estimation*, Ch. 4-5. Springer. — Jackknife و Bootstrap
- Shao, J. & Tu, D. (1995). *The Jackknife and Bootstrap*. Springer. — الأسس النظرية
- Rao, J.N.K. & Wu, C.F.J. (1988). Resampling Inference with Complex Survey Data. *JASA*.

</div>
