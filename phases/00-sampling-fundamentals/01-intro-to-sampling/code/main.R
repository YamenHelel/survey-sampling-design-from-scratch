# ============================================================
# Lesson 0.1: Verifying Unbiasedness via Simulation
# R — From Scratch (No survey packages)
# ============================================================

set.seed(42)

# --- Generate a small population ---
N <- 10000
population <- data.frame(
  id     = 1:N,
  income = rlnorm(N, meanlog = 7.5, sdlog = 0.9)
)

# True population parameter (theta)
theta <- mean(population$income)
cat(sprintf("True population mean (theta): %.4f\n", theta))

# --- Repeated sampling experiment ---
n <- 200           # Sample size
B <- 5000          # Number of replications

estimates <- numeric(B)

for (b in 1:B) {
  idx <- sample(1:N, n, replace = FALSE)
  sample_data <- population$income[idx]
  estimates[b] <- mean(sample_data)
}

# --- Verify unbiasedness ---
expected_value <- mean(estimates)
bias <- expected_value - theta
variance_est <- var(estimates)
mse <- variance_est + bias^2

cat(sprintf("\n--- Simulation Results (B = %d) ---\n", B))
cat(sprintf("E(theta_hat)   : %.4f\n", expected_value))
cat(sprintf("theta (true)   : %.4f\n", theta))
cat(sprintf("Bias           : %.4f\n", bias))
cat(sprintf("Variance       : %.4f\n", variance_est))
cat(sprintf("MSE            : %.4f\n", mse))

# --- Theoretical variance under SRSWOR ---
S2 <- var(population$income)
theoretical_var <- (1 - n/N) * S2 / n
cat(sprintf("\nTheoretical Var: %.4f\n", theoretical_var))
cat(sprintf("Simulated Var  : %.4f\n", variance_est))
cat(sprintf("Ratio          : %.4f (should be ~1.0)\n",
            variance_est / theoretical_var))

# Assertion: bias should be negligible
stopifnot(abs(bias) < 0.5 * sqrt(theoretical_var))
cat("\n[PASS] Unbiasedness verified.\n")

# ============================================================
# Production: survey package comparison
# ============================================================

library(survey)

set.seed(42)
idx <- sample(1:N, n, replace = FALSE)
sample_data <- population[idx, ]

design <- svydesign(
  id      = ~1,
  fpc     = rep(N, n),
  data    = sample_data
)

est <- svymean(~income, design)
manual_mean <- mean(sample_data$income)

cat(sprintf("\nManual mean : %.4f\n", manual_mean))
cat(sprintf("svymean     : %.4f\n", coef(est)))

stopifnot(abs(coef(est) - manual_mean) < 1e-10)
cat("[PASS] Manual and survey package estimates match.\n")
