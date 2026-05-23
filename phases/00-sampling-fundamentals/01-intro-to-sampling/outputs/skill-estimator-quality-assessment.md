---
name: skill-estimator-quality-assessment
description: Monte Carlo simulation to assess estimator properties (bias, variance, MSE, CV)
version: 1.0.0
phase: 0
lesson: 1
tags: [simulation, monte-carlo, estimator, bias, mse, unbiasedness]
---

# Skill: Estimator Quality Assessment

## What It Does

This production function runs a Monte Carlo simulation to evaluate any estimator's statistical properties against a known population.

## R Implementation

```r
estimator_quality_report <- function(population_values,
                                     sample_size,
                                     n_simulations = 10000,
                                     estimator_fn = mean,
                                     seed = 2024) {
  set.seed(seed)

  N <- length(population_values)
  n <- sample_size
  theta <- estimator_fn(population_values)

  stopifnot(n < N, n > 0, N > 0)

  estimates <- numeric(n_simulations)
  for (b in 1:n_simulations) {
    idx <- sample(N, n, replace = FALSE)
    estimates[b] <- estimator_fn(population_values[idx])
  }

  e_hat     <- mean(estimates)
  bias      <- e_hat - theta
  variance  <- var(estimates)
  mse       <- variance + bias^2
  rmse      <- sqrt(mse)
  cv        <- (sqrt(variance) / abs(e_hat)) * 100
  ci_lower  <- quantile(estimates, 0.025)
  ci_upper  <- quantile(estimates, 0.975)

  cat("============================================================\n")
  cat("  ESTIMATOR QUALITY ASSESSMENT REPORT\n")
  cat("============================================================\n")
  cat(sprintf("  Population size (N)    : %s\n", format(N, big.mark = ",")))
  cat(sprintf("  Sample size (n)        : %s\n", format(n, big.mark = ",")))
  cat(sprintf("  Sampling fraction      : %.4f%%\n", (n / N) * 100))
  cat(sprintf("  Simulations (B)        : %s\n", format(n_simulations, big.mark = ",")))
  cat("------------------------------------------------------------\n")
  cat(sprintf("  True parameter (theta) : %.6f\n", theta))
  cat(sprintf("  E(theta_hat)           : %.6f\n", e_hat))
  cat(sprintf("  Bias                   : %.6f\n", bias))
  cat(sprintf("  Variance               : %.6f\n", variance))
  cat(sprintf("  MSE                    : %.6f\n", mse))
  cat(sprintf("  RMSE                   : %.6f\n", rmse))
  cat(sprintf("  CV                     : %.2f%%\n", cv))
  cat(sprintf("  95%% Empirical CI       : [%.4f, %.4f]\n", ci_lower, ci_upper))
  cat("============================================================\n")

  invisible(list(
    theta = theta, e_hat = e_hat, bias = bias,
    variance = variance, mse = mse, cv = cv,
    estimates = estimates
  ))
}
```

## Usage

```r
pop <- rlnorm(50000, 7, 1)
result <- estimator_quality_report(pop, sample_size = 500)
```
