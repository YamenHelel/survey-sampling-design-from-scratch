# ============================================================
# Lesson 2.1: Stratified Random Sampling & Optimal Allocation
# R — From Scratch (No sampling libraries)
# ============================================================

set.seed(2024)

# --- Create stratified population ---
strata_params <- data.frame(
  stratum    = paste0("GOV_", sprintf("%02d", 1:6)),
  N_h        = c(200000, 80000, 70000, 100000, 60000, 90000),
  mean_inc   = c(2500, 1200, 1000, 1800, 900, 1500),
  sd_inc     = c(1500, 400, 300, 800, 250, 600),
  stringsAsFactors = FALSE
)

N <- sum(strata_params$N_h)
n_total <- 3000
H <- nrow(strata_params)

# Generate population
population <- data.frame()
for (h in 1:H) {
  pop_h <- data.frame(
    stratum = strata_params$stratum[h],
    income  = pmax(0, rnorm(strata_params$N_h[h],
                            strata_params$mean_inc[h],
                            strata_params$sd_inc[h])),
    stringsAsFactors = FALSE
  )
  population <- rbind(population, pop_h)
}

# True population mean
theta <- mean(population$income)
cat(sprintf("True population mean: %.2f\n", theta))

# --- Compute stratum statistics ---
stratum_stats <- data.frame(
  stratum = strata_params$stratum,
  N_h     = strata_params$N_h,
  stringsAsFactors = FALSE
)

for (h in 1:H) {
  mask <- population$stratum == strata_params$stratum[h]
  stratum_stats$mean_h[h] <- mean(population$income[mask])
  stratum_stats$var_h[h]  <- var(population$income[mask])
  stratum_stats$sd_h[h]   <- sd(population$income[mask])
}

stratum_stats$W_h <- stratum_stats$N_h / N

cat("\n--- Stratum Statistics ---\n")
print(stratum_stats[, c("stratum", "N_h", "W_h", "mean_h", "sd_h")])

# ============================================================
# ALLOCATION 1: PROPORTIONAL
# ============================================================

n_prop <- round(n_total * stratum_stats$W_h)
# Adjust to sum to n_total
n_prop[1] <- n_prop[1] + (n_total - sum(n_prop))
n_prop <- pmax(n_prop, 2)  # Minimum 2 per stratum

cat("\n--- Proportional Allocation ---\n")
cat(sprintf("  %-8s: n_h = %s\n", stratum_stats$stratum, n_prop))

# ============================================================
# ALLOCATION 2: NEYMAN OPTIMAL
# ============================================================

neyman_weights <- stratum_stats$N_h * stratum_stats$sd_h
neyman_weights <- neyman_weights / sum(neyman_weights)
n_neyman <- round(n_total * neyman_weights)
n_neyman[1] <- n_neyman[1] + (n_total - sum(n_neyman))
n_neyman <- pmax(n_neyman, 2)

cat("\n--- Neyman Optimal Allocation ---\n")
cat(sprintf("  %-8s: n_h = %s\n", stratum_stats$stratum, n_neyman))

# ============================================================
# SIMULATION: Compare allocations
# ============================================================

B <- 5000

estimate_stratified <- function(pop, strata_info, n_alloc) {
  est <- 0
  for (h in 1:nrow(strata_info)) {
    mask <- pop$stratum == strata_info$stratum[h]
    pop_h <- pop$income[mask]
    idx <- sample(length(pop_h), n_alloc[h], replace = FALSE)
    est <- est + strata_info$W_h[h] * mean(pop_h[idx])
  }
  est
}

estimates_prop   <- replicate(B, estimate_stratified(population, stratum_stats, n_prop))
estimates_neyman <- replicate(B, estimate_stratified(population, stratum_stats, n_neyman))

# SRS for comparison
estimates_srs <- replicate(B, mean(population$income[sample(N, n_total)]))

cat("\n============================================================\n")
cat("  ALLOCATION COMPARISON (B = 5000 replications)\n")
cat("============================================================\n")
cat(sprintf("  %-22s | %-12s | %-12s | %-10s\n",
            "Method", "E(estimate)", "Variance", "RMSE"))
cat(paste(rep("-", 65), collapse = ""), "\n")

methods <- list(
  list("SRS", estimates_srs),
  list("Stratified (Prop)", estimates_prop),
  list("Stratified (Neyman)", estimates_neyman)
)

for (m in methods) {
  est <- m[[2]]
  cat(sprintf("  %-22s | %12.2f | %12.2f | %10.2f\n",
              m[[1]], mean(est), var(est), sqrt(mean((est - theta)^2))))
}

# Gains
gain_prop   <- var(estimates_srs) / var(estimates_prop)
gain_neyman <- var(estimates_srs) / var(estimates_neyman)

cat(sprintf("\n  Stratification gain (Proportional): %.2fx\n", gain_prop))
cat(sprintf("  Stratification gain (Neyman)      : %.2fx\n", gain_neyman))

# Assertions
stopifnot(var(estimates_neyman) <= var(estimates_prop) * 1.05)
cat("\n[PASS] Neyman allocation achieves lower variance than proportional.\n")

stopifnot(var(estimates_prop) <= var(estimates_srs) * 1.05)
cat("[PASS] Stratification improves over SRS.\n")

stopifnot(abs(mean(estimates_neyman) - theta) < 5)
cat("[PASS] Neyman estimator is unbiased.\n")
# ============================================================
# Lesson 2.1: Stratified Sampling with the sampling package
# ============================================================

library(sampling)
library(survey)

set.seed(2024)

# Use the same population from the scratch code
# ... (population generation code same as above) ...

N <- 600000
strata_N <- c(200000, 80000, 70000, 100000, 60000, 90000)
strata_names <- paste0("GOV_", sprintf("%02d", 1:6))

population <- data.frame(
  stratum = rep(strata_names, strata_N),
  income  = c(
    pmax(0, rnorm(200000, 2500, 1500)),
    pmax(0, rnorm(80000, 1200, 400)),
    pmax(0, rnorm(70000, 1000, 300)),
    pmax(0, rnorm(100000, 1800, 800)),
    pmax(0, rnorm(60000, 900, 250)),
    pmax(0, rnorm(90000, 1500, 600))
  ),
  stringsAsFactors = FALSE
)

theta <- mean(population$income)

# Neyman allocation using sampling package
stratum_sds <- tapply(population$income, population$stratum, sd)
stratum_Ns  <- tapply(population$income, population$stratum, length)

n_total <- 3000
n_neyman_pkg <- round(n_total * stratum_Ns * stratum_sds /
                        sum(stratum_Ns * stratum_sds))

# Draw stratified sample
population$row_id <- 1:nrow(population)
s <- strata(population, stratanames = "stratum",
            size = n_neyman_pkg[order(names(n_neyman_pkg))],
            method = "srswor")

sample_data <- getdata(population, s)
sample_data$fpc <- stratum_Ns[sample_data$stratum]

# Estimate with survey package
design <- svydesign(id = ~1, strata = ~stratum,
                    fpc = ~fpc, data = sample_data)
est <- svymean(~income, design)

cat(sprintf("survey::svymean  : %.4f (SE = %.4f)\n", coef(est), SE(est)))

# Manual verification
manual_est <- sum(tapply(sample_data$income, sample_data$stratum, mean) *
                    (stratum_Ns / N)[names(tapply(sample_data$income,
                                                   sample_data$stratum, mean))])

cat(sprintf("Manual estimate  : %.4f\n", manual_est))
stopifnot(abs(coef(est) - manual_est) < 0.01)
cat("[PASS] Manual matches survey package to 4 decimals.\n")
# ============================================================
# PRODUCTION: stratified_sampler.R
# Automated stratified sample allocation and selection
# ============================================================

stratified_sampler <- function(frame,
                                stratum_col,
                                size_col = NULL,
                                target_var = NULL,
                                n_total,
                                method = c("proportional", "neyman", "equal"),
                                min_per_stratum = 2,
                                seed = NULL) {

  method <- match.arg(method)
  if (!is.null(seed)) set.seed(seed)

  strata <- unique(frame[[stratum_col]])
  H <- length(strata)

  # Compute stratum sizes
  N_h <- table(frame[[stratum_col]])
  W_h <- N_h / sum(N_h)

  # Compute allocation
  if (method == "proportional") {
    n_h <- round(n_total * W_h)
  } else if (method == "neyman" && !is.null(target_var)) {
    sd_h <- tapply(frame[[target_var]], frame[[stratum_col]], sd, na.rm = TRUE)
    weights <- N_h * sd_h
    n_h <- round(n_total * weights / sum(weights))
  } else {
    n_h <- rep(round(n_total / H), H)
  }

  # Enforce minimum
  n_h <- pmax(n_h, min_per_stratum)
  # Enforce maximum (can't exceed stratum size)
  n_h <- pmin(n_h, N_h)
  # Adjust to hit target
  n_h[which.max(N_h)] <- n_h[which.max(N_h)] + (n_total - sum(n_h))

  # Select sample
  sample_rows <- data.frame()
  for (h in names(N_h)) {
    stratum_data <- frame[frame[[stratum_col]] == h, ]
    idx <- sample(1:nrow(stratum_data), n_h[h], replace = FALSE)
    selected <- stratum_data[idx, ]
    selected$inclusion_prob <- n_h[h] / N_h[h]
    selected$base_weight <- N_h[h] / n_h[h]
    sample_rows <- rbind(sample_rows, selected)
  }

  cat(sprintf("\nStratified Sample Selected (method = %s)\n", method))
  cat(sprintf("Total n = %d from N = %s\n",
              nrow(sample_rows), format(sum(N_h), big.mark = ",")))

  sample_rows
}
