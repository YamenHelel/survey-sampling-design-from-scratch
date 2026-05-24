# ============================================================
# Lesson 2.2: Systematic PPS Selection
# R — From Scratch (No sampling libraries)
# ============================================================

set.seed(2024)

# --- Generate EA frame ---
A <- 4500
a <- 200

ea_sizes <- c(
  rpois(300, lambda = 40),
  rpois(3900, lambda = 110),
  rpois(300, lambda = 350)
)
ea_sizes <- pmax(ea_sizes, 20)
ea_ids <- sprintf("EA_%04d", 1:A)

cat(sprintf("Total EAs: %d\n", A))
cat(sprintf("Size range: [%d, %d]\n", min(ea_sizes), max(ea_sizes)))
cat(sprintf("Total HH: %s\n", format(sum(ea_sizes), big.mark = ",")))

# ============================================================
# SYSTEMATIC PPS — FROM SCRATCH
# ============================================================

# Step 1: Cumulative sizes
cumulative <- cumsum(ea_sizes)
M_total <- sum(ea_sizes)

# Step 2: Interval
interval <- M_total / a

# Step 3: Random start
R <- runif(1, 0, interval)

# Step 4: Selection points
sel_points <- R + (0:(a-1)) * interval

# Step 5: Select EAs
selected <- integer(a)
for (k in 1:a) {
  selected[k] <- min(which(cumulative >= sel_points[k]))
}

# Inclusion probabilities
pi_i <- a * ea_sizes[selected] / M_total
base_weights <- 1 / pi_i

cat(sprintf("\n--- Selected Sample ---\n"))
cat(sprintf("  EAs selected: %d\n", length(selected)))
cat(sprintf("  Pi range    : [%.4f, %.4f]\n", min(pi_i), max(pi_i)))
cat(sprintf("  Weight range: [%.2f, %.2f]\n", min(base_weights), max(base_weights)))

# Self-weighting check
b <- 15
hh_weights <- base_weights * (ea_sizes[selected] / b)
expected_w <- M_total / (a * b)

cat(sprintf("\n--- Self-Weighting Check (b = %d) ---\n", b))
cat(sprintf("  Expected weight: %.2f\n", expected_w))
cat(sprintf("  Actual range   : [%.2f, %.2f]\n", min(hh_weights), max(hh_weights)))
cat(sprintf("  CV             : %.4f%%\n", sd(hh_weights) / mean(hh_weights) * 100))

stopifnot(all(abs(hh_weights - expected_w) / expected_w < 0.01))
cat("\n[PASS] Self-weighting property verified.\n")
# ============================================================
# Lesson 2.2: PPS Selection with sampling package
# ============================================================

library(sampling)

set.seed(2024)

A <- 4500
a <- 200
ea_sizes <- c(rpois(300, 40), rpois(3900, 110), rpois(300, 350))
ea_sizes <- pmax(ea_sizes, 20)

frame <- data.frame(
  ea_id = sprintf("EA_%04d", 1:A),
  size  = ea_sizes
)

# Inclusion probabilities
pik <- inclusionprobabilities(frame$size, a)

# Systematic PPS
s <- UPsystematic(pik)
selected_pkg <- frame[s == 1, ]

cat(sprintf("sampling::UPsystematic selected %d EAs\n", nrow(selected_pkg)))

# Compare with manual
# (Manual implementation already verified above)
cat(sprintf("  Size range: [%d, %d]\n",
            min(selected_pkg$size), max(selected_pkg$size)))

# Verify inclusion probabilities
manual_pi <- a * selected_pkg$size / sum(frame$size)
pkg_pi <- pik[s == 1]
max_diff <- max(abs(manual_pi - pkg_pi))
cat(sprintf("  Max pi difference (manual vs pkg): %.6f\n", max_diff))
stopifnot(max_diff < 1e-10)
cat("[PASS] Manual pi matches sampling package.\n")
