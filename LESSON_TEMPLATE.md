<div dir="rtl" align="right">

# قالب الدرس — Lesson Template

> هذا القالب هو المرجع الإلزامي لكتابة أي درس جديد في المستودع. كل درس يتبع نفس الهيكل السداسي.

---

## هيكل المجلد

```
phases/NN-phase-name/MM-lesson-name/
├── code/
│   ├── main.R          # التنفيذ بلغة R
│   └── main.py         # التنفيذ بلغة Python
├── docs/
│   └── en.md           # النص التعليمي الكامل (عربي مع مصطلحات إنجليزية)
├── outputs/
│   ├── prompt-*.md     # موجّه إنتاجي قابل لإعادة الاستخدام
│   └── skill-*.md      # مهارة إنتاجية قابلة لإعادة الاستخدام
└── quiz.json           # (اختياري) أسئلة تقييم
```

---

## قالب ملف `docs/en.md`

</div>

```markdown
# [Lesson Title — عنوان الدرس]

> **Motto**: One-line core idea that students remember.

**Type**: Build | Learn
**Languages**: R, Python
**Prerequisites**: [Prior lessons]
**Time**: ~30 minutes

---

## The Problem — بيان المشكلة

[2-3 paragraphs in Arabic. Real operational crisis scenario.
Why should someone care? Show a concrete scenario from NSOs.]

---

## The Concept — الحدس الرياضي

[Mathematical intuition WITHOUT code. Use:
- LaTeX equations ($$...$$)
- ASCII diagrams
- Tables
- Arabic prose with English technical terms in parentheses]

---

## Build It — ابنِها من الصفر

[Step-by-step implementation from scratch.
Reference code files: `../code/main.R` and `../code/main.py`]

### Step 1: [Name]
[Explanation + code reference]

### Step 2: [Name]
[Explanation + code reference]

---

## Use It — استخدمها

[Same task using production libraries (survey, sampling, samplics).
Compare outputs with assertions to 4 decimal places.]

---

## Ship It — أطلقها

[Describe the reusable artifact in `../outputs/`.
Link to the prompt/skill/agent file.]

---

## Exercises — تمارين

1. **Easy**: [Reinforce core concept]
2. **Medium**: [Apply to new problem]
3. **Hard**: [Extend or combine with prior lessons]

---

## Key Terms — المصطلحات الأساسية

| Term | What people say | What it actually means |
|------|----------------|----------------------|
| [Term] | [Common misconception] | [Precise definition] |

---

## Further Reading — مراجع إضافية

- [Resource](url) — [Why it matters]
```

<div dir="rtl" align="right">

---

## قواعد ملفات الكود

### `code/main.R` و `code/main.py`

- الكود بالإنجليزية بالكامل (أسماء المتغيرات، التعليقات)
- تعليقات شارحة مختصرة
- **يجب** أن يعمل بدون أخطاء
- **يجب** أن يتعامل مع القيم المفقودة (`NA` / `NaN`)
- **يجب** أن يتضمن نقاط تأكيد (`stopifnot()` / `assert`) تقارن النتائج اليدوية مع المكتبات الإنتاجية حتى 4 خانات عشرية
- ابدأ بسيطاً ← ابنِ التعقيد تدريجياً

### `outputs/*.md`

كل ملف مخرج يجب أن يحتوي على **YAML frontmatter**:

```yaml
---
name: prompt-descriptive-slug
description: One-line description
version: 1.0.0
phase: N
lesson: M
tags: [keyword1, keyword2, keyword3]
---
```

---

## قائمة التحقق قبل الدمج

- [ ] هيكل المجلد يطابق القالب
- [ ] جميع الأقسام الستة موجودة (Motto, Problem, Concept, Build It, Use It, Ship It)
- [ ] التمارين (Easy/Medium/Hard) موجودة
- [ ] جدول المصطلحات الأساسية موجود
- [ ] المراجع الإضافية موجودة
- [ ] الكود يعمل بدون أخطاء في R و Python
- [ ] نقاط التأكيد (`assert`/`stopifnot`) تمرر بنجاح
- [ ] المخرجات تحتوي على YAML frontmatter
- [ ] المتطلبات المسبقة محددة
- [ ] تم تحديث ROADMAP.md
- [ ] تم تحديث glossary/terms.md بالمصطلحات الجديدة

</div>
