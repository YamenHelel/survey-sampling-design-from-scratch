<div dir="rtl" align="right">

# الدرس 3.2: تفكيك أثر التصميم ومعامل الارتباط داخل العنقود

> **Motto**: "أثر التصميم يخبرك بالثمن الذي تدفعه مقابل راحة العنقدة — ومعامل الارتباط داخل العنقود يخبرك لماذا."

**Type**: Build
**Languages**: R, Python
**Prerequisites**: Lesson 3.1
**Time**: ~40 minutes

---

## The Problem — بيان المشكلة

### الأزمة التشغيلية

فريق التصميم في مكتب الإحصاء يقارن بين سيناريوهين لمسح القوى العاملة:
- **السيناريو أ:** 300 عنقود × 10 أسر = 3,000 أسرة (فرق ميدانية أكثر، عناقيد أصغر)
- **السيناريو ب:** 150 عنقود × 20 أسرة = 3,000 أسرة (فرق أقل، عناقيد أكبر)

نفس حجم العينة الكلي! لكن أيهما يعطي دقة أعلى؟ ذلك يعتمد على $\rho$ — معامل الارتباط داخل العنقود (*Intraclass Correlation Coefficient - ICC*).

---

## The Concept — الحدس الرياضي

### 3.1 أثر التصميم (Design Effect)

$$Deff = \frac{Var(\hat{\theta}_{complex})}{Var(\hat{\theta}_{SRS})}$$

تحت المعاينة العنقودية البسيطة ذات الحجم المتساوي:

$$Deff = 1 + (\bar{m} - 1)\rho$$

حيث:
- $\bar{m}$ = متوسط حجم العنقود
- $\rho$ = معامل الارتباط داخل العنقود (ICC)

### 3.2 حساب ICC عبر مكونات تباين ANOVA

من تحليل التباين أحادي الاتجاه (*One-Way ANOVA*):

$$\rho = \frac{MSB - MSW}{MSB + (\bar{m} - 1) \cdot MSW}$$

حيث:
- $MSB = \frac{SSB}{k - 1}$ — متوسط مربعات بين العناقيد (*Mean Square Between*)
- $MSW = \frac{SSW}{n - k}$ — متوسط مربعات داخل العناقيد (*Mean Square Within*)
- $k$ = عدد العناقيد، $n$ = إجمالي المشاهدات

### 3.3 مكونات التباين

$$\sigma^2_{total} = \sigma^2_{between} + \sigma^2_{within}$$

$$\sigma^2_{between} = \frac{MSB - MSW}{\bar{m}}$$

$$\sigma^2_{within} = MSW$$

$$\rho = \frac{\sigma^2_{between}}{\sigma^2_{between} + \sigma^2_{within}}$$

### 3.4 تأثير $\rho$ على Deff

| $\rho$ | $\bar{m} = 10$ | $\bar{m} = 20$ | $\bar{m} = 30$ |
|--------|----------------|----------------|----------------|
| 0.01   | 1.09           | 1.19           | 1.29           |
| 0.05   | 1.45           | 1.95           | 2.45           |
| 0.10   | 1.90           | 2.90           | 3.90           |
| 0.20   | 2.80           | 4.80           | 6.80           |

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

المخرج الإنتاجي متاح في: [`../outputs/skill-deff-icc-calculator.md`](../outputs/skill-deff-icc-calculator.md)

---

## Exercises — تمارين

1. **Easy**: احسب $Deff$ لتصميم عنقودي بمتوسط حجم عنقود $\bar{m} = 15$ ومعامل ارتباط $\rho = 0.05$. ما حجم العينة الفعّال؟

2. **Medium**: ولّد بيانات عنقودية بقيم مختلفة لـ $\rho$ (0.01, 0.05, 0.10, 0.20) واحسب $Deff$ لكل منها. ارسم العلاقة.

3. **Hard**: قارن بين حساب ICC باستخدام ANOVA وباستخدام نموذج مختلط (*Mixed Model*). هل يعطيان نفس النتيجة؟ متى يختلفان؟

---

## Key Terms — المصطلحات الأساسية


| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Design Effect (Deff) | "بكم يتضخم التباين" | $Deff = 1 + (\bar{m}-1)\rho$ — نسبة تباين التصميم الفعلي إلى SRS بنفس $n$ |
| ICC ($\rho$) | "التشابه داخل العنقود" | $\rho = \sigma^2_b / (\sigma^2_b + \sigma^2_w)$ — نسبة التباين بين العناقيد إلى الكلي |
| Effective Sample Size | "الحجم الفعّال" | $n_{eff} = n / Deff$ — الحجم المكافئ لتصميم SRS |
| ANOVA Decomposition | "تفكيك التباين" | فصل التباين الكلي إلى مكون بين العناقيد ($\sigma^2_b$) وداخلها ($\sigma^2_w$) |

---

## Further Reading — مراجع إضافية


- Kish, L. (1965). *Survey Sampling*, Ch. 8: Deff. Wiley. — الأصل
- Hox, J. (2010). *Multilevel Analysis*. Routledge. — ICC في سياق النماذج المتعددة المستويات
- Lohr, S.L. (2022). *Sampling: Design and Analysis*, Ch. 5. CRC Press. — شرح حديث وشامل

</div>
