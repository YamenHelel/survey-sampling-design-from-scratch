# ============================================================
# Lesson 5.2: Jackknife & Bootstrap Variance Estimation
# R — From Scratch (No survey package)
# ============================================================

set.seed(2024)

# --- Generate stratified cluster sample ---
H <- 3
a_per_h <- 25
b <- 20

sample_data <- data.frame()
psu_counter <- 0

for (h in 1:H) {
  for (i in 1:a_per_h) {
    psu_counter <- psu_counter + 1
    psu_mean <- rnorm(1, mean = 1500 + h * 300, sd = 200)
    psu_data <- data.frame(
      stratum = h,
      psu_id  = psu_counter,
      income  = pmax(100, rnorm(b, psu_mean, 400)),
      weight  = 500,
      stringsAsFactors = FALSE
    )
    sample_data <- rbind(sample_data, psu_data)
  }
}

n <- nrow(sample_data)
cat(sprintf("Sample: %d obs, %d strata, %d PSUs\n",
            n, H, H * a_per_h))

# Full-sample estimates
full_mean   <- weighted.mean(sample_data$income, sample_data$weight)
full_median <- median(rep(sample_data$income,
                          round(sample_data$weight / min(sample_data$weight))))

# Gini coefficient (weighted)
weighted_gini <- function(x, w) {
  valid <- !is.na(x) & !is.na(w)
  x <- x[valid]; w <- w[valid]
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  n_w <- sum(w)
  cum_w <- cumsum(w)
  cum_wx <- cumsum(w * x)
  total_wx <- sum(w * x)
  1 - 2 * sum(w * cum_wx) / (n_w * total_wx) +
    sum(w * w * x) / (n_w * total_wx)
}

full_gini <- weighted_gini(sample_data$income, sample_data$weight)

cat(sprintf("\nFull-sample estimates:\n"))
cat(sprintf("  Mean   : %.2f\n", full_mean))
cat(sprintf("  Gini   : %.4f\n", full_gini))

# ============================================================
# DELETE-ONE JACKKNIFE (stratified)
# ============================================================

cat("\n============================================================\n")
cat("  DELETE-ONE JACKKNIFE\n")
cat("============================================================\n")

jk_mean <- numeric(0)
jk_gini <- numeric(0)

for (h in 1:H) {
  h_data <- sample_data[sample_data$stratum == h, ]
  psus <- unique(h_data$psu_id)
  a_h <- length(psus)

  for (k in seq_along(psus)) {
    # Delete PSU k, rescale remaining weights
    keep <- sample_data$psu_id != psus[k]

    # Rescale weights within this stratum
    jk_data <- sample_data[keep, ]
    jk_data$jk_weight <- jk_data$weight
    remaining_h <- jk_data$stratum == h
    jk_data$jk_weight[remaining_h] <- jk_data$jk_weight[remaining_h] *
      a_h / (a_h - 1)

    jk_mean <- c(jk_mean, weighted.mean(jk_data$income, jk_data$jk_weight))
    jk_gini <- c(jk_gini, weighted_gini(jk_data$income, jk_data$jk_weight))
  }
}

a_total <- H * a_per_h

# Jackknife variance (stratified formula)
var_jk_mean <- ((a_total - 1) / a_total) * sum((jk_mean - mean(jk_mean))^2)
var_jk_gini <- ((a_total - 1) / a_total) * sum((jk_gini - mean(jk_gini))^2)

se_jk_mean <- sqrt(var_jk_mean)
se_jk_gini <- sqrt(var_jk_gini)

cat(sprintf("\n  Jackknife SE(mean): %.4f (CV: %.1f%%)\n",
            se_jk_mean, se_jk_mean / full_mean * 100))
cat(sprintf("  Jackknife SE(Gini): %.6f (CV: %.1f%%)\n",
            se_jk_gini, se_jk_gini / full_gini * 100))

# ============================================================
# SURVEY BOOTSTRAP
# ============================================================

cat("\n============================================================\n")
cat("  SURVEY BOOTSTRAP\n")
cat("============================================================\n")

B <- 500  # Bootstrap replications
boot_mean <- numeric(B)
boot_gini <- numeric(B)

for (r in 1:B) {
  boot_data <- sample_data
  boot_data$boot_weight <- boot_data$weight

  for (h in 1:H) {
    h_mask <- boot_data$stratum == h
    h_data <- boot_data[h_mask, ]
    psus <- unique(h_data$psu_id)
    a_h <- length(psus)

    # Resample a_h - 1 PSUs with replacement
    resampled <- sample(psus, a_h - 1, replace = TRUE)

    # Count occurrences
    counts <- table(factor(resampled, levels = psus))

    for (p in psus) {
      p_mask <- h_mask & boot_data$psu_id == p
      m_star <- as.numeric(counts[as.character(p)])
      boot_data$boot_weight[p_mask] <- boot_data$weight[p_mask] *
        (a_h / (a_h - 1)) * m_star
    }
  }

  # Keep only units with positive weight
  boot_active <- boot_data[boot_data$boot_weight > 0, ]

  boot_mean[r] <- weighted.mean(boot_active$income, boot_active$boot_weight)
  boot_gini[r] <- weighted_gini(boot_active$income, boot_active$boot_weight)
}

se_boot_mean <- sd(boot_mean)
se_boot_gini <- sd(boot_gini)

cat(sprintf("\n  Bootstrap SE(mean) [B=%d]: %.4f (CV: %.1f%%)\n",
            B, se_boot_mean, se_boot_mean / full_mean * 100))
cat(sprintf("  Bootstrap SE(Gini) [B=%d]: %.6f (CV: %.1f%%)\n",
            B, se_boot_gini, se_boot_gini / full_gini * 100))

# ============================================================
# COMPARISON
# ============================================================

cat("\n============================================================\n")
cat("  COMPARISON: Jackknife vs Bootstrap\n")
cat("============================================================\n")
cat(sprintf("  %-20s | %-15s | %-15s\n", "Statistic", "JK SE", "Boot SE"))
cat(paste(rep("-", 55), collapse = ""), "\n")
cat(sprintf("  %-20s | %15.4f | %15.4f\n", "Mean", se_jk_mean, se_boot_mean))
cat(sprintf("  %-20s | %15.6f | %15.6f\n", "Gini", se_jk_gini, se_boot_gini))

# They should be in the same ballpark
ratio_mean <- se_jk_mean / se_boot_mean
ratio_gini <- se_jk_gini / se_boot_gini
cat(sprintf("\n  SE ratio (JK/Boot) for mean: %.2f\n", ratio_mean))
cat(sprintf("  SE ratio (JK/Boot) for Gini: %.2f\n", ratio_gini))

stopifnot(ratio_mean > 0.5 && ratio_mean < 2.0)
cat("\n[PASS] JK and Bootstrap SEs are consistent.\n")
library(survey)

design <- svydesign(id = ~psu_id, strata = ~stratum,
                    weights = ~weight, data = sample_data, nest = TRUE)

# Jackknife replicate design
jk_design <- as.svrepdesign(design, type = "JK1")

est_mean_jk <- svymean(~income, jk_design)
cat(sprintf("JK svymean: %.4f (SE: %.4f)\n", coef(est_mean_jk), SE(est_mean_jk)))

# Compare
cat(sprintf("Manual JK SE: %.4f\n", se_jk_mean))
stopifnot(abs(SE(est_mean_jk) - se_jk_mean) / se_jk_mean < 0.15)
cat("[PASS] Manual JK consistent with survey package.\n")
