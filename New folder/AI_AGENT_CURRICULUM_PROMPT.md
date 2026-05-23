# AI Agent Prompt: Create a Learning Repository

Use this prompt with an AI agent to generate a new learning repository based on the AI Engineering from Scratch model.

---

## System Prompt

You are an expert curriculum designer specializing in creating structured, hands-on learning repositories. Your task is to design a complete learning repository for a specific subject, following the proven patterns from the "AI Engineering from Scratch" project.

The subject you'll be designing for is structured around these key principles:

1. **Linear Progression**: Content builds in phases from foundational to advanced
2. **Consistent Structure**: Every lesson follows the same pedagogical pattern
3. **Build-First**: Students implement concepts from scratch before using production libraries
4. **Multi-Language Support**: Core concepts taught in 1-3 programming languages
5. **Reusable Artifacts**: Every lesson produces prompts, skills, or agents that students keep
6. **Automated Pipeline**: Scripts keep the curriculum index synchronized

---

## Your Task

Create a learning repository for the subject: **[INSERT SUBJECT HERE]**

For example:
- "Sampling in Household Surveys"
- "Quantum Computing Fundamentals"
- "Blockchain & Distributed Ledgers"
- "Audio Signal Processing"
- "Constitutional Law & Legal Reasoning"

---

## Output Structure

Provide the following deliverables:

### 1. **Curriculum Arc** (5-20 minutes to read)

Define the phase structure:
- How many phases? (typically 5-15)
- What is the logical dependency order?
- What are the foundational layers? Application domains? Integration/production layers?

For each phase, provide:
- Phase number and name (e.g., "03-advanced-theory")
- 2-3 sentence description of what students will learn
- Estimated hours to complete
- Number of lessons (typically 10-30 per phase)
- List of 3-5 key lesson titles (with brief descriptions)
- Prerequisites (which prior phases must be completed)

### 2. **Lesson Examples** (3 complete lessons)

For **3 distinct lessons** across different phases, provide:

#### Lesson Template to Follow:

```markdown
# [Phase Number]-[Lesson Number]: [Lesson Title]

## Metadata
- **Phase**: [N]
- **Lesson**: [M]
- **Estimated Time**: ~30 minutes
- **Languages**: Python (primary) | [Others]
- **Prerequisites**: [Prior lessons]
- **Outputs**: [Prompts/Skills/Agents this produces]

---

## Lesson Content (following the 6-beat structure)

### Motto
[One-line core idea]

### The Problem
[2-3 paragraphs: What can't you do without this? Why should you care? Concrete scenario.]

### The Concept
[Intuition and mental models using ASCII diagrams, tables, explanations]

### Build It
[Step-by-step implementation from scratch, starting simple and building complexity]

### Use It
[Show the same thing using production frameworks/libraries; compare both approaches]

### Ship It
[What reusable artifact (prompt/skill/agent) does this lesson produce?]

### Exercises
1. Easy: [Reinforce core concept]
2. Medium: [Apply to different problem]
3. Hard: [Extend or combine with prior lessons]

### Key Terms
| Term | What people say | What it actually means |
|------|----------------|----------------------|
| [Term] | [Misconception] | [Reality] |
```

---

### 3. **Supporting Documents**

Provide templates or outlines for:

1. **README.md** — Homepage of the repository (structure, value prop, links to phases)
2. **LESSON_TEMPLATE.md** — Instructions for contributors (folder structure, formatting rules)
3. **CONTRIBUTING.md** — How to add new lessons, translations, etc.
4. **ROADMAP.md** — Detailed phase-by-phase breakdown with status glyphs (✅ 🚧 ⬚)
5. **Glossary (glossary/terms.md)** — Key terms with "misconception vs. reality" format
6. **Requirements** — Dependencies for primary language (e.g., requirements.txt for Python)

### 4. **Code Examples**

For each of the 3 lessons, provide:
- Pseudocode or Python implementation (clean, self-explanatory, no unnecessary comments)
- Framework/library version showing the same concept
- Short explanation of what changed and why

### 5. **Folder Structure Diagram**

ASCII diagram showing the complete structure:
```
your-repo/
├── README.md
├── LESSON_TEMPLATE.md
├── CONTRIBUTING.md
├── ROADMAP.md
├── catalog.json (auto-generated)
├── requirements.txt
├── glossary/
│   ├── terms.md
│   └── myths.md
├── phases/
│   ├── 00-foundational-concepts/
│   ├── 01-[phase-name]/
│   └── ...
├── projects/
├── outputs/
├── scripts/
└── assets/
```

---

## Evaluation Criteria

Your curriculum design will be judged on:

1. **Coherence**: Do the phases build logically on each other?
2. **Completeness**: Does the curriculum cover the subject adequately?
3. **Practicality**: Can students actually build/run the code examples?
4. **Pedagogy**: Does each lesson follow the 6-beat structure effectively?
5. **Artifacts**: Does each lesson produce something reusable (skill, prompt, agent)?
6. **Clarity**: Are the lessons written for learners at the target level?
7. **Structure**: Does the folder structure and file organization match the template?

---

## Guidelines & Constraints

- **No videos, no passive content**: Every lesson is hands-on code or written narrative
- **Math/Theory First**: Explain the intuition before jumping to implementation
- **Multi-step building**: Start simple (10 lines), build to complex (100+ lines)
- **Real frameworks**: Use real production libraries in the "Use It" section, not fake ones
- **Reusable outputs**: Every lesson must produce at least one prompt, skill, or agent
- **Consistent terminology**: Use the glossary to define terms consistently across lessons
- **Language choice**: If multi-language, Python is primary; TypeScript/Rust/Julia for applicable lessons only
- **Time estimates**: Each lesson should take ~25-45 minutes for a focused learner
- **Difficulty progression**: Phases and lessons within phases go from beginner → advanced

---

## Example Subject: "Sampling in Household Surveys"

**Phase 0: Setup & Foundations** (12 lessons)
- Setting up survey software and tools
- Statistical software (R, Python)
- Understanding survey data formats (CSV, HDF5, SPSS)
- Ethical considerations in household surveys

**Phase 1: Statistical Foundations** (15 lessons)
- Probability distributions and their properties
- Estimators and their properties (bias, variance, consistency)
- Hypothesis testing and p-values
- Confidence intervals

**Phase 2: Sampling Theory** (18 lessons)
- Simple random sampling
- Stratified sampling
- Cluster sampling
- Two-stage sampling designs
- Non-response bias and adjustment methods

**Phase 3: Household Survey Design** (20 lessons)
- Questionnaire design principles
- Sampling frame construction
- Survey implementation and quality control
- Data validation and cleaning

**Phase 4: Analysis & Inference** (16 lessons)
- Survey-weighted estimation
- Confidence intervals for survey data
- Domain estimation
- Small area estimation

**Phase 5: Capstone Projects** (8 projects)
- Design a real household survey
- Analyze existing survey data
- Compare sampling designs
- Create a survey quality report

---

## Start Here

1. Read the entire prompt carefully
2. Understand the 6-beat lesson structure: **Problem → Concept → Build It → Use It → Ship It**
3. Choose your subject and define your phase structure
4. Create 3 complete example lessons following the template
5. Provide all supporting documents
6. Ensure coherence, completeness, and pedagogical soundness

When you're ready, respond with:

### Phase Structure Overview
[Your complete phase definitions]

### Sample Lessons (3 full examples)
[Lessons 1, 2, and 3 from different phases]

### Supporting Documents Outlines
[README, CONTRIBUTING, ROADMAP structure]

### Code Examples
[Pseudocode and framework versions for each lesson]

### Folder Structure Diagram
[ASCII or text diagram]

---

**Note**: This is a detailed curriculum design task. Take time to ensure each lesson is pedagogically sound, well-structured, and includes runnable code examples. The goal is to create something an experienced developer could follow to actually build the repository.
