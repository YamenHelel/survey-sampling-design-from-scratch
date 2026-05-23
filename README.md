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
  <a href="#-الترخيص"><img src="https://img.shields.io/badge/الترخيص-MIT-red?style=for-the-badge" alt="MIT License"/></a>
</p>

---

## ما هذا المستودع؟

هذا المستودع هو **منهج هندسي متكامل** يأخذك من الصفر المطلق إلى بناء منظومة معاينة إحصائية كاملة (*Complete Survey Sampling Pipeline*) قادرة على إنتاج تقديرات وطنية موثوقة. لا نستخدم مكتبات جاهزة في البداية — بل نبني كل خوارزمية يدوياً بالحلقات والمصفوفات، ثم نقارن نتائجنا مع الحزم الإنتاجية المعتمدة.

### لماذا هذا المستودع مختلف؟

| السمة | التفصيل |
|-------|---------|
| **من الصفر أولاً** | كل خوارزمية تُبنى يدوياً قبل استخدام أي مكتبة جاهزة |
| **ثنائي اللغة البرمجية** | كل تمرين مكتوب بـ R و Python معاً للمقارنة |
| **التحقق الصارم** | نقاط تأكيد (`assert` / `stopifnot`) تضمن تطابق النتائج اليدوية مع المكتبات حتى 4 خانات عشرية |
| **سيناريوهات واقعية** | كل درس يبدأ بأزمة تشغيلية حقيقية من مكاتب الإحصاء الوطنية |
| **بيانات تركيبية واقعية** | إطار تعداد مُولَّد يحتوي 500,000 أسرة موزعة على محافظات ومناطق |
| **عربي بمصطلحات إنجليزية** | الشرح بالعربية مع المصطلح الإنجليزي الدقيق عند أول ذكر |

---

## هيكل المستودع

```text
├── README.md                              # هذا الملف
├── .gitignore
├── scripts/
│   ├── generate_census_frame.R            # توليد إطار تعداد تركيبي (500 ألف صف)
│   └── utils.R                            # دوال إحصائية مساعدة مشتركة
├── course/
│   ├── phase_0_fundamentals/              # المرحلة 0: الأسس والمبادئ
│   │   ├── lesson_0_1_intro_sampling.md
│   │   ├── lesson_0_2_probability_vs_nonprob.md
│   │   └── lesson_0_3_sampling_error_mechanics.md
│   ├── phase_1_infrastructure_frames/     # المرحلة 1: البنية التحتية والأطر
│   │   ├── lesson_1_1_frame_diagnostics.md
│   │   └── lesson_1_2_psu_partitioning.md
│   ├── phase_2_probability_designs/       # المرحلة 2: التصاميم الاحتمالية
│   │   ├── lesson_2_1_stratified_opt_allocation.md
│   │   ├── lesson_2_2_systematic_pps.md
│   │   └── lesson_2_3_multistage_engine.md
│   ├── phase_3_sample_size_calibration/   # المرحلة 3: حجم العينة وأثر التصميم
│   │   ├── lesson_3_1_cochran_extensions.md
│   │   └── lesson_3_2_deff_icc_mechanics.md
│   ├── phase_4_weighting_pipeline/        # المرحلة 4: الأوزان والمعايرة
│   │   ├── lesson_4_1_design_weights.md
│   │   ├── lesson_4_2_nonresponse_propensity.md
│   │   └── lesson_4_3_calibration_raking.md
│   └── phase_5_variance_estimation/       # المرحلة 5: تقدير التباين
│       ├── lesson_5_1_taylor_linearization.md
│       └── lesson_5_2_jackknife_replications.md
└── tests/
    ├── test_phase_2_sampling.R            # اختبارات وحدة: المعاينة
    └── test_phase_4_weights.R             # اختبارات وحدة: الأوزان
```

---

## المراحل التعليمية

### المرحلة 0: مبادئ وأسس المعاينة (*Sampling Fundamentals*)

> الأساس الرياضي والمفاهيمي الذي لا يمكن تجاوزه قبل كتابة أي سطر كود.

| الدرس | العنوان | المحور الأساسي |
|-------|---------|---------------|
| 0.1 | [مقدمة في مفاهيم معاينة المسوح](course/phase_0_fundamentals/lesson_0_1_intro_sampling.md) | المجتمع المستهدف، إطار المعاينة، المعلمة مقابل المقدِّر |
| 0.2 | [الخط الفاصل: المعاينة الاحتمالية مقابل غير الاحتمالية](course/phase_0_fundamentals/lesson_0_2_probability_vs_nonprob.md) | احتمالات الاشتمال المعلومة وغير الصفرية |
| 0.3 | [ميكانيكا خطأ المعاينة مقابل الأخطاء غير العينية](course/phase_0_fundamentals/lesson_0_3_sampling_error_mechanics.md) | تشريح مصادر الخطأ وسلوكها |

### المرحلة 1: البنية التحتية وتشخيص الأطر (*Survey Infrastructure & Frame Diagnostics*)

> تنظيف البيانات وتجهيز إطار المعاينة للعمل الميداني.

| الدرس | العنوان | المحور الأساسي |
|-------|---------|---------------|
| 1.1 | [تنظيف إطار المعاينة وتشخيص نقص التغطية](course/phase_1_infrastructure_frames/lesson_1_1_frame_diagnostics.md) | إزالة التكرارات، السجلات خارج النطاق، مؤشرات التغطية |
| 1.2 | [تقسيم وتوحيد وحدات المعاينة الأولية](course/phase_1_infrastructure_frames/lesson_1_2_psu_partitioning.md) | دمج/تقسيم مناطق العد وفق عتبات الحجم |

### المرحلة 2: التصاميم الاحتمالية من الصفر (*Probability Sampling Designs From Scratch*)

> بناء محركات السحب الاحتمالي بدون مكتبات متخصصة.

| الدرس | العنوان | المحور الأساسي |
|-------|---------|---------------|
| 2.1 | [المعاينة العشوائية الطبقية والتوزيع الأمثل](course/phase_2_probability_designs/lesson_2_1_stratified_opt_allocation.md) | التوزيع التناسبي مقابل توزيع نيمن |
| 2.2 | [السحب المنتظم بالاحتمال المتناسب مع الحجم](course/phase_2_probability_designs/lesson_2_2_systematic_pps.md) | طريقة الحجم التراكمي |
| 2.3 | [محرك المعاينة العنقودية متعددة المراحل](course/phase_2_probability_designs/lesson_2_3_multistage_engine.md) | PPS + معاينة منتظمة للأسر |

### المرحلة 3: حجم العينة وأثر التصميم (*Sample Size Calibration & Design Effect*)

> إيجاد حجم العينة الأمثل رياضياً.

| الدرس | العنوان | المحور الأساسي |
|-------|---------|---------------|
| 3.1 | [امتدادات معادلة كوكران للمسوح المركبة](course/phase_3_sample_size_calibration/lesson_3_1_cochran_extensions.md) | تصحيح المجتمع المحدود وعدم الاستجابة |
| 3.2 | [تفكيك أثر التصميم ومعامل الارتباط داخل العنقود](course/phase_3_sample_size_calibration/lesson_3_2_deff_icc_mechanics.md) | $Deff = 1 + (\bar{m}-1)\rho$ |

### المرحلة 4: منظومة الأوزان والمعايرة (*Weighting, Non-Response & Calibration Pipeline*)

> تحويل الأعداد العينية إلى تقديرات وطنية.

| الدرس | العنوان | المحور الأساسي |
|-------|---------|---------------|
| 4.1 | [أوزان التصميم (الأوزان القاعدية)](course/phase_4_weighting_pipeline/lesson_4_1_design_weights.md) | $W_{base} = 1/\pi_i$ |
| 4.2 | [تعديل عدم الاستجابة بنمذجة الميل](course/phase_4_weighting_pipeline/lesson_4_2_nonresponse_propensity.md) | الانحدار اللوجستي لدرجات الميل |
| 4.3 | [معايرة الأوزان (ما بعد الطبقية والتوازن التكراري)](course/phase_4_weighting_pipeline/lesson_4_3_calibration_raking.md) | خوارزمية IPF |

### المرحلة 5: تقدير التباين في المسوح المركبة (*Variance Estimation in Complex Surveys*)

> توليد أخطاء معيارية وفترات ثقة دقيقة.

| الدرس | العنوان | المحور الأساسي |
|-------|---------|---------------|
| 5.1 | [خطية تايلور من الصفر](course/phase_5_variance_estimation/lesson_5_1_taylor_linearization.md) | تباين مقدِّر النسبة |
| 5.2 | [محركات إعادة المعاينة: جاكنايف وبوتستراب](course/phase_5_variance_estimation/lesson_5_2_jackknife_replications.md) | Delete-One Jackknife |

---

## كيف تستخدم هذا المستودع؟

### المتطلبات الأساسية

**R** (الإصدار 4.0 أو أحدث):
```r
install.packages(c("survey", "sampling", "dplyr", "tidyr", "ggplot2"))
```

**Python** (الإصدار 3.8 أو أحدث):
```bash
pip install numpy pandas scipy scikit-learn samplics statsmodels
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
سيُنشئ ملف `census_frame.csv` يحتوي 500,000 صف يمثل أُسَراً موزعة على محافظات ومناطق.

3. **ابدأ من المرحلة 0** واتبع الترتيب التسلسلي للدروس.

4. **شغّل اختبارات التحقق:**
```bash
Rscript tests/test_phase_2_sampling.R
Rscript tests/test_phase_4_weights.R
```

---

## منهجية الدرس: التدفق السداسي

كل درس في هذا المستودع يتبع هيكلاً موحداً من 6 خطوات:

```
┌─────────────────────────────────────────────┐
│  1. الشعار (Motto)                          │
│     → قاعدة ذهبية مركّزة                    │
├─────────────────────────────────────────────┤
│  2. بيان المشكلة (Problem Statement)        │
│     → أزمة تشغيلية واقعية من مكتب إحصائي   │
├─────────────────────────────────────────────┤
│  3. الحدس الرياضي (Mathematical Intuition)  │
│     → المعادلات الحاكمة بصيغة LaTeX          │
├─────────────────────────────────────────────┤
│  4. ابنِها من الصفر (Build It From Scratch)  │
│     → كود R + Python بدون مكتبات متخصصة     │
├─────────────────────────────────────────────┤
│  5. استخدمها (Use It — Production)           │
│     → نفس المسألة بالحزم الإنتاجية المعتمدة │
├─────────────────────────────────────────────┤
│  6. أطلقها (Ship It — Production Artifact)   │
│     → سكربت إنتاجي جاهز للنشر               │
└─────────────────────────────────────────────┘
```

---

## لمن هذا المستودع؟

- **إحصائيو المسوح** في مكاتب الإحصاء الوطنية (*NSOs*) والمنظمات الدولية
- **طلاب الدراسات العليا** في الإحصاء التطبيقي ومنهجية المسوح
- **مهندسو البيانات** الذين يبنون خطوط أنابيب المعاينة (*Sampling Pipelines*)
- **الباحثون** في العلوم الاجتماعية والاقتصادية الذين يتعاملون مع بيانات مسحية مركبة
- **أي متعلم عربي** يريد فهم المعاينة الإحصائية بعمق هندسي لا سطحي

---

## المساهمة

نرحب بمساهماتكم! إذا وجدتم خطأً رياضياً، أو أردتم تحسين كود، أو إضافة سيناريو واقعي جديد:

1. افتحوا *Issue* يصف التحسين المقترح
2. أنشئوا *Fork* وعدّلوا في فرع مستقل
3. أرسلوا *Pull Request* مع شرح واضح للتعديلات

---

## الترخيص

هذا المستودع مرخص تحت رخصة **MIT** — استخدموه، عدّلوه، وزّعوه بحرية مع ذكر المصدر.

---

<p align="center">
  <strong>⭐ إذا استفدتم من هذا المستودع، لا تنسوا نجمة التقدير ⭐</strong>
</p>

</div>
