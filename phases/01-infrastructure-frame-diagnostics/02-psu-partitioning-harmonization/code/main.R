# ============================================================
# Lesson 1.2: PSU Partitioning & Harmonization
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Generate EA frame with problematic sizes ---
n_eas <- 4500
eas <- data.frame(
  ea_id   = sprintf("EA_%04d", 1:n_eas),
  dist_id = sample(sprintf("DIST_%03d", 1:120), n_eas, replace = TRUE),
  n_hh    = NA_integer_,
  stringsAsFactors = FALSE
)

# Generate sizes: mix of small, normal, and large
eas$n_hh <- c(
  rpois(340, lambda = 20),                       # Small EAs
  rpois(n_eas - 340 - 85, lambda = 110),          # Normal EAs
  rpois(85, lambda = 400)                          # Large EAs
)
eas$n_hh <- pmax(eas$n_hh, 5)  # Minimum 5 households

# --- Configuration ---
M_MIN <- 80
M_MAX <- 150
M_TARGET <- 110

cat("============================================================\n")
cat("  PSU HARMONIZATION ENGINE\n")
cat("============================================================\n\n")

cat("--- BEFORE Harmonization ---\n")
cat(sprintf("  Total EAs        : %d\n", nrow(eas)))
cat(sprintf("  Size range       : [%d, %d]\n", min(eas$n_hh), max(eas$n_hh)))
cat(sprintf("  Mean size        : %.1f\n", mean(eas$n_hh)))
cat(sprintf("  CV of sizes      : %.1f%%\n", sd(eas$n_hh) / mean(eas$n_hh) * 100))
cat(sprintf("  Undersized (<%d) : %d\n", M_MIN, sum(eas$n_hh < M_MIN)))
cat(sprintf("  Oversized (>%d)  : %d\n", M_MAX, sum(eas$n_hh > M_MAX)))

# ============================================================
# STEP 1: SPLIT OVERSIZED EAs
# ============================================================

cat("\n--- STEP 1: Splitting oversized EAs ---\n")

split_results <- data.frame()
n_splits <- 0

for (i in 1:nrow(eas)) {
  if (eas$n_hh[i] > M_MAX) {
    # Determine number of sub-units
    k <- ceiling(eas$n_hh[i] / M_TARGET)
    base_size <- floor(eas$n_hh[i] / k)
    remainder <- eas$n_hh[i] - base_size * k

    for (j in 1:k) {
      sub_size <- base_size + ifelse(j <= remainder, 1, 0)
      split_results <- rbind(split_results, data.frame(
        psu_id  = sprintf("%s_S%d", eas$ea_id[i], j),
        dist_id = eas$dist_id[i],
        n_hh    = sub_size,
        origin  = "split",
        stringsAsFactors = FALSE
      ))
    }
    n_splits <- n_splits + 1
  } else {
    split_results <- rbind(split_results, data.frame(
      psu_id  = eas$ea_id[i],
      dist_id = eas$dist_id[i],
      n_hh    = eas$n_hh[i],
      origin  = "original",
      stringsAsFactors = FALSE
    ))
  }
}

cat(sprintf("  EAs split: %d -> %d sub-units\n",
            n_splits, sum(split_results$origin == "split")))

# ============================================================
# STEP 2: MERGE UNDERSIZED PSUs
# ============================================================

cat("\n--- STEP 2: Merging undersized PSUs ---\n")

psu_frame <- split_results
psu_frame$merged_into <- NA_character_
n_merges <- 0

# Process district by district
for (d in unique(psu_frame$dist_id)) {
  dist_mask <- psu_frame$dist_id == d
  dist_psus <- which(dist_mask)

  # Find undersized PSUs in this district
  undersized <- dist_psus[psu_frame$n_hh[dist_psus] < M_MIN &
                           is.na(psu_frame$merged_into[dist_psus])]

  while (length(undersized) > 0) {
    current <- undersized[1]

    # Find best merge partner: closest in size, not already merged
    candidates <- dist_psus[is.na(psu_frame$merged_into[dist_psus]) &
                             dist_psus != current]

    if (length(candidates) == 0) break

    # Pick candidate whose combined size is closest to target
    combined_sizes <- psu_frame$n_hh[current] + psu_frame$n_hh[candidates]
    best_idx <- which.min(abs(combined_sizes - M_TARGET))
    partner <- candidates[best_idx]

    # Check if merge wouldn't exceed max
    new_size <- psu_frame$n_hh[current] + psu_frame$n_hh[partner]

    if (new_size <= M_MAX * 1.2) {  # Allow slight overshoot
      psu_frame$n_hh[partner] <- new_size
      psu_frame$merged_into[current] <- psu_frame$psu_id[partner]
      psu_frame$psu_id[partner] <- sprintf("%s+%s",
                                            psu_frame$psu_id[partner],
                                            psu_frame$psu_id[current])
      psu_frame$origin[partner] <- "merged"
      n_merges <- n_merges + 1
    }

    # Remove current from undersized list
    undersized <- undersized[-1]

    # Refresh undersized list
    undersized <- dist_psus[psu_frame$n_hh[dist_psus] < M_MIN &
                             is.na(psu_frame$merged_into[dist_psus])]
  }
}

# Remove merged-away PSUs
final_psus <- psu_frame[is.na(psu_frame$merged_into), ]
cat(sprintf("  Merges performed: %d\n", n_merges))

# ============================================================
# RESULTS
# ============================================================

cat("\n--- AFTER Harmonization ---\n")
cat(sprintf("  Total PSUs       : %d\n", nrow(final_psus)))
cat(sprintf("  Size range       : [%d, %d]\n",
            min(final_psus$n_hh), max(final_psus$n_hh)))
cat(sprintf("  Mean size        : %.1f\n", mean(final_psus$n_hh)))
cat(sprintf("  CV of sizes      : %.1f%%\n",
            sd(final_psus$n_hh) / mean(final_psus$n_hh) * 100))
cat(sprintf("  Still undersized : %d\n", sum(final_psus$n_hh < M_MIN)))
cat(sprintf("  Still oversized  : %d\n", sum(final_psus$n_hh > M_MAX)))

# Total households should be preserved
total_before <- sum(eas$n_hh)
total_after <- sum(final_psus$n_hh)
stopifnot(total_before == total_after)
cat(sprintf("\n  Total HH preserved: %s = %s [PASS]\n",
            format(total_before, big.mark = ","),
            format(total_after, big.mark = ",")))

# ============================================================
# USE IT: Geographic adjacency with sf package
# ============================================================

# In production, use GIS for geographic adjacency:
# library(sf)
#
# # Load EA boundary shapefile
# ea_boundaries <- st_read("ea_boundaries.shp")
#
# # Find adjacent EAs
# adjacency <- st_touches(ea_boundaries)
#
# # For each undersized EA, find adjacent candidates
# for (i in which(ea_boundaries$n_hh < M_MIN)) {
#   neighbors <- adjacency[[i]]
#   # Merge with smallest adjacent neighbor
#   ...
# }
