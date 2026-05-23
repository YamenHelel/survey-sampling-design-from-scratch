---
name: skill-tse-diagnostic-report
description: Automated Total Survey Error diagnostic report generator
version: 1.0.0
phase: 0
lesson: 3
tags: [total-survey-error, non-response, quality, diagnostics]
---

# Skill: Total Survey Error Diagnostic Report

## What It Does

Generates a comprehensive TSE diagnostic report covering response analysis, non-response bias indicators, sampling error indicators, and coverage checks against known population totals.

## Usage

```r
generate_tse_report(
  sample_data = my_survey,
  response_col = "responded",
  weight_col = "weight",
  key_variables = c("income", "age", "urban"),
  frame_size = 500000,
  known_totals = list(urban = 300000)
)
```
