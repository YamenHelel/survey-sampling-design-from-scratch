# ============================================================
# Lesson 2.3: Two-Stage Cluster Sampling Engine
# R — From Scratch (No survey/sampling packages)
# ============================================================

set.seed(2024)

# ============================================================
# STAGE 0: Generate population frame
# ============================================================

n_eas <- 4500
ea_sizes <- pmax(50, rpois(n_eas, lambda = 120))

# Generate household-level data within each EA
population <- data.frame()
for (i in 1:n_eas) {
  ea_data <- data.frame(
    ea_id    = sprintf("EA_%04d", i),
    ea_size  = ea_sizes[i],
    hh_id    = sprintf("EA_%04d_HH_%03d", i, 1:ea_sizes[i]),
    income   = pmax(0, rnorm(ea_sizes[i],
                              mean = rnorm(1, 1500, 500),
                              sd = abs(rnorm(1, 400, 100)))),
    employed = rbinom(ea_sizes[i], 1, prob = runif(1, 0.3, 0.8)),
    stringsAsFactors = FALSE
  )
  population <- rbind(population, ea_data)
}

N <- nrow(population)
theta_income <- mean(population$income)
theta_employ <- mean(population$employed)

cat(sprintf("Population size (N): %s\n", format(N, big.mark = ",")))
cat(sprintf("Number of EAs     : %d\n", n_eas))
cat(sprintf("True mean income  : %.2f\n", theta_income))
cat(sprintf("True employment   : %.4f (%.1f%%)\n",
            theta_employ, theta_employ * 100))

# ============================================================
# STAGE 1: PPS Systematic Selection of PSUs
# ============================================================

a <- 180  # PSUs to select
b <- 15   # HH per PSU

cat(sprintf("\n--- Stage 1: Select %d PSUs via PPS ---\n", a))

cumulative <- cumsum(ea_sizes)
M_total <- sum(ea_sizes)
interval <- M_total / a
R <- runif(1, 0, interval)
sel_points <- R + (0:(a-1)) * interval

selected_psu_idx <- integer(a)
for (k in 1:a) {
  selected_psu_idx[k] <- min(which(cumulative >= sel_points[k]))
}

# Stage 1 inclusion probabilities
pi_1 <- a * ea_sizes[selected_psu_idx] / M_total

cat(sprintf("  PSUs selected: %d\n", a))
cat(sprintf("  Pi_1 range   : [%.4f, %.4f]\n", min(pi_1), max(pi_1)))

# ============================================================
# STAGE 2: Systematic Random Sampling of HH within PSUs
# ============================================================

cat(sprintf("\n--- Stage 2: Select %d HH per PSU ---\n", b))

sample_data <- data.frame()

for (k in 1:a) {
  psu_id <- sprintf("EA_%04d", selected_psu_idx[k])

  # Get all HH in this PSU
  psu_hh <- population[population$ea_id == psu_id, ]
  M_i <- nrow(psu_hh)

  # Systematic sampling within PSU
  step <- M_i / b
  start <- runif(1, 1, step)
  hh_indices <- floor(start + (0:(b-1)) * step)
  hh_indices <- pmin(hh_indices, M_i)

  selected_hh <- psu_hh[hh_indices, ]

  # Stage 2 inclusion probability
  pi_2 <- b / M_i

  # Overall inclusion probability and weight
  selected_hh$pi_1 <- pi_1[k]
  selected_hh$pi_2 <- pi_2
  selected_hh$pi_overall <- pi_1[k] * pi_2
  selected_hh$weight <- 1 / (pi_1[k] * pi_2)
  selected_hh$psu_order <- k

  sample_data <- rbind(sample_data, selected_hh)
}

cat(sprintf("  Total HH selected: %d\n", nrow(sample_data)))
cat(sprintf("  Weight range     : [%.2f, %.2f]\n",
            min(sample_data$weight), max(sample_data$weight)))

# ============================================================
# ESTIMATION
# ============================================================

cat("\n--- ESTIMATION ---\n")

# Weighted mean income
est_income <- sum(sample_data$weight * sample_data$income) /
              sum(sample_data$weight)

# Weighted employment rate
est_employ <- sum(sample_data$weight * sample_data$employed) /
              sum(sample_data$weight)

cat(sprintf("  Est. mean income : %.2f (true: %.2f, diff: %.2f)\n",
            est_income, theta_income, est_income - theta_income))
cat(sprintf("  Est. employment  : %.4f (true: %.4f, diff: %.4f)\n",
            est_employ, theta_employ, est_employ - theta_employ))

# Self-weighting check
expected_w <- M_total / (a * b)
cat(sprintf("\n--- Self-Weighting Check ---\n"))
cat(sprintf("  Expected constant weight: %.2f\n", expected_w))
cat(sprintf("  Actual weight CV        : %.4f%%\n",
            sd(sample_data$weight) / mean(sample_data$weight) * 100))

stopifnot(all(abs(sample_data$weight - expected_w) / expected_w < 0.02))
cat("[PASS] Self-weighting property holds.\n")

# ============================================================
# VARIANCE ESTIMATION (Ultimate Cluster Approximation)
# ============================================================

cat("\n--- VARIANCE ESTIMATION ---\n")

# Compute cluster totals
z_income <- tapply(sample_data$weight * sample_data$income,
                   sample_data$psu_order, sum)
z_bar <- mean(z_income)

# Variance of weighted total
var_total <- (1 / (a * (a - 1))) * sum((z_income - z_bar)^2)
var_mean <- var_total / (sum(sample_data$weight))^2 * N^2

se_income <- sqrt(var_mean)
cv_income <- se_income / est_income * 100

cat(sprintf("  SE(mean income)  : %.2f\n", se_income))
cat(sprintf("  CV               : %.1f%%\n", cv_income))
cat(sprintf("  95%% CI           : [%.2f, %.2f]\n",
            est_income - 1.96 * se_income,
            est_income + 1.96 * se_income))
# ============================================================
# Lesson 2.3: Two-Stage Design with survey package
# ============================================================

library(survey)

# Using sample_data from the scratch code above
# sample_data has columns: ea_id, income, employed, weight, psu_order

# Define two-stage design
design <- svydesign(
  id      = ~psu_order,           # PSU identifier (cluster)
  weights = ~weight,              # Sampling weights
  data    = sample_data
)

# Estimates
est_income_pkg <- svymean(~income, design)
est_employ_pkg <- svymean(~employed, design)

cat(sprintf("\n--- survey package estimates ---\n"))
cat(sprintf("  Income : %.4f (SE: %.4f)\n", coef(est_income_pkg), SE(est_income_pkg)))
cat(sprintf("  Employ : %.4f (SE: %.4f)\n", coef(est_employ_pkg), SE(est_employ_pkg)))

# Compare with manual
cat(sprintf("\n  Manual income : %.4f\n", est_income))
cat(sprintf("  Pkg income    : %.4f\n", coef(est_income_pkg)))
stopifnot(abs(coef(est_income_pkg) - est_income) < 0.01)
cat("[PASS] Manual matches survey package estimate.\n")
