# Learning Repository Structure Guide

## Overview

This document describes the structure, philosophy, and patterns of the AI Engineering from Scratch repository. Use this guide to create similar learning repositories for different subjects while maintaining the same pedagogical value, organization, and delivery patterns.

**Key Principle**: This is not a video course, blog series, or loose collection of tutorials. It's a **structured curriculum with a linear progression**, where each lesson builds on prior knowledge, produces reusable artifacts, and follows a consistent teaching methodology.

---

## Philosophy & Pedagogy

### Core Teaching Loop: "Build It, Use It, Ship It"

Every lesson follows this same six-beat structure:

1. **Motto**: A one-line core idea that sticks (the insight you take away)
2. **Problem**: Concrete pain point — why this matters and what you can't do without it
3. **Concept**: Intuition and mental models (diagrams, tables, explanations) before any code
4. **Build It**: Implement from scratch, step-by-step, starting simple and building complexity
5. **Use It**: Show the same thing using production frameworks/libraries to understand what they're doing
6. **Ship It**: Every lesson produces a reusable artifact: a prompt, a skill, an agent, or an MCP server

### Why This Works

- **Math-first, framework-second**: You understand the algorithm before the library hides it
- **Consistent structure**: Learners know what to expect at every step
- **Hands-on**: No passive watching — you code every concept from scratch
- **Production-ready**: Skills/prompts/agents are immediately usable
- **Language-agnostic**: Core concepts taught in multiple languages (Python, TypeScript, Rust, Julia)

---

## Repository Structure

### Root Level Files

```
.
├── README.md                    # Homepage: curriculum overview, value prop, table of contents
├── LESSON_TEMPLATE.md           # Template for new lessons (structure, format, guidelines)
├── CONTRIBUTING.md              # How to add lessons, translations, fixes
├── CHANGELOG.md                 # Version history and updates
├── CODE_OF_CONDUCT.md           # Community guidelines
├── FORKING.md                   # Instructions for forking and adapting
├── ROADMAP.md                   # Detailed lesson-by-lesson roadmap (used in build pipeline)
├── LICENSE                      # MIT license
├── catalog.json                 # Machine-readable index of all phases/lessons/outputs
├── requirements.txt             # Python dependencies for all lessons
├── glossary/                    # Glossary of terms used throughout curriculum
├── phases/                      # The main curriculum (20 phases × ~20-40 lessons each)
├── projects/                    # Capstone projects that combine multiple lessons
├── outputs/                     # Exported prompts, skills, agents, MCP servers
├── scripts/                     # Build and automation scripts
├── site/                        # Website generation and deployment
├── assets/                      # Banners, images, diagrams
└── web/                         # Optional: interactive web components
```

### Key Root-Level Files Explained

#### **README.md**
- Opens with a banner image and badges (lesson count, phase count, GitHub stars, link to website)
- Explains the problem: "84% of students use AI tools, but only 18% feel prepared"
- The value prop: Linear curriculum, math-to-production, four languages, 435 lessons, ~320 hours
- Shows the mermaid diagram of phase dependencies (how phases stack)
- Table of contents linking each phase
- Instructions for getting started
- Call-to-action (website, community, contributions)

**For your new repo**: Adapt the headline to your subject, but keep the same structure. The mermaid dependency diagram should show how your units/phases depend on each other.

#### **LESSON_TEMPLATE.md**
- Complete template for lesson structure and documentation format
- Shows folder layout for each lesson (code/, docs/, outputs/, etc.)
- Specifies exact markdown format for `docs/en.md` including sections: Motto, Type, Prerequisites, Problem, Concept, Build It, Use It, Ship It, Exercises, Key Terms, Further Reading
- Code file guidelines: must run without errors, self-explanatory (minimal comments), language-appropriate
- Output file format for prompts and skills (YAML frontmatter + content)

**For your new repo**: Keep this template exactly as-is or adapt it minimally. The consistency is part of the value.

#### **CONTRIBUTING.md**
- Clear guidelines for adding lessons, translations, and fixes
- **IMPORTANT**: Notes that README and ROADMAP feed the website build pipeline
- Specifies parsing patterns that must be preserved (phase headers, lesson tables, status glyphs)
- Step-by-step instructions for contributing a new lesson
- Rules for translations
- Mentions that one PR per contribution keeps review fast

**For your new repo**: Replace the build pipeline mentions if your setup differs, but keep the rest.

#### **ROADMAP.md**
- Detailed, phase-by-phase breakdown of all lessons
- Uses markdown with status glyphs:
  - ✅ Complete
  - 🚧 In progress
  - ⬚ Not started
- Each phase has a header (`### Phase N: Name \`X lessons\``) and a table of lessons
- Lesson table columns: `| # | Lesson | Type | Language |`
- **Critical**: This file is parsed by `site/build.js` to generate the website

**For your new repo**: Follow the exact format shown in the AI Engineering repo. The parsing relies on specific markdown patterns.

#### **catalog.json**
- Machine-readable index of the entire curriculum
- Structure:
  ```json
  {
    "schema_version": 1,
    "totals": { "phases": 20, "lessons": 435, ... },
    "phases": [
      {
        "num": 0,
        "slug": "00-setup-and-tooling",
        "title": "Setup and Tooling",
        "lesson_count": 12,
        "lessons": [
          {
            "num": 1,
            "slug": "01-dev-environment",
            "title": "Dev Environment",
            "path": "phases/00-setup-and-tooling/01-dev-environment",
            "has_docs": true,
            "has_code": true,
            "has_quiz": true,
            "has_notebook": false,
            "code_files": ["verify.py"],
            "outputs": [...]
          }
        ]
      }
    ]
  }
  ```
- Generated automatically by build scripts

**For your new repo**: Use the same format. Build a script to generate this from your phases folder.

#### **requirements.txt**
- Consolidated list of all Python dependencies across all lessons
- Learners run `pip install -r requirements.txt` once to get everything
- Includes: numpy, torch, transformers, jupyter, pandas, openai, anthropic, etc.

**For your new repo**: List dependencies once here rather than scattered per lesson, unless lessons are truly isolated.

---

### Glossary (`glossary/` folder)

Contains term definitions with a specific format:

**glossary/terms.md**:
```markdown
| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Backpropagation | The way neural nets learn | The chain rule applied to compute gradients through layers |
| Attention | Magic that makes transformers work | Learned weighted sum of values computed from queries and keys |
```

**glossary/myths.md** (optional):
- Common misconceptions and their corrections
- Helps prevent students from internalizing half-truths

**For your new repo**: Keep this format. It's scannable and directly opposite to how people usually think about terms.

---

### Phases (`phases/` folder)

The heart of the curriculum. 20 phases in the original; adapt to your subject.

#### Naming Convention
```
phases/
├── NN-phase-slug/
│   ├── MM-lesson-slug/
│   │   ├── code/
│   │   ├── docs/
│   │   ├── outputs/
│   │   └── quiz.json
│   └── README.md (phase overview)
```

**Phase naming**:
- `NN` is a two-digit number (00, 01, 02, ...)
- `-phase-slug` is kebab-case (e.g., `setup-and-tooling`, `math-foundations`, `deep-learning-core`)
- Same pattern for lessons: `MM-lesson-slug`

**Example from AI Engineering from Scratch**:
- `00-setup-and-tooling` → 12 lessons
- `01-math-foundations` → ~25 lessons
- `02-ml-fundamentals` → ~22 lessons
- ... and so on through Phase 19 (Capstone Projects)

**For your new repo**: Define 5-15 phases depending on subject scope. Each phase should be a coherent unit (either foundational layer, application domain, or tool/framework).

#### Phase Folder Contents

Each phase folder contains:

1. **Multiple lesson folders** (01-lesson-name, 02-lesson-name, etc.)
2. **README.md** (phase overview, learning objectives, prerequisites)

Example phase README:
```markdown
# Phase N: Phase Name

## Overview
[2-3 paragraphs explaining what you'll learn in this phase]

## Prerequisites
- Phase N-1: Previous Phase Name
- Phase N-2: Another Prior Phase (if applicable)

## Structure
This phase has MM lessons organized into N learning arcs:

1. [Arc 1 Name]: Lessons 1-5
2. [Arc 2 Name]: Lessons 6-10
...

## Learning Objectives
By the end of this phase, you'll understand:
- [ ] Objective 1
- [ ] Objective 2
- [ ] Objective 3
```

---

### Lesson Folders (`phases/NN-phase/MM-lesson/`)

Every lesson has this standard structure:

```
MM-lesson-name/
├── code/
│   ├── main.py            (primary implementation in Python)
│   ├── main.ts            (TypeScript version, if applicable)
│   ├── main.rs            (Rust version, if applicable)
│   ├── main.jl            (Julia version, if applicable)
│   └── requirements.txt    (if lesson has unique dependencies)
├── notebook/
│   └── lesson.ipynb       (optional: Jupyter notebook for experimentation)
├── docs/
│   └── en.md              (lesson documentation in English)
│   └── [other-lang].md    (translations: es.md, fr.md, zh.md, etc.)
├── outputs/
│   ├── prompt-*.md        (prompts this lesson produces, with YAML frontmatter)
│   ├── skill-*.md         (skills this lesson produces)
│   └── agent-*.md         (agents, if applicable)
└── quiz.json              (optional: validation quiz in JSON format)
```

#### **code/** folder

**Requirements**:
- At least one implementation per lesson
- Code must run without errors
- Self-explanatory (minimal comments — the code is the documentation)
- Start simple, build complexity
- Every function/class has a clear purpose

**Multi-language strategy**:
- Primary implementation in the most natural language for the topic (Python for ML, TypeScript for web tools, Rust for systems)
- Ports to other languages if the lesson is foundational (e.g., Phase 1 Math → all four languages; Phase 17 Infrastructure → mostly Python/Go)
- Not every lesson needs all four languages; prioritize clarity over completeness

**For your new repo**: Decide which 1-3 languages your subject requires. Adapt the code folder accordingly.

#### **docs/en.md** (The Lesson Narrative)

Every lesson has a `docs/en.md` file with exactly this structure:

```markdown
# Lesson Title

> **Motto**: One-line core idea that sticks.

**Type**: Build | Learn
**Languages**: Python, TypeScript, Rust, Julia (list what's included)
**Prerequisites**: [List prior lessons or skills needed]
**Time**: ~30 minutes

---

## The Problem

[2-3 paragraphs. What can't you do without this? Why should you care?
Make it concrete — show a scenario or use case.]

---

## The Concept

[Explain the intuition and mental model. Use:
- ASCII diagrams
- Tables comparing approaches
- Plain English explanations
- Links to visual resources
Do NOT include code yet.]

---

## Build It

[Step-by-step implementation from scratch.
Use subsections for each step.
Every code block should be runnable on its own or with minor imports.]

### Step 1: [Name]

[Explanation of what this step does and why]

```python
# code here
```

### Step 2: [Name]

[Continue...]

---

## Use It

[Show the same thing using frameworks/libraries.
Compare your from-scratch version to the library version.
This proves the concept and introduces production tools.]

```python
# library example here
```

---

## Ship It

[What reusable artifact does this lesson produce?
Explain the prompt/skill/agent and why it's useful.
Include the artifact file name (e.g., outputs/prompt-*.md or outputs/skill-*.md).]

---

## Exercises

1. **Easy**: [Reinforce the core concept with a simple task]
2. **Medium**: [Apply it to a different problem or dataset]
3. **Hard**: [Extend it or combine with prior lessons]

---

## Key Terms

| Term | What people say | What it actually means |
|------|----------------|----------------------|
| [Term 1] | [Common misconception] | [Actual definition] |
| [Term 2] | [Common misconception] | [Actual definition] |

---

## Further Reading

- [Resource 1](url) — [Why it's worth reading]
- [Resource 2](url) — [Why it's worth reading]
```

**Important notes**:
- Every section header (The Problem, The Concept, etc.) is consistent across all lessons
- Motto is a YAML-like field but not YAML; it's in markdown blockquote format
- The three-dash separator `---` visually breaks sections
- Key Terms table uses the specific format: "What people say" (misconception) vs. "What it actually means" (truth)

#### **docs/[lang].md** (Translations)

For each language translation (es.md, fr.md, zh.md), use the exact same structure as en.md but in that language.

---

### Outputs (`phases/NN-phase/MM-lesson/outputs/`)

Each lesson can produce reusable artifacts:

#### **Prompts** (`prompt-*.md`)

```markdown
---
name: prompt-env-check
description: Diagnose and fix AI engineering environment setup issues
phase: 0
lesson: 1
tags: [environment, setup, debugging]
---

# Prompt Content

[The actual prompt text that users can copy and paste into an LLM]
```

#### **Skills** (`skill-*.md`)

```markdown
---
name: skill-backpropagation
description: Understand and explain backpropagation as a chain rule application
version: 1.0.0
phase: 3
lesson: 5
tags: [calculus, neural-networks, gradients]
---

# Skill Content

[Detailed explanation of the skill, use cases, and how to apply it]
```

#### **Agents** (`agent-*.md`)

```markdown
---
name: agent-deployment-helper
description: Guide users through ML model deployment patterns
phase: 17
lesson: 3
tags: [deployment, production, MLOps]
---

# Agent Content

[Agent instructions, behavior, and integration details]
```

---

### Projects (`projects/` folder)

Capstone projects that combine lessons from multiple phases. Typically found in Phase 19.

Structure (similar to lessons but more complex):

```
projects/
├── 01-project-name/
│   ├── README.md                (project description, learning outcomes, requirements)
│   ├── starter-code/            (optional: boilerplate or data files)
│   ├── solution/
│   │   ├── main.py
│   │   ├── main.ts
│   │   └── main.rs
│   └── docs/
│       ├── en.md                (full project walkthrough)
│       └── rubric.md            (grading criteria, if applicable)
```

---

## Build Pipeline & Automation

### `site/build.js`

This Node.js script:
1. Parses `README.md`, `ROADMAP.md`, and `glossary/terms.md`
2. Extracts:
   - Phase headers (must match pattern: `### Phase N: Name \`X lessons\``)
   - Lesson tables (must have columns: `| # | Lesson | Type | Lang |`)
   - Status glyphs (✅, 🚧, ⬚)
   - Glossary terms
3. Generates `site/data.js` for website rendering
4. **Critical**: Structural patterns must stay intact, or the build breaks

**For your new repo**: Build a similar script adapted to your folder structure. The key is automating the generation of machine-readable data from human-readable markdown.

### `scripts/` folder

Typically contains:
- `generate-catalog.js` or `generate-catalog.py` — creates or updates `catalog.json`
- `validate-structure.js` or `.py` — checks that all lessons follow the required structure
- `build-site.js` or `.py` — runs the full build pipeline
- Other automation as needed

**For your new repo**: Include validation scripts to catch structural errors early.

---

## Website (`site/` and `web/` folders)

### `site/`

- `build.js` — Main build script (see above)
- `data.js` — Generated index of all curriculum data (do not edit manually)
- `index.html`, `style.css`, etc. — Static site files
- Often deployed via Vercel (see `vercel.json`)

### `web/` (optional)

- Interactive components, visualizations, or tools
- Can be React/Vue/Svelte apps or plain HTML/CSS/JS
- Linked from the main site

---

## Asset Files

### `assets/` folder

- `banner.svg` — Hero image used in README and website
- Phase diagrams (mermaid or PNG)
- Icons or logos
- Any images referenced in lessons

### `vercel.json` (for Vercel deployment)

Configuration for auto-deploying the site whenever the repo is updated.

---

## Key Patterns & Conventions

### Naming Conventions

1. **Phases**: `NN-kebab-case-name` (e.g., `00-setup-and-tooling`, `14-agent-engineering`)
2. **Lessons**: `MM-kebab-case-name` (e.g., `01-dev-environment`, `05-backpropagation`)
3. **Files**: `lowercase_with_underscores.py`, `camelCase.ts`, `snake_case.rs`
4. **Outputs**: `type-descriptive-name.md` (e.g., `prompt-env-check.md`, `skill-gradient-descent.md`)

### Code Style

- **No comments**: Code is self-explanatory through clear naming and structure
- **Language-idiomatic**: Use Python idioms in `.py`, TypeScript conventions in `.ts`, etc.
- **Tested**: All code must run without errors
- **Minimal dependencies**: Import only what's needed

### Documentation Style

- **Consistent headers**: Every lesson uses the same section names
- **Misconception-focused**: Key Terms table contrasts what people think vs. reality
- **Action-oriented**: Exercises have easy → medium → hard progression
- **Concrete examples**: Problems and Build It sections use real scenarios

### YAML Frontmatter in Outputs

Every prompt/skill/agent has YAML frontmatter with these fields:
```yaml
---
name: unique-slug
description: One-line description
version: 1.0.0        # for skills
phase: N              # phase number
lesson: M             # lesson number
tags: [tag1, tag2]    # searchable tags
---
```

---

## How to Adapt This for a New Subject

### Step 1: Define Your Curriculum Arc

1. **Identify your phases** (5-15 total):
   - What are the foundational concepts that everything else depends on?
   - What are the application domains or major topics?
   - What are the production/integration layers?

   Example for "Sampling in Household Surveys":
   - Phase 0: Setup & Foundational Concepts
   - Phase 1: Statistical Foundations
   - Phase 2: Sampling Theory
   - Phase 3: Household Survey Design
   - Phase 4: Data Collection & Management
   - Phase 5: Analysis & Inference
   - Phase 6: Practical Applications & Case Studies

2. **For each phase, list 10-30 lessons** covering concepts, build-it exercises, and tools.

### Step 2: Create Your Folder Structure

```
your-learning-repo/
├── README.md
├── LESSON_TEMPLATE.md
├── CONTRIBUTING.md
├── ROADMAP.md
├── LICENSE
├── catalog.json (auto-generated)
├── requirements.txt
├── glossary/
│   ├── terms.md
│   └── myths.md
├── phases/
│   ├── 00-phase-name/
│   ├── 01-phase-name/
│   └── ...
├── projects/
├── outputs/
├── scripts/
└── assets/
```

### Step 3: Build Your Lessons

For each lesson, follow the template:

1. Create the folder: `phases/NN-phase/MM-lesson/`
2. Create `docs/en.md` with all required sections
3. Create `code/main.py` (and other languages if applicable)
4. Create `quiz.json` for validation (optional)
5. Create outputs in `outputs/` (prompts, skills, agents)

### Step 4: Build Your Pipeline

1. Create `scripts/generate-catalog.js` to auto-generate `catalog.json`
2. Create `scripts/validate-structure.js` to check lesson compliance
3. Create `scripts/build-site.js` to generate website data
4. Update `README.md` and `ROADMAP.md` as you add lessons

### Step 5: Document Contributing

1. Update `CONTRIBUTING.md` with subject-specific guidance
2. Update `LESSON_TEMPLATE.md` if your subject requires different structure
3. Add community guidelines in `CODE_OF_CONDUCT.md`

### Step 6: Set Up Website (Optional but Recommended)

1. Build a simple site from `catalog.json` and `ROADMAP.md`
2. Display: phases, lessons, code examples, outputs
3. Deploy via Vercel, Netlify, or GitHub Pages

---

## Quality Checklist for Each Lesson

Before merging a lesson, verify:

- [ ] Folder structure matches template
- [ ] `docs/en.md` has all required sections (Motto, Problem, Concept, Build It, Use It, Ship It, Exercises, Key Terms, Further Reading)
- [ ] Code runs without errors
- [ ] Code is self-explanatory (minimal comments)
- [ ] At least one implementation (Python recommended as primary)
- [ ] `quiz.json` is present (if applicable) and valid
- [ ] Outputs (prompts/skills) have YAML frontmatter with required fields
- [ ] Glossary updated with any new terms introduced
- [ ] Prerequisites listed in docs
- [ ] Further Reading links are valid
- [ ] Lesson follows the "Build It, Use It, Ship It" pattern

---

## File that Ties It All Together: `catalog.json`

This JSON file is the index. It should be auto-generated by a build script and include:

```json
{
  "schema_version": 1,
  "metadata": {
    "title": "Your Learning Repository Title",
    "description": "Description of your curriculum",
    "total_hours": 250,
    "languages": ["Python", "TypeScript"],
    "created_at": "2024-01-01T00:00:00Z",
    "last_updated": "2024-06-15T12:30:00Z"
  },
  "totals": {
    "phases": 7,
    "lessons": 120,
    "skills": 95,
    "prompts": 25,
    "projects": 3,
    "code_files": 120
  },
  "phases": [
    {
      "num": 0,
      "slug": "00-phase-name",
      "title": "Phase Name",
      "description": "What this phase covers",
      "lesson_count": 15,
      "estimated_hours": 30,
      "lessons": [...]
    }
  ]
}
```

---

## Summary: What Makes This Curriculum Model Work

1. **Linear progression**: Phases build on each other; you can't skip (or you do at your peril)
2. **Consistent structure**: Every lesson follows the same pattern → learners know what to expect
3. **Build-first pedagogy**: You implement from scratch before using frameworks
4. **Multi-language support**: Core concepts in multiple languages; learners choose their favorite
5. **Reusable outputs**: Every lesson produces prompts, skills, or agents that students keep
6. **Automated pipeline**: Scripts keep catalog.json and website in sync
7. **Community-friendly**: Contributing guidelines make it easy to add lessons
8. **Production-ready**: This isn't theoretical—every lesson ships with runnable code and real artifacts

Adapt these patterns to your subject, and you'll have a curriculum with the same depth and rigor.
