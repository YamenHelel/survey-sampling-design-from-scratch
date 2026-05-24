# ============================================================
# Lesson 4.2: Non-Response Propensity Adjustment
# R — From Scratch (using glm for logistic regression)
# ============================================================

set.seed(2024)

n_sample <- 3000

sample_df <- data.frame(
  urban    = rbinom(n_sample, 1, 0.6),
  head_age = pmin(80, pmax(18, round(rnorm(n_sample, 42, 12)))),
  hh_size  = pmax(1, pmin(15, rpois(n_sample, 4))),
  income   = rlnorm(n_sample, 7.0, 0.9),
  base_weight = 200
)

# Non-response mechanism
log_inc_scaled <- (log(sample_df$income) - 7.0) / 0.9
resp_prob <- plogis(1.0 - 0.8 * sample_df$urban +
                     0.02 * (sample_df$head_age - 42) -
                     0.3 * log_inc_scaled +
                     0.1 * sample_df$hh_size)
sample_df$responded <- rbinom(n_sample, 1, resp_prob)

cat(sprintf("Response rate: %.1f%%\n", mean(sample_df$responded) * 100))

# --- Propensity model ---
model <- glm(responded ~ urban + head_age + hh_size,
             data = sample_df, family = binomial)

sample_df$propensity <- predict(model, type = "response")

# Adjust weights
resp <- sample_df[sample_df$responded == 1, ]
resp$adj_weight <- resp$base_weight / resp$propensity

# Compare
true_mean <- mean(sample_df$income)
naive <- mean(resp$income)
base_wt <- weighted.mean(resp$income, resp$base_weight)
adj_wt <- weighted.mean(resp$income, resp$adj_weight)

cat(sprintf("\nTrue mean    : %.2f\n", true_mean))
cat(sprintf("Naive        : %.2f (bias: %+.2f)\n", naive, naive - true_mean))
cat(sprintf("Base weights : %.2f (bias: %+.2f)\n", base_wt, base_wt - true_mean))
cat(sprintf("Propensity   : %.2f (bias: %+.2f)\n", adj_wt, adj_wt - true_mean))

stopifnot(abs(adj_wt - true_mean) < abs(naive - true_mean))
cat("\n[PASS] Propensity adjustment reduces bias.\n")
library(survey)

# Use adjusted weights in survey design
design_adj <- svydesign(id = ~1, weights = ~adj_weight, data = resp)
est <- svymean(~income, design_adj)
cat(sprintf("svymean (adjusted): %.2f (SE: %.2f)\n", coef(est), SE(est)))
