# ============================================================================
# test_phase_2_sampling.R
# Unit Tests: Probability Sampling Designs (Phase 2)
# ============================================================================
# Validates that from-scratch implementations produce results matching
# the survey/sampling R packages to 4 decimal places.
#
# Usage: Rscript tests/test_phase_2_sampling.R
# ============================================================================

cat("============================================================\n")
cat("  UNIT TESTS: Phase 2 — Probability Sampling Designs\n")
cat("============================================================\n\n")

library(survey)
library(sampling)

set.seed(2024)
tests_passed <- 0
tests_failed <- 0

# Helper: assert with message
assert_equal <- function(actual, expected, tol = 1e-4, msg = "") {
  if (abs(actual - expected) <= tol) {
    tests_passed <<- tests_passed + 1
    cat(sprintf("  [PASS] %s (actual=%.6f, expected=%.6f)\n", msg, actual, expected))
  } else {
    tests_failed <<- tests_failed + 1
    cat(sprintf("  [FAIL] %s (actual=%.6f, expected=%.6f, diff=%.6f)\n",
                msg, actual, expected, abs(actual - expected)))
  }
}

# ============================================================
# TEST 1: Stratified Random Sampling — Point Estimate
# ============================================================

cat("\n--- Test 1: Stratified Sampling Point Estimate ---\n")

# Create small population
N_strata <- c(A = 5000, B = 3000, C = 2000)
N <- sum(N_strata)
pop <- data.frame(
  stratum = rep(names(N_strata), N_strata),
  income  = c(rnorm(5000, 3000, 800), rnorm(3000, 1500, 400), rnorm(2000, 2000, 600)),
  stringsAsFactors = FALSE
)

# Proportional allocation
n_total <- 500
n_alloc <- round(n_total * N_strata / N)
n_alloc[1] <- n_alloc[1] + (n_total - sum(n_alloc))

# Draw stratified sample
sample_rows <- data.frame()
for (s in names(N_strata)) {
  s_pop <- pop[pop$stratum == s, ]
  idx <- sample(1:nrow(s_pop), n_alloc[s])
  s_sample <- s_pop[idx, ]
  s_sample$fpc <- N_strata[s]
  s_sample$weight <- N_strata[s] / n_alloc[s]
  sample_rows <- rbind(sample_rows, s_sample)
}

# Manual estimate
W_h <- N_strata / N
manual_means <- tapply(sample_rows$income, sample_rows$stratum, mean)
manual_est <- sum(W_h[names(manual_means)] * manual_means)

# survey package estimate
design <- svydesign(id = ~1, strata = ~stratum, fpc = ~fpc,
                    weights = ~weight, data = sample_rows)
pkg_est <- coef(svymean(~income, design))

assert_equal(manual_est, pkg_est, tol = 1e-8,
             msg = "Stratified mean: manual vs survey package")

# ============================================================
# TEST 2: PPS Inclusion Probabilities
# ============================================================

cat("\n--- Test 2: PPS Inclusion Probabilities ---\n")

frame_sizes <- rpois(500, 120)
frame_sizes <- pmax(frame_sizes, 20)
a <- 50

# Manual PPS probabilities
M_total <- sum(frame_sizes)
manual_pi <- a * frame_sizes / M_total

# sampling package probabilities
pkg_pi <- inclusionprobabilities(frame_sizes, a)

max_pi_diff <- max(abs(manual_pi - pkg_pi))
assert_equal(max_pi_diff, 0, tol = 1e-10,
             msg = "PPS inclusion probs: manual vs sampling::inclusionprobabilities")

# Sum of pi should equal a
assert_equal(sum(manual_pi), a, tol = 1e-8,
             msg = "Sum of inclusion probabilities equals n")

# ============================================================
# TEST 3: Horvitz-Thompson Total Estimator
# ============================================================

cat("\n--- Test 3: Horvitz-Thompson Total ---\n")

# Select via systematic PPS
s <- UPsystematic(pkg_pi)
selected <- which(s == 1)

# Generate y values
pop_y <- rnorm(500, 100, 20)
sample_y <- pop_y[selected]
sample_pi <- pkg_pi[selected]

# Manual HT total
manual_ht <- sum(sample_y / sample_pi)

# survey package HT
ht_data <- data.frame(y = sample_y, pi = sample_pi, weight = 1 / sample_pi)
design_ht <- svydesign(id = ~1, weights = ~weight, data = ht_data)
pkg_ht <- coef(svytotal(~y, design_ht))

assert_equal(manual_ht, pkg_ht, tol = 1e-6,
             msg = "HT total: manual vs survey::svytotal")

# ============================================================
# TEST 4: Self-Weighting Property
# ============================================================

cat("\n--- Test 4: Self-Weighting Design ---\n")

# Two-stage: PPS (stage 1) + SRS within (stage 2)
a_test <- 30
b_test <- 10
test_sizes <- rpois(200, 100)
test_sizes <- pmax(test_sizes, 50)
M_test <- sum(test_sizes)

# PPS selection
cumul <- cumsum(test_sizes)
interval <- M_test / a_test
R <- runif(1, 0, interval)
sel_pts <- R + (0:(a_test-1)) * interval
sel_psu <- sapply(sel_pts, function(sp) min(which(cumul >= sp)))

# Compute overall weight for each HH
pi1 <- a_test * test_sizes[sel_psu] / M_test
pi2 <- b_test / test_sizes[sel_psu]
w_overall <- 1 / (pi1 * pi2)

expected_w <- M_test / (a_test * b_test)
cv_w <- sd(w_overall) / mean(w_overall)

assert_equal(cv_w, 0, tol = 0.001,
             msg = "Self-weighting CV (should be ~0)")
assert_equal(mean(w_overall), expected_w, tol = 0.01,
             msg = "Mean weight equals M/(a*b)")

# ============================================================
# TEST 5: Neyman Allocation Optimality
# ============================================================

cat("\n--- Test 5: Neyman Allocation Optimality ---\n")

# Verify Neyman produces lower variance than proportional
strata_info <- data.frame(
  stratum = c("S1", "S2", "S3"),
  N_h     = c(10000, 5000, 3000),
  sd_h    = c(1000, 200, 500)
)
n_test <- 400

# Proportional
n_prop <- round(n_test * strata_info$N_h / sum(strata_info$N_h))

# Neyman
neyman_w <- strata_info$N_h * strata_info$sd_h
n_neyman <- round(n_test * neyman_w / sum(neyman_w))

# Theoretical variances
W_h <- strata_info$N_h / sum(strata_info$N_h)
var_prop <- sum(W_h^2 * strata_info$sd_h^2 / n_prop)
var_neyman <- sum(W_h^2 * strata_info$sd_h^2 / n_neyman)

if (var_neyman <= var_prop) {
  tests_passed <- tests_passed + 1
  cat(sprintf("  [PASS] Neyman variance (%.2f) <= Proportional (%.2f)\n",
              var_neyman, var_prop))
} else {
  tests_failed <- tests_failed + 1
  cat(sprintf("  [FAIL] Neyman variance (%.2f) > Proportional (%.2f)\n",
              var_neyman, var_prop))
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
