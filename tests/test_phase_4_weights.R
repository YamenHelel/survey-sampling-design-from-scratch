# ============================================================================
# test_phase_4_weights.R
# Unit Tests: Weighting Pipeline (Phase 4)
# ============================================================================
# Validates weight computations: base weights, NR adjustment, calibration.
#
# Usage: Rscript tests/test_phase_4_weights.R
# ============================================================================

cat("============================================================\n")
cat("  UNIT TESTS: Phase 4 — Weighting Pipeline\n")
cat("============================================================\n\n")

library(survey)

set.seed(2024)
tests_passed <- 0
tests_failed <- 0

assert_equal <- function(actual, expected, tol = 1e-4, msg = "") {
  if (abs(actual - expected) <= tol) {
    tests_passed <<- tests_passed + 1
    cat(sprintf("  [PASS] %s\n", msg))
  } else {
    tests_failed <<- tests_failed + 1
    cat(sprintf("  [FAIL] %s (actual=%.6f, expected=%.6f, diff=%.6f)\n",
                msg, actual, expected, abs(actual - expected)))
  }
}

# ============================================================
# TEST 1: Base Weight = 1 / pi_i
# ============================================================

cat("--- Test 1: Base Weight Computation ---\n")

# Two-stage PPS design
n_eas <- 500
ea_sizes <- pmax(50, rpois(n_eas, 120))
M_total <- sum(ea_sizes)
a <- 50
b <- 15

# PPS probabilities
pi_1 <- a * ea_sizes / M_total

# For a self-weighting design:
# w_ij = (M_total / (a * M_i)) * (M_i / b) = M_total / (a * b)
expected_w <- M_total / (a * b)

# Simulate for selected PSUs
cumul <- cumsum(ea_sizes)
interval <- M_total / a
R <- runif(1, 0, interval)
sel_pts <- R + (0:(a-1)) * interval
sel_idx <- sapply(sel_pts, function(sp) min(which(cumul >= sp)))

w_stage1 <- M_total / (a * ea_sizes[sel_idx])
w_stage2 <- ea_sizes[sel_idx] / b
w_total <- w_stage1 * w_stage2

# Check constant
assert_equal(sd(w_total), 0, tol = 0.001,
             msg = "Self-weighting: SD of weights ≈ 0")
assert_equal(mean(w_total), expected_w, tol = 0.01,
             msg = "Mean weight = M_total / (a*b)")

# Check sum
weight_sum <- sum(w_total * b)  # Each PSU has b HH
assert_equal(weight_sum / M_total, 1, tol = 0.01,
             msg = "Sum of weights ≈ population total")

# ============================================================
# TEST 2: NR Adjustment Preserves Population Total
# ============================================================

cat("\n--- Test 2: Non-Response Weight Adjustment ---\n")

n_sample <- 1000
sample_df <- data.frame(
  id         = 1:n_sample,
  urban      = rbinom(n_sample, 1, 0.6),
  age_group  = sample(c("young", "middle", "old"), n_sample, replace = TRUE),
  base_weight = 200,
  stringsAsFactors = FALSE
)

# Non-response
resp_prob <- ifelse(sample_df$urban == 1, 0.75, 0.90) *
             ifelse(sample_df$age_group == "young", 0.70, 1.0)
sample_df$responded <- rbinom(n_sample, 1, pmin(resp_prob, 0.95))

target_N <- n_sample * 200

# Weighting class adjustment
sample_df$wt_class <- paste(sample_df$urban, sample_df$age_group, sep = "_")

resp_df <- sample_df[sample_df$responded == 1, ]
resp_df$adj_weight <- resp_df$base_weight

for (cls in unique(sample_df$wt_class)) {
  total_w <- sum(sample_df$base_weight[sample_df$wt_class == cls])
  resp_w <- sum(resp_df$base_weight[resp_df$wt_class == cls])
  if (resp_w > 0) {
    factor <- total_w / resp_w
    resp_df$adj_weight[resp_df$wt_class == cls] <-
      resp_df$adj_weight[resp_df$wt_class == cls] * factor
  }
}

adj_sum <- sum(resp_df$adj_weight)
assert_equal(adj_sum / target_N, 1, tol = 0.01,
             msg = "NR adjusted weights sum to population total")

# Adjusted weights should be >= base weights
if (all(resp_df$adj_weight >= resp_df$base_weight - 0.01)) {
  tests_passed <- tests_passed + 1
  cat("  [PASS] All adjusted weights >= base weights\n")
} else {
  tests_failed <- tests_failed + 1
  cat("  [FAIL] Some adjusted weights < base weights\n")
}

# ============================================================
# TEST 3: IPF/Raking Convergence
# ============================================================

cat("\n--- Test 3: Raking (IPF) Convergence ---\n")

n <- 2000
rk_df <- data.frame(
  sex    = sample(c("M", "F"), n, replace = TRUE, prob = c(0.55, 0.45)),
  region = sample(c("Urban", "Rural"), n, replace = TRUE, prob = c(0.65, 0.35)),
  weight = 100
)

N_pop <- n * 100
margins <- list(
  sex    = c(M = 0.48 * N_pop, F = 0.52 * N_pop),
  region = c(Urban = 0.55 * N_pop, Rural = 0.45 * N_pop)
)

w <- rk_df$weight
converged <- FALSE

for (iter in 1:200) {
  max_diff <- 0
  for (var_name in names(margins)) {
    for (cat_name in names(margins[[var_name]])) {
      mask <- rk_df[[var_name]] == cat_name
      current <- sum(w[mask])
      target <- margins[[var_name]][cat_name]
      if (current > 0) {
        f <- target / current
        w[mask] <- w[mask] * f
        max_diff <- max(max_diff, abs(f - 1))
      }
    }
  }
  if (max_diff < 0.0001) {
    converged <- TRUE
    break
  }
}

if (converged) {
  tests_passed <- tests_passed + 1
  cat(sprintf("  [PASS] IPF converged in %d iterations\n", iter))
} else {
  tests_failed <- tests_failed + 1
  cat("  [FAIL] IPF did not converge\n")
}

# Check all margins match
for (var_name in names(margins)) {
  for (cat_name in names(margins[[var_name]])) {
    mask <- rk_df[[var_name]] == cat_name
    actual <- sum(w[mask])
    target <- margins[[var_name]][cat_name]
    assert_equal(actual / target, 1, tol = 0.001,
                 msg = sprintf("Margin %s/%s", var_name, cat_name))
  }
}

# ============================================================
# TEST 4: Raking vs survey::calibrate
# ============================================================

cat("\n--- Test 4: Manual Raking vs survey::calibrate ---\n")

design_init <- svydesign(id = ~1, weights = ~weight, data = rk_df)

pop_totals <- c(
  `(Intercept)` = N_pop,
  sexM = margins$sex["M"],
  regionUrban = margins$region["Urban"]
)

design_cal <- calibrate(design_init,
                         formula = ~sex + region,
                         population = pop_totals,
                         calfun = "raking")

# Compare calibrated weight sums
cal_weights_pkg <- weights(design_cal)

# Manual raked weights already in w
manual_total <- sum(w)
pkg_total <- sum(cal_weights_pkg)

assert_equal(manual_total, pkg_total, tol = 1,
             msg = "Total weight: manual raking vs survey::calibrate")

# Check sex margin
manual_M <- sum(w[rk_df$sex == "M"])
pkg_M <- sum(cal_weights_pkg[rk_df$sex == "M"])

assert_equal(manual_M, pkg_M, tol = 10,
             msg = "Male total: manual vs calibrate")

# ============================================================
# TEST 5: Weight Trimming
# ============================================================

cat("\n--- Test 5: Weight Trimming ---\n")

extreme_w <- c(rlnorm(980, 5, 0.5), rlnorm(20, 8, 1))  # Some extreme weights
original_sum <- sum(extreme_w)

# Trim at 1st and 99th percentile
bounds <- quantile(extreme_w, c(0.01, 0.99))
trimmed_w <- pmin(pmax(extreme_w, bounds[1]), bounds[2])

# Normalize to preserve sum
trimmed_w <- trimmed_w * (original_sum / sum(trimmed_w))

assert_equal(sum(trimmed_w), original_sum, tol = 1,
             msg = "Trimmed weights preserve total")

if (sd(trimmed_w) < sd(extreme_w)) {
  tests_passed <- tests_passed + 1
  cat("  [PASS] Trimming reduces weight variability\n")
} else {
  tests_failed <- tests_failed + 1
  cat("  [FAIL] Trimming did not reduce variability\n")
}

# ============================================================
# SUMMARY
# ============================================================

cat("\n============================================================\n")
cat(sprintf("  RESULTS: %d passed, %d failed\n", tests_passed, tests_failed))
cat("============================================================\n")

if (tests_failed > 0) {
  stop(sprintf("%d test(s) failed!", tests_failed))
} else {
  cat("  ALL TESTS PASSED\n")
}
