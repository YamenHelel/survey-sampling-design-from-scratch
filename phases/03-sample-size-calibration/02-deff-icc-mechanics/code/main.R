# ============================================================
# Lesson 3.2: Design Effect & ICC from Scratch
# R — Using ANOVA variance components
# ============================================================

set.seed(2024)

# --- Compute ICC from scratch using ANOVA ---
compute_icc_scratch <- function(y, cluster) {
  stopifnot(length(y) == length(cluster))
  valid <- !is.na(y) & !is.na(cluster)
  y <- y[valid]
  cluster <- as.factor(cluster[valid])

  grand_mean <- mean(y)
  clusters <- levels(cluster)
  k <- length(clusters)
  n_total <- length(y)

  # Cluster sizes and means
  cluster_sizes <- as.numeric(table(cluster))
  cluster_means <- tapply(y, cluster, mean)
  m_bar <- mean(cluster_sizes)

  # Sum of Squares Between (SSB)
  ssb <- sum(cluster_sizes * (cluster_means - grand_mean)^2)
  msb <- ssb / (k - 1)

  # Sum of Squares Within (SSW)
  ssw <- sum((y - ave(y, cluster, FUN = mean))^2)
  msw <- ssw / (n_total - k)

  # Variance components
  sigma2_between <- (msb - msw) / m_bar
  sigma2_within <- msw

  # ICC
  rho <- sigma2_between / (sigma2_between + sigma2_within)
  rho <- max(rho, -1 / (m_bar - 1))  # Bound

  list(
    rho     = rho,
    msb     = msb,
    msw     = msw,
    sigma2_b = sigma2_between,
    sigma2_w = sigma2_within,
    k       = k,
    m_bar   = m_bar,
    deff    = 1 + (m_bar - 1) * rho
  )
}

# ============================================================
# SIMULATION: Generate clustered population
# ============================================================

k <- 500         # Number of clusters
m <- 100         # HH per cluster
rho_true <- 0.08 # True ICC

# Generate with controlled ICC
sigma2_total <- 100
sigma2_between <- rho_true * sigma2_total
sigma2_within <- (1 - rho_true) * sigma2_total

cluster_effects <- rnorm(k, mean = 0, sd = sqrt(sigma2_between))
y <- numeric(k * m)
cluster_id <- character(k * m)

for (i in 1:k) {
  idx <- ((i-1)*m + 1):(i*m)
  y[idx] <- 50 + cluster_effects[i] + rnorm(m, 0, sqrt(sigma2_within))
  cluster_id[idx] <- sprintf("CL_%03d", i)
}

cat(sprintf("Population: %d clusters x %d units = %d total\n", k, m, k*m))
cat(sprintf("True ICC (rho): %.4f\n\n", rho_true))

# --- Compute ICC ---
result <- compute_icc_scratch(y, cluster_id)

cat("--- ANOVA Decomposition ---\n")
cat(sprintf("  MSB (between)   : %.4f\n", result$msb))
cat(sprintf("  MSW (within)    : %.4f\n", result$msw))
cat(sprintf("  sigma2_between  : %.4f\n", result$sigma2_b))
cat(sprintf("  sigma2_within   : %.4f\n", result$sigma2_w))
cat(sprintf("  ICC (rho)       : %.4f (true: %.4f)\n", result$rho, rho_true))
cat(sprintf("  Deff (m=%d)     : %.2f\n", result$m_bar, result$deff))

stopifnot(abs(result$rho - rho_true) < 0.02)
cat("\n[PASS] ICC estimate within 0.02 of true value.\n")

# ============================================================
# COMPARE SCENARIOS A vs B
# ============================================================

cat("\n============================================================\n")
cat("  SCENARIO COMPARISON\n")
cat("============================================================\n")

rho_est <- result$rho

# Scenario A: 300 clusters x 10 HH
a_clusters <- 300; a_m <- 10
deff_a <- 1 + (a_m - 1) * rho_est

# Scenario B: 150 clusters x 20 HH
b_clusters <- 150; b_m <- 20
deff_b <- 1 + (b_m - 1) * rho_est

n_total <- 3000
eff_n_a <- n_total / deff_a
eff_n_b <- n_total / deff_b

cat(sprintf("  Scenario A: %d clusters x %d = %d (Deff=%.2f, eff_n=%.0f)\n",
            a_clusters, a_m, a_clusters * a_m, deff_a, eff_n_a))
cat(sprintf("  Scenario B: %d clusters x %d = %d (Deff=%.2f, eff_n=%.0f)\n",
            b_clusters, b_m, b_clusters * b_m, deff_b, eff_n_b))
cat(sprintf("  Efficiency ratio (A/B): %.2f\n", eff_n_a / eff_n_b))

stopifnot(deff_a < deff_b)
cat("\n[PASS] Smaller clusters produce lower Deff.\n")

# ============================================================
# Monte Carlo verification of Deff
# ============================================================

cat("\n--- Monte Carlo Deff Verification ---\n")

B <- 3000
n_sample <- 300  # Sample size for both

# SRS estimates
srs_est <- numeric(B)
for (b in 1:B) {
  idx <- sample(length(y), n_sample, replace = FALSE)
  srs_est[b] <- mean(y[idx])
}
var_srs <- var(srs_est)

# Cluster sample (30 clusters x 10)
clust_est <- numeric(B)
for (b in 1:B) {
  sel_cl <- sample(unique(cluster_id), 30, replace = FALSE)
  est_vals <- numeric(0)
  for (cl in sel_cl) {
    cl_vals <- y[cluster_id == cl]
    idx <- sample(length(cl_vals), min(10, length(cl_vals)))
    est_vals <- c(est_vals, cl_vals[idx])
  }
  clust_est[b] <- mean(est_vals)
}
var_clust <- var(clust_est)

deff_mc <- var_clust / var_srs
deff_formula <- 1 + (10 - 1) * rho_est

cat(sprintf("  Var(SRS)     : %.6f\n", var_srs))
cat(sprintf("  Var(Cluster) : %.6f\n", var_clust))
cat(sprintf("  Deff (MC)    : %.2f\n", deff_mc))
cat(sprintf("  Deff (formula): %.2f\n", deff_formula))
cat(sprintf("  Ratio MC/form: %.2f\n", deff_mc / deff_formula))

stopifnot(abs(deff_mc - deff_formula) / deff_formula < 0.25)
cat("[PASS] MC Deff consistent with formula.\n")
# ============================================================
# Lesson 3.2: Deff estimation with survey package
# ============================================================

library(survey)

# Using population from scratch code
sample_idx <- sample(length(y), 300, replace = FALSE)
sample_clusters <- cluster_id[sample_idx]
sample_y <- y[sample_idx]

# Draw a proper cluster sample: 30 clusters, 10 per cluster
sel_clusters <- sample(unique(cluster_id), 30, replace = FALSE)
cl_sample <- data.frame()
for (cl in sel_clusters) {
  cl_vals <- y[cluster_id == cl]
  idx <- sample(length(cl_vals), min(10, length(cl_vals)))
  cl_sample <- rbind(cl_sample, data.frame(
    cluster = cl,
    y_val   = cl_vals[idx],
    weight  = length(unique(cluster_id)) / 30 * length(cl_vals) / 10
  ))
}

design <- svydesign(id = ~cluster, weights = ~weight, data = cl_sample)
est <- svymean(~y_val, design)
deff_pkg <- deff(est)

cat(sprintf("survey::deff = %.2f\n", deff_pkg))

# Manual ICC for comparison
icc_manual <- compute_icc_scratch(cl_sample$y_val, cl_sample$cluster)
cat(sprintf("Manual ICC   = %.4f\n", icc_manual$rho))
cat(sprintf("Manual Deff  = %.2f\n", icc_manual$deff))
