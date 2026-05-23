# ============================================================
# Lesson 0.2: Probability vs Non-Probability Sampling
# R — Simulation demonstrating bias in convenience sampling
# ============================================================

set.seed(2024)

# --- Create population with selection bias mechanism ---
N <- 100000

population <- data.frame(
  id           = 1:N,
  income       = rlnorm(N, meanlog = 7.0, sdlog = 1.0),
  has_internet = NA,
  stringsAsFactors = FALSE
)

# Internet access correlates with income (higher income = more likely online)
population$prob_online <- plogis(-3 + 0.5 * log(population$income))
population$has_internet <- rbinom(N, 1, population$prob_online)

# True population mean
theta <- mean(population$income)
cat(sprintf("True population mean income: %.2f\n", theta))
cat(sprintf("Internet access rate: %.1f%%\n",
            mean(population$has_internet) * 100))
cat(sprintf("Mean income (online only): %.2f\n",
            mean(population$income[population$has_internet == 1])))
cat(sprintf("Mean income (offline): %.2f\n",
            mean(population$income[population$has_internet == 0])))

# --- Simulation parameters ---
B <- 3000
n_prob <- 500      # Probability sample size
n_conv <- 5000     # Convenience sample size (10x larger!)

estimates_prob <- numeric(B)
estimates_conv <- numeric(B)

for (b in 1:B) {
  # --- Method 1: Simple Random Sampling (Probability) ---
  idx_srs <- sample(1:N, n_prob, replace = FALSE)
  estimates_prob[b] <- mean(population$income[idx_srs])

  # --- Method 2: Convenience / Online-only (Non-Probability) ---
  online_pop <- which(population$has_internet == 1)
  response_prob <- plogis(-2 + 0.3 * log(population$income[online_pop]))
  respondents <- online_pop[rbinom(length(online_pop), 1, response_prob) == 1]

  if (length(respondents) >= n_conv) {
    idx_conv <- sample(respondents, n_conv, replace = FALSE)
  } else {
    idx_conv <- respondents
  }
  estimates_conv[b] <- mean(population$income[idx_conv])
}

# --- Results ---
cat("\n============================================================\n")
cat("  COMPARISON: Probability vs Convenience Sampling\n")
cat("============================================================\n")

cat(sprintf("\n--- Probability Sampling (n = %d) ---\n", n_prob))
cat(sprintf("  E(theta_hat) : %.2f\n", mean(estimates_prob)))
cat(sprintf("  Bias         : %.2f\n", mean(estimates_prob) - theta))
cat(sprintf("  RMSE         : %.2f\n", sqrt(mean((estimates_prob - theta)^2))))

cat(sprintf("\n--- Convenience Sampling (n = %d) ---\n", n_conv))
cat(sprintf("  E(theta_hat) : %.2f\n", mean(estimates_conv)))
cat(sprintf("  Bias         : %.2f\n", mean(estimates_conv) - theta))
cat(sprintf("  RMSE         : %.2f\n", sqrt(mean((estimates_conv - theta)^2))))

# The key insight: convenience has LARGER error despite 10x sample
bias_prob <- abs(mean(estimates_prob) - theta)
bias_conv <- abs(mean(estimates_conv) - theta)

cat(sprintf("\n  Bias ratio (Conv/Prob): %.1fx\n", bias_conv / max(bias_prob, 0.01)))

# Assertions
stopifnot(bias_prob < 50)
stopifnot(bias_conv > 100)
cat("\n[PASS] Probability sampling produces unbiased estimates.\n")
cat("[PASS] Convenience sampling shows persistent bias.\n")
