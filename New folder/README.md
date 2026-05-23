# Learning Repository Documentation

## What's in These Files

I've analyzed the **AI Engineering from Scratch** repository and created three comprehensive guides to help you create similar learning repositories for different subjects.

---

## 📄 File 1: `REPOSITORY_STRUCTURE_GUIDE.md` (23KB)

**The comprehensive reference** — Everything you need to know about the repository structure and pedagogy.

### Contains:
- Philosophy & pedagogical approach (6-beat lesson structure)
- Complete folder structure breakdown
- Purpose of every root-level file (README.md, ROADMAP.md, catalog.json, etc.)
- Detailed explanation of phases, lessons, and outputs
- How the build pipeline works (site/build.js)
- Step-by-step guide to adapting for a new subject
- Quality checklist for lessons

### Best for:
- Deep understanding of how the repository is organized
- Building your own pipeline and automation
- Detailed reference when creating lessons
- Understanding why each file exists

**Read this when**: You want the full picture and detailed explanations

---

## 📄 File 2: `AI_AGENT_CURRICULUM_PROMPT.md` (8KB)

**The AI agent prompt** — Copy-paste this into an AI agent to generate a new learning repository.

### Contains:
- System prompt explaining the curriculum design task
- Instructions for defining phase structure
- Template for example lessons (3 complete lessons across different phases)
- Requirements for supporting documents
- Code examples format
- Folder structure diagram
- Evaluation criteria
- Guidelines and constraints
- Example subject breakdown (Sampling in Household Surveys)

### Best for:
- Feeding to an AI agent to generate curriculum design
- Getting a starting template for a new repository
- Understanding the output format an AI should produce

**Use this when**: You want to ask an AI to create a new learning repository for a topic

---

## 📄 File 3: `QUICK_REFERENCE.md` (9KB)

**One-page cheat sheet** — Quick lookup for structure, conventions, and templates.

### Contains:
- 6-beat lesson structure (one-table summary)
- Folder structure at a glance (ASCII diagram)
- Naming conventions
- Lesson frontmatter examples
- Lesson markdown template
- Key terms format
- ROADMAP status glyphs
- Required root files table
- Phase design examples
- Quality checklist (condensed)
- Why this structure works

### Best for:
- Quick reference while building
- Checking conventions and naming
- Sharing with contributors
- Quick overview without reading everything

**Use this when**: You need to look something up fast

---

## 🎯 How to Use These Files

### Scenario 1: You want to create a repository about "Sampling in Household Surveys"

1. **Read** `QUICK_REFERENCE.md` (5 minutes) — Get oriented
2. **Read** `REPOSITORY_STRUCTURE_GUIDE.md` sections "Adapt This for a New Subject" (10 minutes)
3. **Use** `AI_AGENT_CURRICULUM_PROMPT.md` — Give it to an AI agent with your subject
4. **Reference** `QUICK_REFERENCE.md` while building each lesson

### Scenario 2: You want to understand the AI Engineering from Scratch structure

1. **Skim** `QUICK_REFERENCE.md` (3 minutes) — Get the patterns
2. **Read** `REPOSITORY_STRUCTURE_GUIDE.md` completely (30 minutes) — Deep understanding
3. **Use** as reference when exploring the actual repo

### Scenario 3: You're building a new repository and need to onboard contributors

1. **Share** `QUICK_REFERENCE.md` with contributors
2. **Share** the "Lesson Markdown Template" section from `QUICK_REFERENCE.md`
3. **Link to** the full `REPOSITORY_STRUCTURE_GUIDE.md` for detailed questions

---

## 🔑 Core Concept: The 6-Beat Lesson

Every lesson in these repositories follows this structure:

1. **Motto** — One-line insight
2. **Problem** — Concrete pain point (why this matters)
3. **Concept** — Mental models and intuition (no code)
4. **Build It** — Implement from scratch, step-by-step
5. **Use It** — Show production library doing the same thing
6. **Ship It** — Produce a reusable prompt, skill, or agent

This pattern repeats identically across every lesson, making learning predictable and the repository maintainable.

---

## 📦 Folder Structure Summary

```
your-learning-repo/
├── README.md                 # Homepage with curriculum overview
├── LESSON_TEMPLATE.md        # Template for new lessons
├── CONTRIBUTING.md           # How to contribute
├── ROADMAP.md               # Detailed progress tracker
├── catalog.json             # Auto-generated index
├── requirements.txt         # All dependencies
├── glossary/
│   ├── terms.md            # Term definitions
│   └── myths.md            # Misconceptions
├── phases/                  # Main curriculum
│   ├── 00-foundations/
│   ├── 01-intermediate/
│   └── ...
├── projects/               # Capstone projects
├── outputs/                # Compiled prompts/skills/agents
├── scripts/                # Build automation
└── assets/                 # Images, diagrams
```

---

## ✨ Key Principles

1. **Linear progression** — Phases build on each other
2. **Consistent structure** — Same pattern in every lesson
3. **Build-first pedagogy** — Implement before using frameworks
4. **Reusable outputs** — Every lesson ships with prompts/skills/agents
5. **Multi-language** — Core concepts in 1-3 programming languages
6. **Automated pipeline** — Scripts keep the index in sync
7. **Community-friendly** — Clear guidelines for contributors

---

## 🚀 Next Steps

1. **Define your subject** — What do you want to teach?
2. **Plan your phases** — How many phases? (typically 5-15)
3. **Create phase structure** — What are the foundational layers, domains, and integration points?
4. **Build the folder structure** — Follow the template
5. **Write 1-2 example lessons** — Use the template, test the pattern
6. **Set up automation** — Build scripts to generate catalog.json and validate structure
7. **Invite contributors** — Use CONTRIBUTING.md and QUICK_REFERENCE.md to onboard them

---

## 📚 Example: "Sampling in Household Surveys"

From `REPOSITORY_STRUCTURE_GUIDE.md`, here's how you'd break down this subject:

- **Phase 0**: Setup & Foundations (12 lessons)
- **Phase 1**: Statistical Foundations (15 lessons)
- **Phase 2**: Sampling Theory (18 lessons)
- **Phase 3**: Household Survey Design (20 lessons)
- **Phase 4**: Analysis & Inference (16 lessons)
- **Phase 5**: Practical Applications & Case Studies (10 lessons)
- **Phase 6**: Capstone Projects (8 projects)

**Total**: 7 phases, ~90 lessons, ~250 hours

Each lesson would follow the 6-beat structure and produce runnable code + reusable skills.

---

## 💡 Pro Tips

1. **Start with phase structure** — Get the linear progression right before writing lessons
2. **Name consistently** — Use kebab-case for folders and files everywhere
3. **Automate early** — Build the build script (catalog.json generation) in phase 0
4. **Example lessons** — Build 2-3 complete lessons first to test the pattern
5. **Glossary first** — Define your terms before writing lessons
6. **Multi-language optional** — Python is enough; add others if the subject needs it
7. **Reusable artifacts** — Every lesson must produce at least one prompt/skill/agent

---

## 📖 Files at a Glance

| File | Size | Read Time | Best For |
|------|------|-----------|----------|
| `QUICK_REFERENCE.md` | 9KB | 5 min | Quick lookup, conventions, cheat sheet |
| `AI_AGENT_CURRICULUM_PROMPT.md` | 8KB | 5 min | Feeding to AI agents, curriculum templates |
| `REPOSITORY_STRUCTURE_GUIDE.md` | 23KB | 30 min | Deep understanding, detailed reference |

---

**All three files are stored in your session folder** (`C:\Users\hp\.copilot\session-state\...\files\`) and can be referenced anytime.

Good luck building your learning repository! 🚀
