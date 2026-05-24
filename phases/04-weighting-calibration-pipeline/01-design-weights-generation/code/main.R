# ============================================================
# Lesson 4.1: Design Weights (Base Weights)
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Setup: Two-stage sample ---
n_eas <- 3000
ea_sizes <- pmax(50, rpois(n_eas, 120))
M_total <- sum(ea_sizes)
N_total <- M_total  # Each HH is one unit

a <- 180  # PSUs selected
b <- 15   # HH per PSU

# Stage 1: PPS selection
cumulative <- cumsum(ea_sizes)
interval <- M_total / a
R <- runif(1, 0, interval)
sel_points <- R + (0:(a-1)) * interval
selected_psu <- integer(a)
for (k in 1:a) {
  selected_psu[k] <- min(which(cumulative >= sel_points[k]))
}

# Compute weights step by step
cat("============================================================\n")
cat("  DESIGN WEIGHT COMPUTATION\n")
cat("============================================================\n\n")

weight_table <- data.frame(
  psu_order = 1:a,
  ea_id     = sprintf("EA_%04d", selected_psu),
  M_i       = ea_sizes[selected_psu],
  stringsAsFactors = FALSE
)

# Stage 1 weights
weight_table$pi_1 <- a * weight_table$M_i / M_total
weight_table$w_1  <- 1 / weight_table$pi_1

# Stage 2 weights
weight_table$pi_2 <- b / weight_table$M_i
weight_table$w_2  <- 1 / weight_table$pi_2

# Overall weight
weight_table$pi_overall <- weight_table$pi_1 * weight_table$pi_2
weight_table$w_overall  <- weight_table$w_1 * weight_table$w_2

# Display first 10
cat("--- Weight decomposition (first 10 PSUs) ---\n")
cat(sprintf("%-4s | %-8s | %5s | %8s | %8s | %10s | %10s\n",
            "#", "EA", "M_i", "pi_1", "pi_2", "w_1", "w_overall"))
cat(paste(rep("-", 70), collapse = ""), "\n")
for (i in 1:min(10, a)) {
  cat(sprintf("%-4d | %-8s | %5d | %8.4f | %8.4f | %10.2f | %10.2f\n",
              i, weight_table$ea_id[i], weight_table$M_i[i],
              weight_table$pi_1[i], weight_table$pi_2[i],
              weight_table$w_1[i], weight_table$w_overall[i]))
}

# --- Verification 1: Sum of weights ≈ N ---
# Each PSU contributes b HH, each with weight w_overall
total_weight_sum <- sum(weight_table$w_overall * b)
cat(sprintf("\n--- Weight Sum Verification ---\n"))
cat(sprintf("  Sum of weights (a x b x w): %s\n",
            format(round(total_weight_sum), big.mark = ",")))
cat(sprintf("  True N                    : %s\n",
            format(N_total, big.mark = ",")))
cat(sprintf("  Ratio                     : %.4f\n",
            total_weight_sum / N_total))

stopifnot(abs(total_weight_sum / N_total - 1) < 0.01)
cat("[PASS] Weight sum matches population size.\n")

# --- Verification 2: Self-weighting ---
expected_w <- M_total / (a * b)
actual_cv <- sd(weight_table$w_overall) / mean(weight_table$w_overall)
cat(sprintf("\n--- Self-Weighting Check ---\n"))
cat(sprintf("  Expected constant weight: %.2f\n", expected_w))
cat(sprintf("  Mean actual weight      : %.2f\n", mean(weight_table$w_overall)))
cat(sprintf("  Weight CV               : %.6f\n", actual_cv))

stopifnot(actual_cv < 0.001)
cat("[PASS] Self-weighting design confirmed.\n")

# --- Weight distribution summary ---
cat(sprintf("\n--- Weight Distribution ---\n"))
cat(sprintf("  Min    : %.2f\n", min(weight_table$w_overall)))
cat(sprintf("  Q1     : %.2f\n", quantile(weight_table$w_overall, 0.25)))
cat(sprintf("  Median : %.2f\n", median(weight_table$w_overall)))
cat(sprintf("  Q3     : %.2f\n", quantile(weight_table$w_overall, 0.75)))
cat(sprintf("  Max    : %.2f\n", max(weight_table$w_overall)))
# ============================================================
# Lesson 4.1: Weighted estimation with survey package
# ============================================================

library(survey)

set.seed(2024)

# Simulated sample with weights
sample_df <- data.frame(
  psu_id  = rep(1:a, each = b),
  weight  = rep(weight_table$w_overall, each = b),
  income  = rlnorm(a * b, 7.2, 0.8),
  poverty = rbinom(a * b, 1, 0.25)
)

design <- svydesign(id = ~psu_id, weights = ~weight, data = sample_df)

est_income  <- svymean(~income, design)
est_poverty <- svymean(~poverty, design)
est_total   <- svytotal(~income, design)

cat(sprintf("Mean income  : %.2f (SE: %.2f)\n", coef(est_income), SE(est_income)))
cat(sprintf("Poverty rate : %.4f (SE: %.4f)\n", coef(est_poverty), SE(est_poverty)))
cat(sprintf("Total income : %s (SE: %s)\n",
            format(round(coef(est_total)), big.mark = ","),
            format(round(SE(est_total)), big.mark = ",")))

# Verify weight sum = population
pop_est <- svytotal(~I(1), design)
cat(sprintf("\nEstimated N: %s\n", format(round(coef(pop_est)), big.mark = ",")))
