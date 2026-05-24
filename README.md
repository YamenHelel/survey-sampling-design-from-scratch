<div dir="rtl" align="right">

<h1 align="center">
تصميم عينات المسوح الإحصائية
<br/>
<sub>Survey Sampling Engineering From Scratch</sub>
</h1>

<p align="center">
  <strong>مستودع تعليمي متكامل لبناء منظومات المعاينة الإحصائية من الصفر باستخدام R و Python</strong>
</p>

<p align="center">
  <a href="#-المراحل-التعليمية"><img src="https://img.shields.io/badge/المراحل-6_مراحل-blue?style=for-the-badge" alt="6 Phases"/></a>
  <a href="#-الدروس"><img src="https://img.shields.io/badge/الدروس-15_درساً-green?style=for-the-badge" alt="15 Lessons"/></a>
  <a href="#-اللغات"><img src="https://img.shields.io/badge/الأكواد-R_&_Python-orange?style=for-the-badge" alt="R & Python"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/الترخيص-MIT-red?style=for-the-badge" alt="MIT License"/></a>
</p>

---

## ما هذا المستودع؟

هذا المستودع هو **منهج هندسي متكامل** يأخذك من الصفر المطلق إلى بناء منظومة معاينة إحصائية كاملة (*Complete Survey Sampling Pipeline*) قادرة على إنتاج تقديرات وطنية موثوقة. لا نستخدم مكتبات جاهزة في البداية — بل نبني كل خوارزمية يدوياً بالحلقات والمصفوفات، ثم نقارن نتائجنا مع الحزم الإنتاجية المعتمدة.

### لماذا هذا المستودع مختلف؟

| السمة | التفصيل |
|-------|---------|
| **من الصفر أولاً** | كل خوارزمية تُبنى يدوياً قبل استخدام أي مكتبة جاهزة |
| **ثنائي اللغة البرمجية** | كل تمرين مكتوب بـ R و Python معاً للمقارنة |
| **التحقق الصارم** | نقاط تأكيد (`assert` / `stopifnot`) تضمن تطابق النتائج حتى 4 خانات عشرية |
| **هيكل سداسي موحد** | كل درس يتبع: Motto → Problem → Concept → Build It → Use It → Ship It |
| **مخرجات إنتاجية** | كل درس يُنتج مهارة أو أداة قابلة لإعادة الاستخدام |
| **بيانات تركيبية** | إطار تعداد 500,000 أسرة مع عيوب واقعية مُحقَنة |

---

## هيكل المستودع

```text
survey-sampling-ar/
├── README.md                     # هذا الملف
├── ROADMAP.md                    # خارطة الطريق بحالة كل درس
├── LESSON_TEMPLATE.md            # قالب إنشاء درس جديد
├── CONTRIBUTING.md               # دليل المساهمة
├── LICENSE                       # رخصة MIT
├── catalog.json                  # فهرس المنهج (آلي)
├── requirements.txt              # متطلبات Python
├── .gitignore
│
├── phases/                       # المراحل التعليمية
│   ├── 00-sampling-fundamentals/
│   │   ├── README.md             # نظرة عامة على المرحلة
│   │   ├── 01-intro-to-sampling/
│   │   │   ├── code/main.R       # تنفيذ R
│   │   │   ├── code/main.py      # تنفيذ Python
│   │   │   ├── docs/en.md        # النص التعليمي الكامل
│   │   │   └── outputs/          # مخرجات إنتاجية
│   │   ├── 02-probability-vs-nonprobability/
│   │   └── 03-sampling-error-mechanics/
│   ├── 01-infrastructure-frame-diagnostics/
│   ├── 02-probability-sampling-designs/
│   ├── 03-sample-size-calibration/
│   ├── 04-weighting-calibration-pipeline/
│   └── 05-variance-estimation/
│
├── glossary/
│   ├── terms.md                  # قاموس المصطلحات
│   └── myths.md                  # خرافات شائعة
│
├── scripts/
│   ├── generate_census_frame.R   # توليد إطار تعداد تركيبي
│   └── utils.R                   # دوال مساعدة مشتركة
│
├── tests/
│   ├── test_phase_2_sampling.R   # اختبارات المعاينة
│   └── test_phase_4_weights.R    # اختبارات الأوزان
│
├── projects/                     # مشاريع تخرج (قريباً)
├── outputs/                      # مخرجات مُجمَّعة
└── assets/                       # صور ورسومات
```

---

## المراحل التعليمية

```mermaid
graph LR
    P0[المرحلة 0<br/>الأسس والمبادئ] --> P1[المرحلة 1<br/>البنية التحتية]
    P1 --> P2[المرحلة 2<br/>التصاميم الاحتمالية]
    P2 --> P3[المرحلة 3<br/>حجم العينة]
    P2 --> P4[المرحلة 4<br/>الأوزان والمعايرة]
    P3 --> P4
    P4 --> P5[المرحلة 5<br/>تقدير التباين]
```

### المرحلة 0: مبادئ وأسس المعاينة `3 دروس`

| # | الدرس | المحور |
|---|-------|--------|
| 0.1 | [مقدمة في مفاهيم معاينة المسوح](phases/00-sampling-fundamentals/01-intro-to-sampling/docs/en.md) | المجتمع، المعلمة، المقدِّر، MSE |
| 0.2 | [المعاينة الاحتمالية مقابل غير الاحتمالية](phases/00-sampling-fundamentals/02-probability-vs-nonprobability/docs/en.md) | احتمالات الاشتمال، مقدِّر HT |
| 0.3 | [خطأ المعاينة مقابل الأخطاء غير العينية](phases/00-sampling-fundamentals/03-sampling-error-mechanics/docs/en.md) | TSE، تحيز عدم الاستجابة |

### المرحلة 1: البنية التحتية وتشخيص الأطر `2 درسان`

| # | الدرس | المحور |
|---|-------|--------|
| 1.1 | [تنظيف إطار المعاينة](phases/01-infrastructure-frame-diagnostics/01-frame-cleaning-undercoverage/docs/en.md) | إزالة التكرارات، مؤشرات التغطية |
| 1.2 | [تقسيم وتوحيد PSUs](phases/01-infrastructure-frame-diagnostics/02-psu-partitioning-harmonization/docs/en.md) | عتبات الحجم 80-150 أسرة |

### المرحلة 2: التصاميم الاحتمالية من الصفر `3 دروس`

| # | الدرس | المحور |
|---|-------|--------|
| 2.1 | [المعاينة الطبقية والتوزيع الأمثل](phases/02-probability-sampling-designs/01-stratified-optimal-allocation/docs/en.md) | التناسبي مقابل نيمن |
| 2.2 | [السحب المنتظم PPS](phases/02-probability-sampling-designs/02-systematic-pps-selection/docs/en.md) | طريقة الحجم التراكمي |
| 2.3 | [محرك المعاينة العنقودية](phases/02-probability-sampling-designs/03-multistage-cluster-engine/docs/en.md) | PPS + SRS |

### المرحلة 3: حجم العينة وأثر التصميم `2 درسان`

| # | الدرس | المحور |
|---|-------|--------|
| 3.1 | [امتدادات معادلة كوكران](phases/03-sample-size-calibration/01-cochran-formula-extensions/docs/en.md) | FPC، Deff، عدم الاستجابة |
| 3.2 | [أثر التصميم ومعامل ICC](phases/03-sample-size-calibration/02-deff-icc-mechanics/docs/en.md) | $Deff = 1 + (\bar{m}-1)\rho$ |

### المرحلة 4: منظومة الأوزان والمعايرة `3 دروس`

| # | الدرس | المحور |
|---|-------|--------|
| 4.1 | [أوزان التصميم القاعدية](phases/04-weighting-calibration-pipeline/01-design-weights-generation/docs/en.md) | $W_{base} = 1/\pi_i$ |
| 4.2 | [تعديل عدم الاستجابة](phases/04-weighting-calibration-pipeline/02-nonresponse-propensity-adjustment/docs/en.md) | نمذجة الميل |
| 4.3 | [معايرة الأوزان — IPF/Raking](phases/04-weighting-calibration-pipeline/03-calibration-raking-ipf/docs/en.md) | التوازن التكراري |

### المرحلة 5: تقدير التباين `2 درسان`

| # | الدرس | المحور |
|---|-------|--------|
| 5.1 | [خطية تايلور من الصفر](phases/05-variance-estimation/01-taylor-linearization/docs/en.md) | تباين مقدِّر النسبة |
| 5.2 | [جاكنايف وبوتستراب](phases/05-variance-estimation/02-jackknife-bootstrap-replication/docs/en.md) | إعادة المعاينة |

---

## منهجية الدرس: التدفق السداسي

كل درس في هذا المستودع يتبع هيكلاً موحداً:

```
MOTTO        → شعار مركّز يبقى في الذاكرة
    ↓
PROBLEM      → أزمة تشغيلية واقعية
    ↓
CONCEPT      → الحدس الرياضي (بدون كود)
    ↓
BUILD IT     → بناء الخوارزمية من الصفر (R + Python)
    ↓
USE IT       → نفس المسألة بالحزم الإنتاجية المعتمدة
    ↓
SHIP IT      → مخرج إنتاجي قابل لإعادة الاستخدام
```

---

## كيف تبدأ؟

### المتطلبات

**R** (4.0+):
```r
install.packages(c("survey", "sampling", "dplyr", "tidyr", "ggplot2"))
```

**Python** (3.8+):
```bash
pip install -r requirements.txt
```

### خطوات البدء

1. **استنسخ المستودع:**
```bash
git clone https://github.com/YOUR_USERNAME/survey-sampling-ar.git
cd survey-sampling-ar
```

2. **ولِّد إطار التعداد التركيبي:**
```bash
Rscript scripts/generate_census_frame.R
```

3. **ابدأ من المرحلة 0** — اتبع الترتيب التسلسلي.

4. **شغّل الاختبارات:**
```bash
Rscript tests/test_phase_2_sampling.R
Rscript tests/test_phase_4_weights.R
```

---

## لمن هذا المستودع؟

- **إحصائيو المسوح** في مكاتب الإحصاء الوطنية والمنظمات الدولية
- **طلاب الدراسات العليا** في الإحصاء التطبيقي ومنهجية المسوح
- **مهندسو البيانات** الذين يبنون خطوط أنابيب المعاينة
- **أي متعلم عربي** يريد فهم المعاينة الإحصائية بعمق هندسي

---

## المساهمة

اقرأ [دليل المساهمة](CONTRIBUTING.md) و [قالب الدرس](LESSON_TEMPLATE.md) قبل إرسال أي Pull Request.

---

## الترخيص

هذا المستودع مرخص تحت رخصة [MIT](LICENSE).

<p align="center">
  <strong>إذا استفدتم من هذا المستودع، لا تنسوا نجمة التقدير</strong>
</p>

</div>
