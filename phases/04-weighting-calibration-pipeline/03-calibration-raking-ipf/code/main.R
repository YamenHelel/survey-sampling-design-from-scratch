# ============================================================
# Lesson 4.3: Calibration / Raking via IPF
# R — From Scratch (basic matrix algebra)
# ============================================================

set.seed(2024)

# --- Generate sample with known population margins ---
n <- 3000
sample_df <- data.frame(
  sex      = sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.52, 0.48)),
  age_grp  = sample(c("18-30", "31-45", "46-60", "61+"), n, replace = TRUE,
                     prob = c(0.18, 0.32, 0.30, 0.20)),
  region   = sample(c("Urban", "Rural"), n, replace = TRUE, prob = c(0.65, 0.35)),
  income   = rlnorm(n, 7.0, 0.8),
  weight   = 200,  # Initial base weight
  stringsAsFactors = FALSE
)

N_pop <- n * 200  # Total population

# Known population margins (from census projections)
margins <- list(
  sex = c(Male = 0.49 * N_pop, Female = 0.51 * N_pop),
  age_grp = c("18-30" = 0.25 * N_pop, "31-45" = 0.30 * N_pop,
              "46-60" = 0.28 * N_pop, "61+" = 0.17 * N_pop),
  region = c(Urban = 0.58 * N_pop, Rural = 0.42 * N_pop)
)

cat("============================================================\n")
cat("  ITERATIVE PROPORTIONAL FITTING (RAKING)\n")
cat("============================================================\n\n")

# --- Show pre-calibration mismatch ---
cat("--- Before calibration ---\n")
for (var_name in names(margins)) {
  weighted_totals <- tapply(sample_df$weight, sample_df[[var_name]], sum)
  cat(sprintf("  %s:\n", var_name))
  for (cat_name in names(margins[[var_name]])) {
    wt <- weighted_totals[cat_name]
    target <- margins[[var_name]][cat_name]
    cat(sprintf("    %-8s: weighted=%8.0f, target=%8.0f, ratio=%.3f\n",
                cat_name, wt, target, wt / target))
  }
}

# ============================================================
# IPF ALGORITHM
# ============================================================

w <- sample_df$weight  # Working weights
max_iter <- 100
tol <- 0.001

cat(sprintf("\n--- Running IPF (tol=%.4f, max_iter=%d) ---\n", tol, max_iter))

for (iter in 1:max_iter) {
  max_diff <- 0

  for (var_name in names(margins)) {
    targets <- margins[[var_name]]
    variable <- sample_df[[var_name]]

    for (cat_name in names(targets)) {
      mask <- variable == cat_name
      current_total <- sum(w[mask])
      target_total <- targets[cat_name]

      if (current_total > 0) {
        factor <- target_total / current_total
        w[mask] <- w[mask] * factor
        max_diff <- max(max_diff, abs(factor - 1))
      }
    }
  }

  if (iter <= 5 || iter %% 10 == 0) {
    cat(sprintf("  Iteration %3d: max adjustment factor deviation = %.6f\n",
                iter, max_diff))
  }

  if (max_diff < tol) {
    cat(sprintf("  CONVERGED at iteration %d\n", iter))
    break
  }
}

sample_df$cal_weight <- w

# --- Verify calibration ---
cat("\n--- After calibration ---\n")
all_match <- TRUE
for (var_name in names(margins)) {
  weighted_totals <- tapply(sample_df$cal_weight, sample_df[[var_name]], sum)
  for (cat_name in names(margins[[var_name]])) {
    wt <- weighted_totals[cat_name]
    target <- margins[[var_name]][cat_name]
    ratio <- wt / target
    cat(sprintf("  %s / %-8s: ratio=%.6f\n", var_name, cat_name, ratio))
    if (abs(ratio - 1) > 0.001) all_match <- FALSE
  }
}

stopifnot(all_match)
cat("\n[PASS] All margins matched after raking.\n")

# --- Weight diagnostics ---
cat(sprintf("\n--- Weight diagnostics ---\n"))
cat(sprintf("  Original weight: %.0f (constant)\n", 200))
cat(sprintf("  Calibrated range: [%.1f, %.1f]\n",
            min(sample_df$cal_weight), max(sample_df$cal_weight)))
cat(sprintf("  Calibrated CV   : %.1f%%\n",
            sd(sample_df$cal_weight) / mean(sample_df$cal_weight) * 100))
cat(sprintf("  Weight sum      : %s (target: %s)\n",
            format(round(sum(sample_df$cal_weight)), big.mark = ","),
            format(N_pop, big.mark = ",")))

stopifnot(abs(sum(sample_df$cal_weight) - N_pop) < 1)
cat("[PASS] Total weight equals population.\n")
# ============================================================
# Lesson 4.3: Calibration with survey::calibrate
# ============================================================

library(survey)

# Initial design
design_init <- svydesign(id = ~1, weights = ~weight, data = sample_df)

# Population totals for calibration
pop_totals <- c(
  `(Intercept)` = N_pop,
  sexMale = 0.49 * N_pop,
  `age_grp31-45` = 0.30 * N_pop,
  `age_grp46-60` = 0.28 * N_pop,
  `age_grp61+` = 0.17 * N_pop,
  regionUrban = 0.58 * N_pop
)

design_cal <- calibrate(design_init,
                         formula = ~sex + age_grp + region,
                         population = pop_totals,
                         calfun = "raking")

# Compare estimates
est_before <- svymean(~income, design_init)
est_after  <- svymean(~income, design_cal)

cat(sprintf("Before calibration: %.2f (SE: %.2f)\n",
            coef(est_before), SE(est_before)))
cat(sprintf("After calibration : %.2f (SE: %.2f)\n",
            coef(est_after), SE(est_after)))

# Verify margins
cat("\nMargin check (sex):\n")
print(svytotal(~sex, design_cal))
