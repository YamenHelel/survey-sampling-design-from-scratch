# Visual Architecture Guide

A visual reference for how all the pieces of a learning repository fit together.

---

## The Learning Repository Ecosystem

```
┌─────────────────────────────────────────────────────────────────┐
│  LEARNING REPOSITORY FOR ANY SUBJECT                           │
│  (AI Engineering | Sampling Surveys | Quantum Computing | ...) │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 📚 PHASES (5-15 total)                                          │
│ ├─ Phase 0: Foundations                                         │
│ ├─ Phase 1: Intermediate                                        │
│ ├─ Phase N: Capstone/Applications                               │
│ └─ Each phase: 10-30 lessons                                    │
└─────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 📖 LESSONS (90-200 total)                                       │
│ Each lesson follows the 6-beat structure:                       │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │  1. MOTTO        │  One-line core idea                     │ │
│ │  2. PROBLEM      │  Why does this matter?                  │ │
│ │  3. CONCEPT      │  Intuition (diagrams, no code)          │ │
│ │  4. BUILD IT     │  Implement from scratch                 │ │
│ │  5. USE IT       │  Production framework version           │ │
│ │  6. SHIP IT      │  Reusable prompt/skill/agent            │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ Produced by each lesson:                                        │
│ ├─ code/main.py (runnable implementation)                       │
│ ├─ docs/en.md (lesson narrative)                                │
│ ├─ outputs/prompt-*.md (reusable prompts)                       │
│ ├─ outputs/skill-*.md (reusable skills)                         │
│ └─ quiz.json (validation quiz)                                  │
└─────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 🎯 OUTPUTS (Artifacts students keep)                            │
│                                                                  │
│ ├─ Prompts: "Explain concept X" → Reusable AI prompts          │
│ ├─ Skills: "How to do Y" → Transferable knowledge              │
│ ├─ Agents: "Build Z" → Autonomous task runners                 │
│ └─ Code: All implementations → Reference implementations        │
└─────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 📊 PIPELINE & AUTOMATION                                        │
│                                                                  │
│ scripts/                                                         │
│ ├─ generate-catalog.js  → outputs catalog.json                  │
│ ├─ validate-structure.js → checks template compliance           │
│ ├─ build-site.js        → generates website from data           │
│ └─ lint-markdown.js     → ensures consistent formatting         │
└─────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 🌐 WEBSITE & DEPLOYMENT                                         │
│                                                                  │
│ ├─ site/               → Website code                           │
│ ├─ site/data.js        → Generated curriculum index             │
│ ├─ vercel.json         → Auto-deploy on updates                 │
│ └─ Hosted at:          → your-domain.com                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Folder Tree Architecture

```
your-learning-repo/
│
├── 📄 ROOT DOCUMENTATION
│   ├─ README.md              → Homepage: "Why take this curriculum?"
│   ├─ ROADMAP.md             → Lesson-by-lesson progress tracker
│   ├─ CONTRIBUTING.md        → "How to add a new lesson"
│   ├─ LESSON_TEMPLATE.md     → "Use this structure for new lessons"
│   ├─ CODE_OF_CONDUCT.md     → Community guidelines
│   ├─ FORKING.md             → "How to fork & adapt this"
│   ├─ LICENSE                → MIT license
│   └─ CHANGELOG.md           → Version history
│
├── 📑 REFERENCE & CONFIG
│   ├─ catalog.json           → Machine index (auto-generated)
│   ├─ requirements.txt       → Python dependencies
│   └─ vercel.json            → Deployment config
│
├── 📚 GLOSSARY
│   └─ glossary/
│       ├─ terms.md           → Term definitions with misconceptions
│       ├─ myths.md           → Common misunderstandings
│       └─ README.md          → "How to read the glossary"
│
├── 🎓 MAIN CURRICULUM
│   └─ phases/
│       ├─ 00-setup-and-foundations/
│       │   ├─ 01-lesson-one/
│       │   │   ├─ code/
│       │   │   │   ├─ main.py              → Implementation
│       │   │   │   ├─ main.ts             → TypeScript version
│       │   │   │   └─ requirements.txt    → Dependencies (if unique)
│       │   │   ├─ docs/
│       │   │   │   ├─ en.md               → English lesson narrative
│       │   │   │   ├─ es.md               → Spanish translation
│       │   │   │   └─ fr.md               → French translation
│       │   │   ├─ notebook/
│       │   │   │   └─ lesson.ipynb        → Jupyter for experimentation
│       │   │   ├─ outputs/
│       │   │   │   ├─ prompt-name.md      → Reusable prompt
│       │   │   │   ├─ skill-name.md       → Reusable skill
│       │   │   │   └─ agent-name.md       → Reusable agent
│       │   │   └─ quiz.json               → Validation quiz
│       │   │
│       │   ├─ 02-lesson-two/
│       │   │   └─ [same structure as above]
│       │   │
│       │   └─ README.md                   → Phase overview
│       │
│       ├─ 01-intermediate-concepts/
│       │   └─ [lessons...]
│       │
│       └─ NN-capstone-projects/
│           └─ [projects...]
│
├── 🚀 CAPSTONE PROJECTS
│   └─ projects/
│       ├─ 01-project-one/
│       │   ├─ README.md                   → Project description
│       │   ├─ starter-code/               → Boilerplate & data
│       │   ├─ solution/
│       │   │   ├─ main.py
│       │   │   ├─ main.ts
│       │   │   └─ main.rs
│       │   └─ docs/
│       │       ├─ en.md                   → Walkthrough
│       │       └─ rubric.md               → Grading criteria
│       │
│       └─ 02-project-two/
│           └─ [similar structure]
│
├── 📦 OUTPUTS ARCHIVE
│   └─ outputs/
│       ├─ prompts/                        → Compiled prompts (auto-generated)
│       ├─ skills/                         → Compiled skills (auto-generated)
│       └─ agents/                         → Compiled agents (auto-generated)
│
├── 🛠️ BUILD & AUTOMATION
│   ├─ scripts/
│   │   ├─ generate-catalog.js             → Parse phases/, output catalog.json
│   │   ├─ validate-structure.js           → Check template compliance
│   │   ├─ build-site.js                   → Generate website data
│   │   └─ lint-markdown.js                → Format validation
│   │
│   ├─ site/                               → Website code
│   │   ├─ build.js                        → Main build script
│   │   ├─ data.js                         → Generated curriculum index
│   │   ├─ index.html                      → Homepage
│   │   ├─ style.css                       → Styling
│   │   └─ deploy.yml                      → CI/CD config
│   │
│   └─ web/ (optional)                     → Interactive components
│       ├─ components/
│       └─ visualizations/
│
├── 🎨 ASSETS
│   └─ assets/
│       ├─ banner.svg                      → Hero image for README
│       ├─ phase-diagram.png               → Dependency diagram
│       ├─ icons/                          → Icons used in site
│       └─ diagrams/                       → ASCII/visual diagrams
│
└── .git/                                   → Git repo metadata
```

---

## Data Flow: From Markdown to Website

```
MARKDOWN FILES                    PARSING SCRIPTS              GENERATED DATA
────────────────                  ───────────────              ──────────────

README.md
  ├─ Curriculum structure           ┐
  └─ Phase headers              ──→ │
                                    │  scripts/build.js
ROADMAP.md                          │  (parses markdown,
  ├─ Phase sections                 │   extracts structure,
  ├─ Lesson tables              ──→ │   validates format)
  └─ Status glyphs                  │
                                    ↓
glossary/terms.md                ──→ site/data.js
                                    │ (Machine-readable
                                    │  curriculum index)
catalog.json                        ↑
(if auto-generated)             ──→┘

                                   WEBSITE GENERATION
                                   ──────────────────
                                          ↓
                                   site/index.html
                                   site/style.css
                                   site/components/
                                          ↓
                                   🌐 DEPLOYED WEBSITE
                                      (Vercel, Netlify, etc.)
```

---

## The 6-Beat Lesson Flow (Detailed)

```
LESSON DOCUMENTATION: docs/en.md
═════════════════════════════════

┌─────────────────────────────────┐
│  📌 MOTTO                        │  "The core idea in one sentence"
│  One-liner that sticks           │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│  ❓ THE PROBLEM                  │  "Why does this matter?"
│  • Concrete pain point           │  • Real scenario
│  • Why you should care           │  • What you can't do without it
│  • Motivation                    │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│  💡 THE CONCEPT                  │  "Understand before coding"
│  • Intuition                     │  • ASCII diagrams
│  • Mental models                 │  • Tables
│  • Examples                      │  • Plain English
│  ❌ NO CODE YET                  │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│  🔨 BUILD IT                     │  "Implement from scratch"
│  • Step 1: Simple version        │  • Step 2: Add complexity
│  • Step 3: Full solution         │  • YOUR implementation
│  (in code/main.py)               │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│  🏭 USE IT                       │  "Production library version"
│  • Real framework                │  • Compare to Build It
│  • Same thing, production way    │  • Understand what it's hiding
│  (in docs/en.md section)         │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│  📦 SHIP IT                      │  "Reusable artifact"
│  • Prompt (outputs/prompt-*.md)  │  • Skill (outputs/skill-*.md)
│  • Agent (outputs/agent-*.md)    │  • Students keep this forever
│  • Code (code/main.py)           │
└─────────────────────────────────┘
```

---

## Phase Dependencies (Example: AI Engineering from Scratch)

```
                    Phase 0
                 Setup & Tooling
                        │
                        ↓
                   Phase 1
                Math Foundations
                        │
                        ↓
                   Phase 2
                ML Fundamentals
                        │
         ┌──────────────┼──────────────┐
         ↓              ↓              ↓
     Phase 3        Phase 4        Phase 5
  Deep Learning    Computer       NLP
     Core          Vision      Foundations
         │              │              │
         └──────────────┼──────────────┘
                        ↓
                   Phase 7
                 Transformers
                        │
         ┌──────────────┼──────────────┐
         ↓              ↓              ↓
     Phase 8        Phase 10       Phase 12
   GenAI          LLMs from      Multimodal
                   Scratch
         │              │              │
         └──────────────┼──────────────┘
                        ↓
                  Phase 11
              LLM Engineering
                        │
                        ↓
                  Phase 14
              Agent Engineering
                        │
         ┌──────────────┼──────────────┐
         ↓              ↓              ↓
     Phase 15       Phase 17       Phase 18
  Autonomous      Infrastructure   Ethics &
    Systems      & Production      Alignment
         │              │              │
         └──────────────┼──────────────┘
                        ↓
                  Phase 19
              Capstone Projects
```

**For your subject**: Map out similar dependencies.

---

## Artifact Lifecycle

```
LESSON CREATED
├─ code/main.py          → Runnable code students learn from
├─ docs/en.md            → Learning narrative
└─ outputs/
    ├─ prompt-*.md       → Reusable AI prompts
    ├─ skill-*.md        → Transferable knowledge
    └─ agent-*.md        → Autonomous helpers

        ↓

ARTIFACT COMPILATION (scripts/generate-catalog.js)
├─ Outputs/ folder → Organized by type
└─ catalog.json    → Machine-readable index

        ↓

WEBSITE DISPLAY
├─ Curriculum view    → Browse all phases & lessons
├─ Lesson detail page → Full narrative + code
├─ Artifact library   → Search prompts/skills/agents
└─ Progress tracker   → "You've completed 23 lessons"

        ↓

STUDENT USAGE
├─ Copies prompt → Uses in ChatGPT, Claude, local LLM
├─ Applies skill → Transfers knowledge to new problem
├─ Runs agent   → Automation in their own projects
└─ References code → Builds similar implementation
```

---

## Quality Gate: Lesson Checklist

```
┌─────────────────────────────────────────────────┐
│ BEFORE MERGING A NEW LESSON                     │
└─────────────────────────────────────────────────┘

STRUCTURE
  ✓ Folder: phases/NN-phase/MM-lesson/
  ✓ Has code/, docs/, outputs/ folders
  ✓ docs/en.md file exists

CONTENT
  ✓ Motto (one-liner)
  ✓ Problem section (concrete pain)
  ✓ Concept section (intuition)
  ✓ Build It section (step-by-step)
  ✓ Use It section (framework version)
  ✓ Ship It section (artifact)
  ✓ Exercises (easy → medium → hard)
  ✓ Key Terms table (misconception vs. reality)
  ✓ Further Reading (with explanations)

CODE
  ✓ code/main.py runs without errors
  ✓ Code is self-explanatory
  ✓ No unnecessary comments
  ✓ Starts simple, builds complexity

ARTIFACTS
  ✓ outputs/prompt-*.md has YAML frontmatter
  ✓ outputs/skill-*.md has YAML frontmatter
  ✓ All fields: name, description, version, phase, lesson, tags

INTEGRATION
  ✓ Prerequisites listed
  ✓ New glossary terms defined
  ✓ Links are valid
  ✓ Follows subject terminology

PASSES → ✅ Ready to merge
FAILS  → 🔨 Request changes
```

---

## File Size Reference

```
Typical Repository Stats:
─────────────────────────

Phases:          15
Lessons:        150
Code Files:     150
Prompts:         80
Skills:         120
Agents:          20

Folder Size:    ~500 MB (including code, data)
Git Size:       ~100 MB (after compression)
Build Time:        3-5 seconds (generate catalog.json)
Website:           Auto-deployed on each push
```

---

**This visual guide helps you understand how all the pieces fit together.**
