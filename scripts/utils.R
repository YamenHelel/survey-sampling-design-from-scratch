# ============================================================================
# utils.R
# Common Statistical Helper Functions for Survey Sampling Exercises
# ============================================================================
# Source this file at the top of any lesson script:
#   source("scripts/utils.R")
# ============================================================================

# --- 1. Descriptive Statistics Helpers ------------------------------------

#' Weighted mean with NA handling
#' @param x Numeric vector of values
#' @param w Numeric vector of weights
#' @return Weighted mean (scalar)
weighted_mean <- function(x, w) {
  valid <- !is.na(x) & !is.na(w)
  sum(x[valid] * w[valid]) / sum(w[valid])
}

#' Weighted variance (frequency weights)
#' @param x Numeric vector
#' @param w Numeric vector of weights
#' @return Weighted variance (scalar)
weighted_var <- function(x, w) {
  valid <- !is.na(x) & !is.na(w)
  xv <- x[valid]
  wv <- w[valid]
  mu <- sum(xv * wv) / sum(wv)
  sum(wv * (xv - mu)^2) / (sum(wv) - 1)
}

# --- 2. Sampling Utility Functions ----------------------------------------

#' Simple Random Sampling Without Replacement (SRSWOR)
#' @param frame_ids Character vector of unit IDs
#' @param n Sample size
#' @return Character vector of selected IDs
srswor <- function(frame_ids, n) {
  stopifnot(n <= length(frame_ids))
  frame_ids[sample.int(length(frame_ids), n, replace = FALSE)]
}

#' Systematic sampling with random start
#' @param frame_ids Ordered vector of unit IDs
#' @param n Number of units to select
#' @return Vector of selected IDs
systematic_sample <- function(frame_ids, n) {
  N <- length(frame_ids)
  stopifnot(n <= N)
  k <- N / n
  start <- runif(1, min = 1, max = k)
  indices <- floor(start + (0:(n - 1)) * k)
  indices <- pmin(indices, N)
  frame_ids[indices]
}

#' Cumulative total PPS selection (single draw)
#' @param sizes Numeric vector of size measures
#' @param n Number of PSUs to select
#' @return Integer vector of selected indices
pps_systematic <- function(sizes, n) {
  stopifnot(all(!is.na(sizes)), all(sizes > 0))
  N <- length(sizes)
  cumulative <- cumsum(sizes)
  total <- cumulative[N]
  interval <- total / n
  start <- runif(1, min = 0, max = interval)
  draw_points <- start + (0:(n - 1)) * interval

  selected <- integer(n)
  for (i in seq_along(draw_points)) {
    selected[i] <- min(which(cumulative >= draw_points[i]))
  }
  selected
}

# --- 3. Estimation Functions ----------------------------------------------

#' Horvitz-Thompson estimator for a total
#' @param y Numeric vector of observed values
#' @param pi_i Numeric vector of inclusion probabilities
#' @return Estimated total (scalar)
ht_total <- function(y, pi_i) {
  valid <- !is.na(y) & !is.na(pi_i)
  sum(y[valid] / pi_i[valid])
}

#' Horvitz-Thompson estimator for a mean
#' @param y Numeric vector of observed values
#' @param pi_i Numeric vector of inclusion probabilities
#' @param N Population size
#' @return Estimated mean (scalar)
ht_mean <- function(y, pi_i, N) {
  ht_total(y, pi_i) / N
}

#' Ratio estimator
#' @param y Numerator variable
#' @param x Denominator variable
#' @param w Weights (1/pi_i)
#' @return Ratio estimate (scalar)
ratio_estimator <- function(y, x, w) {
  valid <- !is.na(y) & !is.na(x) & !is.na(w)
  sum(w[valid] * y[valid]) / sum(w[valid] * x[valid])
}

# --- 4. Variance Estimation Helpers ---------------------------------------

#' Variance of HT total under SRSWOR
#' @param y Numeric vector of sample values
#' @param N Population size
#' @param n Sample size
#' @return Estimated variance of the total
var_ht_total_srs <- function(y, N, n) {
  fpc <- 1 - n / N
  N^2 * fpc * var(y, na.rm = TRUE) / n
}

#' Design Effect (Deff) computation
#' @param var_complex Variance under complex design
#' @param var_srs Variance under SRS of same size
#' @return Design effect (scalar)
compute_deff <- function(var_complex, var_srs) {
  stopifnot(var_srs > 0)
  var_complex / var_srs
}

#' Intraclass Correlation Coefficient (ICC / rho) via one-way ANOVA
#' @param y Numeric vector of values
#' @param cluster Factor or character vector of cluster IDs
#' @return ICC value (scalar)
compute_icc <- function(y, cluster) {
  valid <- !is.na(y) & !is.na(cluster)
  y <- y[valid]
  cluster <- as.factor(cluster[valid])

  grand_mean <- mean(y)
  clusters <- levels(cluster)
  k <- length(clusters)

  cluster_sizes <- table(cluster)
  m_bar <- mean(cluster_sizes)

  # Between-cluster variance (MSB)
  ssb <- sum(cluster_sizes * (tapply(y, cluster, mean) - grand_mean)^2)
  msb <- ssb / (k - 1)

  # Within-cluster variance (MSW)
  ssw <- sum((y - ave(y, cluster, FUN = mean))^2)
  n_total <- length(y)
  msw <- ssw / (n_total - k)

  # ICC
  rho <- (msb - msw) / (msb + (m_bar - 1) * msw)
  max(-1 / (m_bar - 1), rho)  # Bound ICC
}

# --- 5. Sample Size Functions ---------------------------------------------

#' Cochran's sample size formula for proportions
#' @param p Estimated proportion
#' @param e Margin of error
#' @param z Z-value for confidence level (default 1.96)
#' @param N Population size (NULL for infinite)
#' @param deff Design effect (default 1)
#' @param nr_rate Non-response rate (default 0)
#' @return Required sample size (integer)
cochran_n <- function(p, e, z = 1.96, N = NULL, deff = 1, nr_rate = 0) {
  stopifnot(p > 0, p < 1, e > 0, deff >= 1, nr_rate >= 0, nr_rate < 1)

  n0 <- (z^2 * p * (1 - p)) / e^2

  # Finite population correction
  if (!is.null(N)) {
    n0 <- n0 / (1 + (n0 - 1) / N)
  }

  # Adjust for design effect and non-response
  n_final <- n0 * deff / (1 - nr_rate)
  ceiling(n_final)
}

#' Cochran's sample size formula for means
#' @param sigma Population standard deviation estimate
#' @param e Margin of error
#' @param z Z-value (default 1.96)
#' @param N Population size (NULL for infinite)
#' @param deff Design effect (default 1)
#' @param nr_rate Non-response rate (default 0)
#' @return Required sample size (integer)
cochran_n_mean <- function(sigma, e, z = 1.96, N = NULL, deff = 1, nr_rate = 0) {
  stopifnot(sigma > 0, e > 0, deff >= 1, nr_rate >= 0, nr_rate < 1)

  n0 <- (z^2 * sigma^2) / e^2

  if (!is.null(N)) {
    n0 <- n0 / (1 + (n0 - 1) / N)
  }

  n_final <- n0 * deff / (1 - nr_rate)
  ceiling(n_final)
}

# --- 6. Weight Processing -------------------------------------------------

#' Trim extreme weights using percentile-based winsorization
#' @param w Numeric vector of weights
#' @param lower Lower percentile (default 0.01)
#' @param upper Upper percentile (default 0.99)
#' @return Trimmed weight vector
trim_weights <- function(w, lower = 0.01, upper = 0.99) {
  valid <- !is.na(w)
  bounds <- quantile(w[valid], probs = c(lower, upper))
  w[valid] <- pmin(pmax(w[valid], bounds[1]), bounds[2])
  w
}

#' Normalize weights to sum to population total
#' @param w Raw weights
#' @param pop_total Target population total
#' @return Normalized weights
normalize_weights <- function(w, pop_total) {
  valid <- !is.na(w)
  w[valid] <- w[valid] * (pop_total / sum(w[valid]))
  w
}

# --- 7. Diagnostic / Reporting Functions ----------------------------------

#' Print a formatted summary of sampling results
#' @param estimate Point estimate
#' @param se Standard error
#' @param ci_level Confidence level (default 0.95)
#' @param label Optional label string
print_estimate <- function(estimate, se, ci_level = 0.95, label = "Estimate") {
  z <- qnorm(1 - (1 - ci_level) / 2)
  ci_lower <- estimate - z * se
  ci_upper <- estimate + z * se
  cv <- (se / abs(estimate)) * 100

  cat(sprintf("\n--- %s ---\n", label))
  cat(sprintf("  Point Estimate : %.4f\n", estimate))
  cat(sprintf("  Standard Error : %.4f\n", se))
  cat(sprintf("  %.0f%% CI        : [%.4f, %.4f]\n", ci_level * 100, ci_lower, ci_upper))
  cat(sprintf("  CV             : %.2f%%\n", cv))
  cat("\n")
}

#' Coefficient of Variation
#' @param se Standard error
#' @param estimate Point estimate
#' @return CV as percentage
cv_pct <- function(se, estimate) {
  (se / abs(estimate)) * 100
}

cat("utils.R loaded successfully.\n")
