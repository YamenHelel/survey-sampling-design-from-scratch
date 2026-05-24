# ============================================================
# Lesson 3.1: Cochran's Formula Extensions
# R — From Scratch (No specialized packages)
# ============================================================

# --- Core function: sample size for proportions ---
cochran_proportion <- function(p, e, z = 1.96, N = NULL,
                                deff = 1, nr_rate = 0) {
  stopifnot(p > 0 && p < 1)
  stopifnot(e > 0)
  stopifnot(deff >= 1)
  stopifnot(nr_rate >= 0 && nr_rate < 1)

  # Step 1: Base (infinite population)
  n0 <- (z^2 * p * (1 - p)) / e^2

  # Step 2: Finite population correction
  if (!is.null(N) && N > 0) {
    n_fpc <- n0 / (1 + (n0 - 1) / N)
  } else {
    n_fpc <- n0
  }

  # Step 3: Design effect adjustment
  n_deff <- n_fpc * deff

  # Step 4: Non-response adjustment
  n_final <- n_deff / (1 - nr_rate)

  list(
    n0      = ceiling(n0),
    n_fpc   = ceiling(n_fpc),
    n_deff  = ceiling(n_deff),
    n_final = ceiling(n_final),
    components = data.frame(
      step = c("Base (Cochran)", "After FPC", "After Deff", "After NR"),
      n    = ceiling(c(n0, n_fpc, n_deff, n_final))
    )
  )
}

# --- Core function: sample size for means ---
cochran_mean <- function(sigma, e, z = 1.96, N = NULL,
                          deff = 1, nr_rate = 0) {
  stopifnot(sigma > 0 && e > 0 && deff >= 1)
  stopifnot(nr_rate >= 0 && nr_rate < 1)

  n0 <- (z^2 * sigma^2) / e^2

  if (!is.null(N) && N > 0) {
    n_fpc <- n0 / (1 + (n0 - 1) / N)
  } else {
    n_fpc <- n0
  }

  n_final <- ceiling(n_fpc * deff / (1 - nr_rate))
  n_final
}

# ============================================================
# SCENARIO: National Poverty Survey
# ============================================================

cat("============================================================\n")
cat("  SAMPLE SIZE CALCULATION: National Poverty Survey\n")
cat("============================================================\n\n")

result <- cochran_proportion(
  p       = 0.25,      # Expected poverty rate ~25%
  e       = 0.02,      # Margin of error ±2%
  z       = 1.96,      # 95% confidence
  N       = 2000000,   # Population size
  deff    = 2.5,        # Cluster design effect
  nr_rate = 0.15        # 15% non-response
)

cat("--- Step-by-step computation ---\n")
print(result$components)
cat(sprintf("\nFinal required sample size: %s households\n",
            format(result$n_final, big.mark = ",")))

# ============================================================
# SENSITIVITY ANALYSIS
# ============================================================

cat("\n--- Sensitivity to key parameters ---\n\n")

# Vary Deff
cat("Effect of Design Effect (Deff):\n")
for (d in c(1.0, 1.5, 2.0, 2.5, 3.0, 4.0)) {
  r <- cochran_proportion(0.25, 0.02, N = 2e6, deff = d, nr_rate = 0.15)
  cat(sprintf("  Deff = %.1f -> n = %s\n", d,
              format(r$n_final, big.mark = ",")))
}

# Vary margin of error
cat("\nEffect of margin of error (e):\n")
for (e in c(0.01, 0.015, 0.02, 0.03, 0.05)) {
  r <- cochran_proportion(0.25, e, N = 2e6, deff = 2.5, nr_rate = 0.15)
  cat(sprintf("  e = %.1f%% -> n = %s\n", e * 100,
              format(r$n_final, big.mark = ",")))
}

# Vary non-response rate
cat("\nEffect of non-response rate:\n")
for (nr in c(0.05, 0.10, 0.15, 0.20, 0.30)) {
  r <- cochran_proportion(0.25, 0.02, N = 2e6, deff = 2.5, nr_rate = nr)
  cat(sprintf("  NR = %.0f%% -> n = %s\n", nr * 100,
              format(r$n_final, big.mark = ",")))
}

# ============================================================
# DOMAIN-LEVEL ESTIMATION
# ============================================================

cat("\n============================================================\n")
cat("  DOMAIN-LEVEL SAMPLE SIZE (12 Governorates)\n")
cat("============================================================\n\n")

domains <- data.frame(
  domain = paste0("GOV_", sprintf("%02d", 1:12)),
  N_d    = c(500000, 200000, 180000, 250000, 150000,
             120000, 100000, 130000, 90000, 80000, 110000, 90000),
  p_d    = c(0.15, 0.30, 0.35, 0.20, 0.40,
             0.25, 0.22, 0.28, 0.45, 0.50, 0.18, 0.38),
  stringsAsFactors = FALSE
)

domains$n_d <- NA
for (i in 1:nrow(domains)) {
  r <- cochran_proportion(
    p = domains$p_d[i], e = 0.05, N = domains$N_d[i],
    deff = 2.5, nr_rate = 0.15
  )
  domains$n_d[i] <- r$n_final
}

cat(sprintf("%-8s | %10s | %6s | %8s\n", "Domain", "N_d", "p_d", "n_d"))
cat(paste(rep("-", 42), collapse = ""), "\n")
for (i in 1:nrow(domains)) {
  cat(sprintf("%-8s | %10s | %6.2f | %8s\n",
              domains$domain[i],
              format(domains$N_d[i], big.mark = ","),
              domains$p_d[i],
              format(domains$n_d[i], big.mark = ",")))
}

cat(sprintf("\nTotal sample (all domains): %s\n",
            format(sum(domains$n_d), big.mark = ",")))

# ============================================================
# VERIFICATION via simulation
# ============================================================

cat("\n--- Verification: does the computed n achieve target precision? ---\n")

set.seed(2024)
N_sim <- 200000
pop <- rbinom(N_sim, 1, 0.25)  # 25% poverty rate
theta <- mean(pop)

n_calc <- cochran_proportion(0.25, 0.02, N = N_sim, deff = 1, nr_rate = 0)
n_test <- n_calc$n_final

B <- 5000
estimates <- numeric(B)
for (b in 1:B) {
  idx <- sample(N_sim, n_test, replace = FALSE)
  estimates[b] <- mean(pop[idx])
}

achieved_se <- sd(estimates)
achieved_moe <- 1.96 * achieved_se
target_moe <- 0.02

cat(sprintf("  Target MoE      : %.4f\n", target_moe))
cat(sprintf("  Achieved MoE    : %.4f\n", achieved_moe))
cat(sprintf("  n used          : %d\n", n_test))

stopifnot(achieved_moe <= target_moe * 1.15)
cat("[PASS] Computed n achieves target precision (within 15% tolerance).\n")
# ============================================================
# Lesson 3.1: Power analysis verification with survey package
# ============================================================

library(survey)

set.seed(2024)

# Simulate a clustered population to verify Deff-adjusted sample size
N_pop <- 200000
n_clusters <- 2000
cluster_size <- N_pop / n_clusters

# Generate clustered data (poverty indicator)
cluster_rates <- rbeta(n_clusters, 2, 6)  # Varying cluster poverty rates
pop_data <- data.frame(
  cluster_id = rep(1:n_clusters, each = cluster_size),
  poverty    = unlist(lapply(cluster_rates, function(p)
    rbinom(cluster_size, 1, p)))
)

true_rate <- mean(pop_data$poverty)

# Draw two-stage sample
a <- 100  # PSUs
b <- 15   # HH per PSU
selected_clusters <- sample(1:n_clusters, a, replace = FALSE)

sample_list <- list()
for (i in seq_along(selected_clusters)) {
  cl <- selected_clusters[i]
  cl_data <- pop_data[pop_data$cluster_id == cl, ]
  idx <- sample(1:nrow(cl_data), min(b, nrow(cl_data)))
  s <- cl_data[idx, ]
  s$weight <- (n_clusters / a) * (cluster_size / b)
  s$psu_id <- i
  sample_list[[i]] <- s
}
sample_df <- do.call(rbind, sample_list)

# Survey design
design <- svydesign(id = ~psu_id, weights = ~weight, data = sample_df)
est <- svymean(~poverty, design)
deff_est <- deff(svymean(~poverty, design))

cat(sprintf("True poverty rate : %.4f\n", true_rate))
cat(sprintf("Estimated rate    : %.4f (SE: %.4f)\n", coef(est), SE(est)))
cat(sprintf("Estimated Deff    : %.2f\n", deff_est))

# Verify our formula gives adequate n
our_n <- cochran_proportion(
  p = coef(est), e = 0.02, N = N_pop,
  deff = as.numeric(deff_est), nr_rate = 0.15
)
cat(sprintf("Required n (our formula): %s\n",
            format(our_n$n_final, big.mark = ",")))
