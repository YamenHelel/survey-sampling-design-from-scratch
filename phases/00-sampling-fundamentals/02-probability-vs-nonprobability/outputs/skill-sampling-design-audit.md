---
name: skill-sampling-design-audit
description: Diagnostic tool to evaluate if a survey meets probability sampling requirements
version: 1.0.0
phase: 0
lesson: 2
tags: [probability-sampling, audit, inclusion-probability, design-check]
---

# Skill: Sampling Design Audit

## What It Does

Evaluates whether a survey dataset meets the mathematical requirements for probability sampling: known, positive inclusion probabilities for all units, and acceptable weight variability.

## R Implementation

```r
audit_sampling_design <- function(sample_data,
                                  frame_size,
                                  inclusion_prob_col = NULL,
                                  cluster_col = NULL,
                                  stratum_col = NULL) {
  n <- nrow(sample_data)
  issues <- character(0)

  # Check 1: Inclusion probabilities exist and are valid
  if (!is.null(inclusion_prob_col) && inclusion_prob_col %in% names(sample_data)) {
    pi_vals <- sample_data[[inclusion_prob_col]]
    n_missing <- sum(is.na(pi_vals))
    n_zero <- sum(pi_vals <= 0, na.rm = TRUE)
    if (n_missing > 0) issues <- c(issues, sprintf("%d missing pi_i", n_missing))
    if (n_zero > 0) issues <- c(issues, sprintf("%d zero/negative pi_i", n_zero))
  } else {
    issues <- c(issues, "No inclusion probability column found")
  }

  # Check 2: Weight variability
  if (!is.null(inclusion_prob_col) && inclusion_prob_col %in% names(sample_data)) {
    weights <- 1 / sample_data[[inclusion_prob_col]]
    weights <- weights[!is.na(weights) & is.finite(weights)]
    cv_w <- sd(weights) / mean(weights) * 100
    if (cv_w > 200) issues <- c(issues, "Extreme weight variability (CV > 200%)")
  }

  list(is_probability = length(issues) == 0, issues = issues)
}
```

## Usage

```r
result <- audit_sampling_design(my_sample, frame_size = 500000, inclusion_prob_col = "pi_i")
```
