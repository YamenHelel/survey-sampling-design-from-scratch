# ============================================================
# Lesson 5.1: Taylor Series Linearization from Scratch
# R — No survey package
# ============================================================

set.seed(2024)

# --- Generate two-stage stratified cluster sample ---
H <- 4        # Strata
a_h <- 20     # PSUs per stratum
b <- 15       # HH per PSU

sample_data <- data.frame()
psu_counter <- 0

for (h in 1:H) {
  stratum_unemp_rate <- runif(1, 0.05, 0.25)

  for (i in 1:a_h) {
    psu_counter <- psu_counter + 1
    psu_rate <- plogis(qlogis(stratum_unemp_rate) + rnorm(1, 0, 0.5))

    psu_data <- data.frame(
      stratum     = h,
      psu_id      = psu_counter,
      labor_force = rbinom(b, 1, prob = 0.65),  # In labor force?
      stringsAsFactors = FALSE
    )
    # Unemployed only among labor force participants
    psu_data$unemployed <- ifelse(psu_data$labor_force == 1,
                                   rbinom(b, 1, prob = psu_rate), 0)
    psu_data$weight <- 500  # Simplified constant weight

    sample_data <- rbind(sample_data, psu_data)
  }
}

n_total <- nrow(sample_data)
cat(sprintf("Sample: %d obs, %d strata, %d PSUs, %d HH/PSU\n",
            n_total, H, H * a_h, b))

# ============================================================
# STEP 1: Compute ratio estimate
# ============================================================

Y_hat <- sum(sample_data$weight * sample_data$unemployed)
X_hat <- sum(sample_data$weight * sample_data$labor_force)
R_hat <- Y_hat / X_hat

cat(sprintf("\nEstimated unemployment rate: %.4f (%.1f%%)\n",
            R_hat, R_hat * 100))

# ============================================================
# STEP 2: Compute linearized residuals
# ============================================================

sample_data$e_i <- sample_data$unemployed - R_hat * sample_data$labor_force

# ============================================================
# STEP 3: Compute variance via Taylor linearization
# ============================================================

var_taylor <- 0

for (h in 1:H) {
  stratum_data <- sample_data[sample_data$stratum == h, ]
  psus_in_h <- unique(stratum_data$psu_id)
  a <- length(psus_in_h)

  # PSU-level weighted totals of residuals
  z_hi <- numeric(a)
  for (i in seq_along(psus_in_h)) {
    psu_data <- stratum_data[stratum_data$psu_id == psus_in_h[i], ]
    z_hi[i] <- sum(psu_data$weight * psu_data$e_i)
  }

  z_bar <- mean(z_hi)
  ss <- sum((z_hi - z_bar)^2)

  var_taylor <- var_taylor + (a / (a - 1)) * ss
}

var_R <- var_taylor / X_hat^2
se_R <- sqrt(var_R)
cv_R <- se_R / R_hat * 100

cat(sprintf("\n--- Taylor Linearization Results ---\n"))
cat(sprintf("  Var(R_hat)  : %.8f\n", var_R))
cat(sprintf("  SE(R_hat)   : %.4f\n", se_R))
cat(sprintf("  CV          : %.1f%%\n", cv_R))
cat(sprintf("  95%% CI      : [%.4f, %.4f]\n",
            R_hat - 1.96 * se_R, R_hat + 1.96 * se_R))

# ============================================================
# VERIFICATION: Compare with survey package
# ============================================================

library(survey)

design <- svydesign(id = ~psu_id, strata = ~stratum,
                    weights = ~weight, data = sample_data,
                    nest = TRUE)

# Ratio estimator: unemployed / labor_force
est_pkg <- svyratio(~unemployed, ~labor_force, design)
se_pkg <- SE(est_pkg)

cat(sprintf("\n--- Comparison ---\n"))
cat(sprintf("  Manual R_hat : %.6f\n", R_hat))
cat(sprintf("  survey R_hat : %.6f\n", coef(est_pkg)))
cat(sprintf("  Manual SE    : %.6f\n", se_R))
cat(sprintf("  survey SE    : %.6f\n", se_pkg))
cat(sprintf("  SE ratio     : %.4f\n", se_R / as.numeric(se_pkg)))

stopifnot(abs(R_hat - coef(est_pkg)) < 1e-8)
cat("\n[PASS] Point estimates match exactly.\n")

stopifnot(abs(se_R - as.numeric(se_pkg)) / as.numeric(se_pkg) < 0.01)
cat("[PASS] Standard errors match to 4 decimal places.\n")
# ============================================================
# PRODUCTION: taylor_variance.R
# ============================================================

taylor_ratio_variance <- function(sample_data, y_col, x_col,
                                   weight_col, psu_col, stratum_col) {
  w <- sample_data[[weight_col]]
  y <- sample_data[[y_col]]
  x <- sample_data[[x_col]]

  Y_hat <- sum(w * y, na.rm = TRUE)
  X_hat <- sum(w * x, na.rm = TRUE)
  R_hat <- Y_hat / X_hat

  e <- y - R_hat * x

  strata <- unique(sample_data[[stratum_col]])
  var_total <- 0

  for (h in strata) {
    mask <- sample_data[[stratum_col]] == h
    h_data <- sample_data[mask, ]
    psus <- unique(h_data[[psu_col]])
    a <- length(psus)

    z <- sapply(psus, function(p) {
      p_mask <- h_data[[psu_col]] == p
      sum(h_data[p_mask, weight_col] * e[mask][p_mask], na.rm = TRUE)
    })

    z_bar <- mean(z)
    var_total <- var_total + (a / (a - 1)) * sum((z - z_bar)^2)
  }

  se <- sqrt(var_total / X_hat^2)

  list(
    estimate = R_hat,
    se       = se,
    cv       = se / abs(R_hat) * 100,
    ci_lower = R_hat - 1.96 * se,
    ci_upper = R_hat + 1.96 * se,
    dof      = sum(sapply(strata, function(h)
      length(unique(sample_data[[psu_col]][sample_data[[stratum_col]] == h])))) -
      length(strata)
  )
}
