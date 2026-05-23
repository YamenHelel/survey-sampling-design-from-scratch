# Concrete Examples: How to Adapt for Different Subjects

Real-world examples showing how to take this repository structure and apply it to completely different subjects.

---

## Example 1: Sampling in Household Surveys

### Subject Overview
Teaching modern household survey methodology: sampling design, data collection, analysis, and practical application.

---

### Phase Structure (7 phases, ~90 lessons, ~200 hours)

#### Phase 0: Setup & Foundational Concepts (12 lessons)
**Objectives:**
- Set up survey software (R, Python)
- Understand survey data formats
- Ethical foundations

**Key Lessons:**
- 01-environment-setup
- 02-data-formats
- 03-ethical-considerations-in-surveys
- 04-survey-software-overview
- ...

**Outputs:**
- Prompts: "Design an ethical survey"
- Skills: "Recognize biased survey questions"
- Agent: "Survey quality checker"

---

#### Phase 1: Statistical Foundations (15 lessons)
**Objectives:**
- Probability distributions
- Estimators and their properties
- Hypothesis testing
- Confidence intervals

**Key Lessons:**
- 01-probability-distributions
- 02-estimators-bias-variance
- 03-hypothesis-testing
- 04-confidence-intervals
- 05-statistical-power
- ...

**Outputs:**
- Skill: "Calculate sample size given power constraints"
- Prompt: "Explain Type I vs Type II error"
- Agent: "Statistical assumptions validator"

---

#### Phase 2: Sampling Theory (18 lessons)
**Objectives:**
- Core sampling designs
- Stratification strategies
- Clustering and multi-stage sampling
- Non-response and adjustment

**Key Lessons:**
- 01-simple-random-sampling
- 02-stratified-sampling
- 03-cluster-sampling
- 04-two-stage-sampling
- 05-non-response-bias
- 06-post-stratification
- 07-replication-methods
- ...

**Outputs:**
- Skill: "Design a stratified sample"
- Prompt: "Compare sampling designs for efficiency"
- Code: Working Python implementation of each design

---

#### Phase 3: Household Survey Design (20 lessons)
**Objectives:**
- Questionnaire design principles
- Sampling frame construction
- Implementation logistics
- Quality control

**Key Lessons:**
- 01-questionnaire-principles
- 02-sampling-frame-construction
- 03-survey-mode-selection
- 04-fieldwork-management
- 05-data-validation-cleaning
- ...

**Outputs:**
- Template: "Questionnaire design checklist"
- Agent: "Survey quality assessor"
- Prompt: "Identify survey design issues"

---

#### Phase 4: Analysis & Inference (16 lessons)
**Objectives:**
- Survey-weighted estimation
- Variance estimation for surveys
- Domain estimation
- Small area estimation

**Key Lessons:**
- 01-survey-weighted-estimation
- 02-variance-estimation-for-surveys
- 03-domain-estimation
- 04-small-area-estimation
- 05-missing-data-imputation
- ...

**Outputs:**
- Skill: "Compute domain estimates with proper variance"
- Code: Reusable functions for weighted analysis
- Prompt: "Design analysis strategy for survey data"

---

#### Phase 5: Practical Applications (12 lessons)
**Objectives:**
- Real household surveys
- Case studies from national statistical offices
- Handling practical challenges

**Key Lessons:**
- 01-labor-force-survey
- 02-household-income-survey
- 03-health-survey-design
- 04-case-study-national-survey
- ...

**Outputs:**
- Project: "Analyze real survey data"
- Prompt: "Troubleshoot survey implementation issues"

---

#### Phase 6: Capstone Projects (8 projects)
**Objectives:**
- Design and analyze real surveys
- Combine knowledge from all phases

**Sample Projects:**
- Design a household consumption survey
- Analyze public health survey data
- Compare sampling strategies
- Create quality assessment report

---

### Example Lesson: "02-stratified-sampling" (Phase 2, Lesson 2)

#### Lesson Structure

```markdown
# Stratified Sampling: Precision Gain Through Organization

> **Motto**: Divide your population into homogeneous groups, 
> sample from each, and watch your standard errors shrink.

**Type**: Build
**Languages**: Python
**Prerequisites**: 01-simple-random-sampling, Phase 1 (Statistical Foundations)
**Time**: ~40 minutes

---

## The Problem

Imagine you're surveying household income across an entire country. 
If you use simple random sampling, your estimates will be noisy 
because income varies wildly: some households earn $10k/year, 
others earn $500k+. 

But you know that income correlates strongly with education level 
and region. If you split your population by these characteristics 
(creating "strata"), then sample within each stratum, your estimates 
become much more precise.

This is stratification. The gain in precision can reduce your required 
sample size by 30-50% compared to simple random sampling.

---

## The Concept

### How Stratification Works

```
ENTIRE POPULATION
├─ STRATUM 1: [Urban, High Education] 
│  └─ Similar incomes within
├─ STRATUM 2: [Rural, Medium Education]
│  └─ Similar incomes within
└─ STRATUM 3: [Rural, Low Education]
   └─ Similar incomes within

STRATIFIED SAMPLE
├─ Sample from Stratum 1 (get high-income units)
├─ Sample from Stratum 2 (get medium-income units)
└─ Sample from Stratum 3 (get low-income units)

→ Estimate is more precise because you cover the full range
```

### Why It Works

- **Reduced variance**: Each stratum is more homogeneous than the full population
- **Automatic representation**: Rare groups get representation if you allocate correctly
- **Flexibility**: You control sample size in each stratum

### Key Decision: Allocation

```
ALLOCATION RULES (How many to sample from each stratum)

Proportional: n_h = n * (N_h / N)
  → Sample size matches population proportion
  → Simplest, but doesn't maximize precision

Neyman: n_h = n * (N_h * σ_h) / Σ(N_i * σ_i)
  → Sample more from variable strata
  → Minimizes variance for fixed total n
  → Requires knowing σ_h beforehand (often estimated from pilot)

Optimal: Same as Neyman + cost considerations
  → If strata have different costs to survey
```

---

## Build It

### Step 1: Create Strata from Raw Data

```python
import pandas as pd
import numpy as np

households = pd.read_csv('households.csv')
# Columns: income, education, region

# Create strata
households['stratum'] = (
    households['region'].astype(str) + '_' +
    pd.cut(households['education'], 3, labels=['Low','Med','High']).astype(str)
)

print(households.groupby('stratum').size())
# Shows stratum sizes: N_h
```

### Step 2: Calculate Stratum-Specific Variance

```python
# For each stratum, compute variance of income
stratum_stats = households.groupby('stratum')['income'].agg([
    ('N_h', 'count'),
    ('sigma_h', 'std'),
    ('mean_h', 'mean')
]).reset_index()

print(stratum_stats)
# Stratum with σ_h > 5000 are variable (needs bigger sample)
```

### Step 3: Determine Sample Allocation

```python
# Neyman allocation
total_sample = 500
stratum_stats['numerator'] = (
    stratum_stats['N_h'] * stratum_stats['sigma_h']
)
stratum_stats['sum_numerator'] = stratum_stats['numerator'].sum()

stratum_stats['n_h'] = (
    total_sample * 
    stratum_stats['numerator'] / stratum_stats['sum_numerator']
).astype(int)

print(stratum_stats[['stratum', 'N_h', 'sigma_h', 'n_h']])
# Strata with high σ_h get more samples
```

### Step 4: Draw Stratified Sample

```python
# Sample n_h units from each stratum
sampled = households.groupby('stratum', group_keys=False).apply(
    lambda x: x.sample(n=int(stratum_stats[
        stratum_stats['stratum'] == x.name
    ]['n_h'].values[0]))
)

print(f"Total sampled: {len(sampled)}")
print(sampled.groupby('stratum').size())
```

### Step 5: Estimate Population Mean with Proper Variance

```python
# Stratified estimator of population mean
N = len(households)
strata_means = sampled.groupby('stratum')['income'].agg(['mean', 'count', 'std'])
strata_means['W_h'] = (
    households.groupby('stratum').size() / N
)

# Population estimate
y_st = (strata_means['mean'] * strata_means['W_h']).sum()

# Variance of stratified estimator
n_h = strata_means['count']
sigma_h = strata_means['std']
N_h = households.groupby('stratum').size()

var_y_st = sum(
    (N_h[h] / N) ** 2 * 
    (1 - n_h[h] / N_h[h]) * 
    sigma_h[h] ** 2 / n_h[h]
    for h in strata_means.index
)

se_y_st = np.sqrt(var_y_st)
ci_lower = y_st - 1.96 * se_y_st
ci_upper = y_st + 1.96 * se_y_st

print(f"Mean income estimate: ${y_st:.2f}")
print(f"95% CI: [${ci_lower:.2f}, ${ci_upper:.2f}]")
```

---

## Use It

Now do the same with Python's `survey` libraries:

```python
from survey import Survey
import pickle

# Create survey design object
design = Survey(
    data=sampled,
    strata='stratum',
    nest=False,
    weights='weight'  # if different from design weights
)

# Estimate population mean
mean_est = design.mean('income')
print(mean_est)
# Returns: estimate, SE, CI — all computed correctly
```

**What changed?**
- Your manual calculations ↔ Production library
- You saw exactly how variance computation works
- Now you trust the library because you wrote the small version first

---

## Ship It

### Prompt
```markdown
---
name: prompt-stratify-your-survey
description: Design a stratification strategy for your household survey
version: 1.0.0
phase: 2
lesson: 2
tags: [stratification, survey-design, sampling]
---

# Prompt: Stratify Your Household Survey

You are helping a survey statistician design their sampling strategy.
Given: population characteristics, ...
```

### Skill
```markdown
---
name: skill-neyman-allocation
description: Calculate Neyman-optimal sample allocation across strata
version: 1.0.0
phase: 2
lesson: 2
tags: [allocation, optimization, sampling]
---

## What is Neyman Allocation?

Neyman allocation answers: "How should I distribute my fixed sample 
size across strata to minimize variance?"

The formula:
  n_h = n * (N_h * σ_h) / Σ(N_i * σ_i)
...
```

---

## Exercises

1. **Easy**: Given 3 strata with known N_h and σ_h, calculate Neyman allocation 
   for n=1000.

2. **Medium**: You have pilot data suggesting region is strongly associated with 
   income (σ within region << σ between regions). Redesign your strata to reflect 
   this; recalculate required sample size to achieve ±$5k CI.

3. **Hard**: Cost to survey urban households is $100/unit, rural is $300/unit. 
   Given budget $200k, optimize allocation (Neyman vs. cost-optimal). Compare 
   resulting precisions.

---

## Key Terms

| Term | What people say | What it actually means |
|------|----------------|----------------------|
| Stratum | "Just split the data" | Mutually exclusive, exhaustive group homogeneous on variable of interest |
| Allocation | "How many per group?" | Decision rule mapping n to each h that minimizes variance or cost |
| Neyman allocation | "Magic formula" | Optimal rule when costs equal; maximizes precision for fixed n |

---

## Further Reading

- Kish, L. (1965). Survey Sampling. Wiley. — The foundational textbook
- Cochran, W.G. (1977). Sampling Techniques. Wiley. — Mathematical rigor
- UN Handbook on Stratified Sampling — Practical guidance for national surveys
```

---

## Example Capstone Project

**Project: Design a National Household Income Survey**

**Objectives:**
- Design complete survey including stratification
- Pilot and estimate variances
- Calculate sample size for CI width
- Plan fieldwork and quality control

**Deliverables:**
- Survey design document (5-10 pages)
- Sampling frame construction details
- Stratification rationale
- Sample size calculation with justification
- Budget and timeline
- Draft questionnaire
- Quality control plan

**Learning outcome:** You now understand how real household surveys are built.

---

---

## Example 2: Constitutional Law (Non-Technical Subject)

### Phase Structure (12 phases, ~144 lessons, ~180 hours)

#### Phase 0: Foundations (12 lessons)
- What is a constitution?
- Rule of law principles
- Separation of powers
- Historical context

**Outputs:** Prompts like "Explain the purpose of a constitution"

#### Phase 1: Rights & Freedoms (14 lessons)
- Freedom of speech & expression
- Due process rights
- Privacy rights
- Equality protections

**Outputs:** Skills like "Analyze whether a law violates free speech"

#### Phase 2: Structures of Government (16 lessons)
- Executive branch powers & limits
- Legislative branch structure
- Judicial review
- Federalism

**Outputs:** Agent like "Constitutional law question answerer"

---

#### Example Lesson: "05-judicial-review"

```markdown
# Judicial Review: How Courts Check Government Power

> When courts can overturn laws, democracy stays in balance.

**Type**: Learn | Analyze
**Languages**: Legal writing (case briefs)
**Prerequisites**: 01-rule-of-law, 04-separation-of-powers
**Time**: ~45 minutes

---

## The Problem

Governments pass unjust laws. Without judicial review, citizens 
have no recourse except voting (which is too slow).

Example: A state bans certain religions. Without courts empowered 
to strike down the law, those citizens are permanently oppressed.

Judicial review—the power of courts to void unconstitutional laws—
is the safety valve.

---

## The Concept

### The Marbury v. Madison Framework

Chief Justice Marshall's 1803 decision established:
1. Constitution is supreme law
2. Courts interpret the Constitution
3. When law conflicts Constitution, courts apply Constitution

### Levels of Scrutiny

Courts don't all review laws the same way:

```
┌──────────────┐
│ STRICT       │ (Most searching review)
│ SCRUTINY     │ Government must show compelling interest & 
│              │ narrowly tailored solution
│              │ Applied to: race, religion, fundamental rights
├──────────────┤
│ INTERMEDIATE │ Government must show important interest &
│ SCRUTINY     │ substantially related means
│              │ Applied to: gender, quasi-suspect classifications
├──────────────┤
│ RATIONAL     │ (Minimal review)
│ BASIS        │ Government just needs rational relationship
│              │ to legitimate purpose
│              │ Applied to: economic regulations
└──────────────┘
```

### How Judicial Review Works

```
Law is passed
     ↓
Citizen sues: "This law is unconstitutional"
     ↓
Court examines:
  1. What constitutional right is affected?
  2. What level of scrutiny applies?
  3. Can government meet that standard?
     ↓
If no: Law is struck down
If yes: Law stands
```

---

## Build It: Analyze a Case

### Step 1: Identify the Constitutional Claim

**Case: Loving v. Virginia (1967)**
- Virginia law: Interracial marriage is illegal
- Constitutional claim: Violates Equal Protection Clause (14th Amendment)

### Step 2: Determine What Right is Implicated

```
Which fundamental rights are involved?
✓ Right to marry
✓ Right to equal protection (race discrimination)
✓ Right to liberty (freedom to choose life partner)
```

### Step 3: Choose Level of Scrutiny

```
Race classification + fundamental right = STRICT SCRUTINY

Question: Does Virginia have a COMPELLING interest 
in banning interracial marriage, and is the ban 
NARROWLY TAILORED to that interest?
```

### Step 4: Apply the Standard

```
Virginia's justification: "Prevent race mixing"

STRICT SCRUTINY ANALYSIS:
✗ Compelling interest? No. "Preventing race mixing" isn't a 
  legitimate government interest; it's just racial animus.
✗ Narrowly tailored? Irrelevant; interest fails.

CONCLUSION: Law violates Equal Protection. STRUCK DOWN.
```

### Step 5: Write a Case Brief

```
CASE: Loving v. Virginia, 388 U.S. 1 (1967)

FACTS:
- Richard Loving (white) married Mildred Jeter (Black)
- Virginia law made this a felony
- Couple convicted and sentenced

ISSUE:
- Does Virginia's anti-miscegenation law violate Equal Protection?

RULE:
- Race classifications trigger strict scrutiny
- Gov't must show compelling interest + narrow tailoring
- Presumption: law is unconstitutional

APPLICATION:
- Virginia's interest (preventing race mixing) is not compelling;
  it's merely expressing a preference based on race
- No narrow tailoring

CONCLUSION:
- Law unconstitutional; struck down
- Right to marry is fundamental; can't be restricted based on race
```

---

## Use It: Study Supreme Court Doctrine

Apply your analysis framework to:
- New cases (e.g., Obergefell v. Hodges — same-sex marriage)
- Hypotheticals (e.g., "Would a law banning red cars violate Equal Protection?")
- Current events (e.g., recent voting rights cases)

**The skill transfers**: You now have a framework for analyzing 
ANY law against ANY constitutional protection.

---

## Ship It

### Prompt
```markdown
---
name: prompt-constitutional-analysis
description: Framework for analyzing whether a law violates the Constitution
version: 1.0.0
phase: 2
lesson: 5
tags: [constitutional-law, judicial-review, rights]
---

# Constitutional Analysis Framework

When asked whether a law is constitutional, follow these steps:

1. Identify the constitutional provision at issue
2. Identify the right or liberty infringed
3. Determine the appropriate level of scrutiny
4. Apply that standard
5. Conclude constitutionally or not
...
```

### Skill
```markdown
---
name: skill-strict-scrutiny-analysis
description: Apply strict scrutiny to race and rights-based classifications
version: 1.0.0
phase: 2
lesson: 5
tags: [equal-protection, strict-scrutiny]
---

## Strict Scrutiny Analysis

When a law classifies people by race or infringes a fundamental right:

Question 1: Is there a COMPELLING government interest?
  → Courts almost never find compelling interests in race-based laws
  → Examples of actual compelling interests: national security, preventing 
    death row escapes

Question 2: Is the law NARROWLY TAILORED?
  → Must be least-restrictive means to achieve interest
  → Over- or under-inclusive = fails narrow tailoring
...
```

---

## Exercises

1. **Easy**: Apply rational basis review to a hypothetical tax on orange cars.

2. **Medium**: Analyze Plessy v. Ferguson (separate but equal) and 
   Brown v. Board of Education (overturning it). What changed in 
   constitutional doctrine?

3. **Hard**: Should a law banning women from combat roles survive 
   intermediate scrutiny? Construct both sides' arguments.

---

```

---

## Key Takeaways: How to Adapt Any Subject

1. **Define phases logically** — Foundation → Intermediate → Advanced
2. **Every lesson teaches a concept** — Not just a fact; a mental model
3. **Every lesson has Build & Use components** — Even if not code:
   - Law: "Build It" = analyze a case; "Use It" = apply to new case
   - Chemistry: "Build It" = derive equation; "Use It" = use it to predict
   - History: "Build It" = examine primary sources; "Use It" = explain events with framework
4. **Every lesson ships with reusable artifacts** — Prompts, skills, templates, analyses
5. **Consistency is the feature** — Same structure everywhere

---

## Subject Categories & How They Map

**STEM Subjects** (Math, Physics, Chemistry, Biology, CS)
- Build It: Derive/implement the algorithm
- Use It: Production library/software
- Ship It: Code + prompts explaining it

**Law & Policy** (Constitutional Law, Tax Law, Ethics)
- Build It: Analyze landmark cases/texts
- Use It: Apply framework to current events/hypotheticals
- Ship It: Decision frameworks + prompts

**Humanities** (Literature, History, Philosophy)
- Build It: Close reading of primary sources
- Use It: Apply interpretation to new texts/events
- Ship It: Analysis frameworks + essay prompts

**Business & Economics** (Finance, Marketing, Strategy)
- Build It: Calculate/model from first principles
- Use It: Production tools/frameworks
- Ship It: Decision templates + prompts

**Every subject fits. The pedagogy is universal.**

