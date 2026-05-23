# ============================================================
# Lesson 0.3: Sampling Error vs Non-Sampling Error Mechanics
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Population setup ---
N <- 200000
income <- rlnorm(N, meanlog = 7.2, sdlog = 0.9)

# Non-response mechanism: lower income = less likely to respond
response_propensity <- plogis(-1.5 + 0.3 * scale(income))

theta <- mean(income)
cat(sprintf("True population mean: %.2f\n", theta))

# --- Experiment: vary sample size ---
sample_sizes <- c(100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000)
B <- 1000

results <- data.frame(
  n             = integer(0),
  sampling_rmse = numeric(0),
  nr_bias       = numeric(0),
  total_rmse    = numeric(0)
)

for (n in sample_sizes) {
  srs_estimates  <- numeric(B)
  nr_estimates   <- numeric(B)

  for (b in 1:B) {
    idx <- sample(1:N, n, replace = FALSE)

    # Scenario A: Full response (pure sampling error)
    srs_estimates[b] <- mean(income[idx])

    # Scenario B: Non-response mechanism
    responds <- rbinom(n, 1, response_propensity[idx])
    if (sum(responds) > 0) {
      nr_estimates[b] <- mean(income[idx[responds == 1]])
    } else {
      nr_estimates[b] <- NA
    }
  }

  nr_estimates <- nr_estimates[!is.na(nr_estimates)]

  results <- rbind(results, data.frame(
    n             = n,
    sampling_rmse = sqrt(mean((srs_estimates - theta)^2)),
    nr_bias       = abs(mean(nr_estimates) - theta),
    total_rmse    = sqrt(mean((nr_estimates - theta)^2))
  ))
}

# --- Display results ---
cat("\n============================================================\n")
cat("  SAMPLING ERROR vs NON-RESPONSE BIAS by Sample Size\n")
cat("============================================================\n")
cat(sprintf("%-10s | %-14s | %-14s | %-14s\n",
            "n", "Sampling RMSE", "NR Bias", "Total RMSE"))
cat(paste(rep("-", 60), collapse = ""), "\n")

for (i in 1:nrow(results)) {
  cat(sprintf("%-10s | %-14.2f | %-14.2f | %-14.2f\n",
              format(results$n[i], big.mark = ","),
              results$sampling_rmse[i],
              results$nr_bias[i],
              results$total_rmse[i]))
}

# --- Key assertions ---
for (i in 2:nrow(results)) {
  stopifnot(results$sampling_rmse[i] <= results$sampling_rmse[i-1] * 1.1)
}
cat("\n[PASS] Sampling error decreases with n.\n")

nr_bias_range <- range(results$nr_bias)
stopifnot(nr_bias_range[2] / nr_bias_range[1] < 3)
cat("[PASS] Non-response bias remains persistent across sample sizes.\n")

large_n_row <- results[results$n == max(results$n), ]
stopifnot(large_n_row$nr_bias > large_n_row$sampling_rmse)
cat("[PASS] At large n, bias dominates total error.\n")

# ============================================================
# Production: survey package comparison
# ============================================================
library(survey)

set.seed(2024)
N2 <- 50000
n2 <- 2000
pop2 <- data.frame(
  id     = 1:N2,
  income = rlnorm(N2, 7.2, 0.9),
  age    = sample(18:75, N2, replace = TRUE),
  urban  = rbinom(N2, 1, 0.6)
)

idx2 <- sample(1:N2, n2, replace = FALSE)
samp2 <- pop2[idx2, ]
samp2$response_prob <- plogis(-0.5 + 0.2 * scale(samp2$income))
samp2$responded <- rbinom(n2, 1, samp2$response_prob)

resp2 <- samp2[samp2$responded == 1, ]
resp2$weight <- N2 / nrow(resp2)

design2 <- svydesign(id = ~1, weights = ~weight, data = resp2)
est2 <- svymean(~income, design2)

cat(sprintf("\nNaive estimate (respondents only): %.2f\n", coef(est2)))
cat(sprintf("True population mean            : %.2f\n", mean(pop2$income)))
cat(sprintf("Difference                      : %.2f\n",
            coef(est2) - mean(pop2$income)))
