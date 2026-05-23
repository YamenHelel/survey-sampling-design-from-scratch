# Learning Repository Quick Reference

A one-page cheat sheet for the structure and pedagogy of the AI Engineering from Scratch repository model.

---

## The 6-Beat Lesson Structure

Every lesson follows this pattern:

| Beat | Purpose | What to Include |
|------|---------|-----------------|
| **Motto** | The insight that sticks | One-line core idea |
| **Problem** | Why this matters | Concrete pain point, real scenario, "what you can't do without this" |
| **Concept** | Build mental models | Diagrams, intuition, "aha!" moments — NO CODE YET |
| **Build It** | Implement from scratch | Step-by-step, starting simple → complex, your own implementation |
| **Use It** | Learn the framework | Production library doing the same thing, compare your version to theirs |
| **Ship It** | Reusable artifact | Prompt, skill, agent, or MCP server that students keep and use |

---

## Folder Structure at a Glance

```
phases/
├── 00-foundational-phase/
│   ├── 01-lesson-name/
│   │   ├── code/
│   │   │   ├── main.py
│   │   │   ├── main.ts (optional)
│   │   │   └── main.rs (optional)
│   │   ├── docs/
│   │   │   ├── en.md (REQUIRED)
│   │   │   ├── es.md (optional translation)
│   │   │   └── fr.md (optional translation)
│   │   ├── outputs/
│   │   │   ├── prompt-name.md
│   │   │   ├── skill-name.md
│   │   │   └── agent-name.md
│   │   ├── notebook/
│   │   │   └── lesson.ipynb (optional)
│   │   └── quiz.json (optional)
│   └── README.md (phase overview)
├── 01-intermediate-phase/
└── 02-advanced-phase/

root/
├── README.md (curriculum homepage)
├── ROADMAP.md (detailed progress tracker)
├── LESSON_TEMPLATE.md (guidelines for new lessons)
├── CONTRIBUTING.md (how to contribute)
├── catalog.json (auto-generated index)
├── requirements.txt (all dependencies)
├── glossary/
│   ├── terms.md (term definitions)
│   └── myths.md (misconceptions)
├── projects/ (capstone projects)
├── outputs/ (compiled prompts/skills/agents)
└── scripts/ (build automation)
```

---

## Naming Conventions

| Item | Format | Example |
|------|--------|---------|
| Phase folder | `NN-kebab-case` | `05-transformers-deep-dive` |
| Lesson folder | `MM-kebab-case` | `07-attention-mechanism` |
| Python file | `snake_case.py` | `main.py`, `utils.py` |
| TypeScript file | `camelCase.ts` | `main.ts`, `utils.ts` |
| Rust file | `snake_case.rs` | `main.rs` |
| Output file | `type-slug.md` | `prompt-explain-backprop.md`, `skill-gradient-descent.md` |

---

## Lesson Frontmatter

### Code Lesson (Python)

```python
# main.py
# No module docstring; code is self-explanatory

def simple_function(x):
    return x * 2

class SimpleClass:
    def __init__(self, value):
        self.value = value
```

**Rules**:
- Minimal/no comments
- Self-explanatory naming
- Start simple, build complexity
- Must run without errors

### Outputs (Prompts/Skills)

```markdown
---
name: prompt-explain-backprop
description: Explain backpropagation step-by-step to a beginner
version: 1.0.0
phase: 3
lesson: 5
tags: [gradients, neural-networks, calculus]
---

# Prompt Content Here

You are a tutor explaining...
```

**Required YAML fields**:
- `name`: Unique slug
- `description`: One-line description
- `version`: Version number (for skills/agents)
- `phase`: Phase number
- `lesson`: Lesson number
- `tags`: Searchable keywords

---

## Lesson Markdown Template

```markdown
# [Lesson Title]

> **Motto**: One-line core idea that students remember.

**Type**: Build | Learn
**Languages**: Python, TypeScript
**Prerequisites**: [Prior lessons]
**Time**: ~30 minutes

---

## The Problem

[2-3 paragraphs. What's the concrete pain point? 
Why should someone care? Show a real scenario.]

---

## The Concept

[Intuition WITHOUT code. Use:
- ASCII diagrams
- Tables
- Plain English explanations
- Analogies]

---

## Build It

[Implement from scratch, step-by-step]

### Step 1: [Name]

[Explanation]

    code here

### Step 2: [Name]

    more code

---

## Use It

[Show the same using production libraries]

    library code here

---

## Ship It

[Explain the reusable artifact and why it's useful]

---

## Exercises

1. **Easy**: [Reinforce core concept]
2. **Medium**: [Apply to new problem]
3. **Hard**: [Extend or combine]

---

## Key Terms

| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Backprop | Magic neural network learning | Chain rule applied layer-by-layer |

---

## Further Reading

- [Resource](url) — [Why it matters]
```

---

## Key Terms Format (Glossary)

Always structure terms as: **"What people say" vs. "What it actually means"**

```markdown
| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Attention | Magic that makes transformers work | Learned weighted sum of values, computed from queries and keys |
| Gradient | Direction to update weights | Derivative showing slope of loss function |
| Epoch | One pass through data | One complete iteration through all training samples |
```

---

## ROADMAP Status Glyphs

Use these in ROADMAP.md:
- ✅ Complete
- 🚧 In progress
- ⬚ Not started

```markdown
### Phase 3: Deep Learning Core ✅ `25 lessons`

| # | Lesson | Type | Status |
|----|--------|------|--------|
| 1 | Intro to Neural Networks | Build | ✅ |
| 2 | Backpropagation | Build | ✅ |
| 3 | Optimization | Learn | 🚧 |
| 4 | Regularization | Build | ⬚ |
```

---

## Required Root Files

| File | Purpose | Update Frequency |
|------|---------|-------------------|
| `README.md` | Curriculum homepage, value prop | Manual + when adding phases |
| `ROADMAP.md` | Phase-by-phase lesson tracker | Manual, every new lesson |
| `LESSON_TEMPLATE.md` | Guidelines for new lessons | Rarely |
| `CONTRIBUTING.md` | How to contribute | When process changes |
| `catalog.json` | Machine-readable index | Auto-generated by script |
| `requirements.txt` | All Python dependencies | Manual |
| `glossary/terms.md` | Term definitions | Manual, when introducing new terms |

---

## Automation Scripts (in `scripts/`)

Essential scripts to build:

1. **generate-catalog.js** — Parse phases folder, output `catalog.json`
2. **validate-structure.js** — Check all lessons follow template
3. **build-site.js** — Generate website from curriculum data
4. **lint-markdown.js** — Ensure consistent formatting

---

## Curriculum Design: Phase Examples

### For "Sampling in Household Surveys"

```
Phase 0: Setup & Foundations (12 lessons)
  ├─ Environment setup
  ├─ Survey software intro
  └─ Ethical foundations

Phase 1: Statistical Foundations (15 lessons)
  ├─ Probability distributions
  ├─ Estimators
  └─ Hypothesis testing

Phase 2: Sampling Theory (18 lessons)
  ├─ Simple random sampling
  ├─ Stratified sampling
  ├─ Cluster sampling
  └─ Non-response adjustment

Phase 3: Survey Design (20 lessons)
  ├─ Questionnaire design
  ├─ Sampling frame construction
  └─ Quality control

Phase 4: Analysis & Inference (16 lessons)
  ├─ Survey-weighted estimation
  ├─ Domain estimation
  └─ Small area estimation

Phase 5: Capstone Projects (8 projects)
  ├─ Design a real survey
  ├─ Analyze existing data
  └─ Compare approaches
```

**Total**: 6 phases, ~90 lessons, ~250 hours

---

## Quality Checklist

Before merging any lesson:

- [ ] Folder structure matches template
- [ ] All required sections present (Motto, Problem, Concept, Build It, Use It, Ship It, Exercises, Key Terms, Further Reading)
- [ ] Code runs without errors
- [ ] Code is self-explanatory (minimal comments)
- [ ] At least one language implemented (Python preferred)
- [ ] Outputs have YAML frontmatter with all fields
- [ ] New glossary terms defined
- [ ] Prerequisites listed
- [ ] Further Reading links valid
- [ ] Follows 6-beat lesson structure
- [ ] Builds on prior lessons

---

## Why This Structure Works

✅ **Linear flow**: Students know where they are in the curriculum
✅ **Consistent pattern**: Same lesson structure everywhere → predictable learning
✅ **From-scratch first**: You understand the algorithm before the library
✅ **Multi-language**: Core concepts + language options
✅ **Reusable artifacts**: Skills/prompts students actually use
✅ **Easy to contribute**: Clear guidelines + templates
✅ **Automated pipeline**: Scripts keep everything in sync
✅ **Production-ready**: Lessons ship with runnable code

---

## One-Sentence Summary

A structured, phase-based curriculum where every lesson teaches a concept from scratch before showing the production way, produces reusable artifacts, and follows the same pedagogical pattern.
