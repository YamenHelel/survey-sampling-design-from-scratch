<div dir="rtl" align="right">

# الدرس 5.1: خطية تايلور من الصفر

> **Motto**: "مقدِّر النسبة ليس خطياً — لكن تقريب تايلور يُخطِّطه ويفتح الباب لحساب التباين."

**Type**: Build
**Languages**: R, Python
**Prerequisites**: Phase 4
**Time**: ~40 minutes

---

## The Problem — بيان المشكلة

### الأزمة التشغيلية

مكتب الإحصاء يحتاج لنشر معدل البطالة الوطني مع **خطئه المعياري** وفترة الثقة. المشكلة: معدل البطالة هو **مقدِّر نسبة** (*Ratio Estimator*):

$$\hat{R} = \frac{\sum w_i \cdot unemployed_i}{\sum w_i \cdot labor\_force_i}$$

البسط والمقام كلاهما عشوائيان — هذا يجعل حساب التباين أعقد من مقدِّر المجموع البسيط.

---

## The Concept — الحدس الرياضي

### 3.1 مقدِّر النسبة

$$\hat{R} = \frac{\hat{Y}}{\hat{X}} = \frac{\sum_{i \in s} w_i y_i}{\sum_{i \in s} w_i x_i}$$

### 3.2 تقريب تايلور (Delta Method)

نُقرِّب $\hat{R}$ بدالة خطية حول القيم الحقيقية:

$$\hat{R} - R \approx \frac{1}{\hat{X}} \sum_{i \in s} w_i (y_i - R \cdot x_i)$$

نُعرِّف المتبقيات الخطية (*Linearized Residuals*):

$$e_i = y_i - \hat{R} \cdot x_i$$

### 3.3 تباين مقدِّر النسبة

$$\widehat{Var}(\hat{R}) = \frac{1}{\hat{X}^2} \widehat{Var}\left(\sum_{i \in s} w_i e_i\right)$$

تحت تقريب العنقود النهائي (*Ultimate Cluster*) مع $H$ طبقات:

$$\widehat{Var}(\hat{R}) = \frac{1}{\hat{X}^2} \sum_{h=1}^{H} \frac{a_h}{a_h - 1} \sum_{i=1}^{a_h} (z_{hi} - \bar{z}_h)^2$$

حيث $z_{hi} = \sum_{j \in PSU_{hi}} w_{hij} e_{hij}$ هو إجمالي المتبقيات الموزونة في PSU.

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

المخرج الإنتاجي متاح في: [`../outputs/skill-taylor-variance-estimator.md`](../outputs/skill-taylor-variance-estimator.md)

---

## Exercises — تمارين

1. **Easy**: احسب تباين مقدِّر النسبة $\hat{R} = \hat{Y}/\hat{X}$ لمسح بطبقة واحدة و$n = 500$. قارن مع تباين المتوسط البسيط.

2. **Medium**: طبّق خطية تايلور على مقدِّر معدل الفقر (*Poverty Rate*) تحت تصميم عنقودي طبقي. كيف تؤثر الطبقات والعناقيد على الخطأ المعياري؟

3. **Hard**: احسب الخطأ المعياري لمعامل جيني (*Gini Coefficient*) باستخدام خطية تايلور. لماذا هذا أصعب من تباين النسبة؟ (تلميح: الدالة غير قابلة للاشتقاق ببساطة)

---

## Key Terms — المصطلحات الأساسية


| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Taylor Linearization | "تقريب خطي" | تقريب دالة غير خطية بمشتقاتها الأولى لتسهيل حساب التباين — أساس معظم برامج المسوح |
| Ratio Estimator | "مقدِّر النسبة" | $\hat{R} = \hat{Y}/\hat{X}$ — شائع جداً (معدل بطالة، نصيب فرد) لكن غير خطي |
| Linearized Variable | "المتغير المُخطَّط" | $z_i = (y_i - \hat{R} x_i) / \hat{X}$ — يُحوّل مشكلة النسبة إلى مشكلة متوسط بسيط |
| Ultimate Cluster | "العنقود النهائي" | في تقدير التباين، نحتاج فقط PSUs — لا نحتاج تفاصيل المراحل الداخلية |

---

## Further Reading — مراجع إضافية


- Wolter, K.M. (2007). *Introduction to Variance Estimation*, 2nd ed. Springer. — المرجع الشامل
- Särndal, C.E. et al. (1992). *Model Assisted Survey Sampling*, Ch. 5. Springer. — الإطار النظري
- Binder, D.A. (1983). On the Variances of Asymptotically Normal Estimators from Complex Surveys. *International Statistical Review*.

</div>
