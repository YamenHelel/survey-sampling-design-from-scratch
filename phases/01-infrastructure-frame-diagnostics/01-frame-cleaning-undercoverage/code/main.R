# ============================================================
# Lesson 1.1: Frame Cleaning & Undercoverage Diagnostics
# R — From Scratch
# ============================================================

set.seed(2024)

# --- Generate test frame ---
N <- 50000
frame <- data.frame(
  hh_id     = sprintf("HH_%06d", 1:N),
  gov_id    = sample(sprintf("GOV_%02d", 1:6), N, replace = TRUE),
  ea_id     = sample(sprintf("EA_%04d", 1:500), N, replace = TRUE),
  hh_size   = pmax(1, rpois(N, 4)),
  head_age  = pmin(90, pmax(18, round(rnorm(N, 42, 12)))),
  hh_income = round(rlnorm(N, 7.0, 0.9), 2),
  status    = "Occupied",
  stringsAsFactors = FALSE
)

# Inject duplicates (~1%)
n_dup <- round(N * 0.01)
dup_rows <- frame[sample(1:N, n_dup, replace = TRUE), ]
dup_rows$hh_id <- sprintf("HH_%06d", (N + 1):(N + n_dup))
frame <- rbind(frame, dup_rows)

# Inject out-of-scope (~2%)
n_oos <- round(nrow(frame) * 0.02)
oos_idx <- sample(1:nrow(frame), n_oos)
frame$status[oos_idx] <- sample(c("Vacant", "Demolished", "Under_Construction"),
                                 n_oos, replace = TRUE, prob = c(0.5, 0.3, 0.2))

# Inject NAs (~3%)
for (col in c("hh_size", "head_age", "hh_income")) {
  na_idx <- sample(1:nrow(frame), round(nrow(frame) * 0.03))
  frame[na_idx, col] <- NA
}

cat(sprintf("Raw frame: %s rows, %d columns\n\n",
            format(nrow(frame), big.mark = ","), ncol(frame)))

# --- STEP 1: Duplicate Detection ---
cat("============================================================\n")
cat("  STEP 1: DUPLICATE DETECTION\n")
cat("============================================================\n")

key_cols <- c("gov_id", "ea_id", "hh_size", "head_age")
frame$dup_key <- apply(frame[, key_cols], 1, paste, collapse = "|")
is_dup <- duplicated(frame$dup_key)
n_duplicates <- sum(is_dup)

cat(sprintf("  Duplicates found: %s (%.2f%%)\n",
            format(n_duplicates, big.mark = ","),
            n_duplicates / nrow(frame) * 100))

frame_clean <- frame[!is_dup, ]
frame_clean$dup_key <- NULL
cat(sprintf("  After deduplication: %s rows\n",
            format(nrow(frame_clean), big.mark = ",")))

# --- STEP 2: Out-of-Scope ---
cat("\n============================================================\n")
cat("  STEP 2: OUT-OF-SCOPE RECORDS\n")
cat("============================================================\n")

status_tab <- table(frame_clean$status)
for (s in names(status_tab)) {
  cat(sprintf("  %-20s: %s (%.1f%%)\n", s,
              format(status_tab[s], big.mark = ","),
              status_tab[s] / nrow(frame_clean) * 100))
}

frame_inscope <- frame_clean[frame_clean$status == "Occupied", ]
n_oos_removed <- nrow(frame_clean) - nrow(frame_inscope)
cat(sprintf("\n  Removed: %s out-of-scope records\n",
            format(n_oos_removed, big.mark = ",")))

# --- STEP 3: Missing Values ---
cat("\n============================================================\n")
cat("  STEP 3: MISSING VALUE IMPUTATION\n")
cat("============================================================\n")

for (col in c("hh_size", "head_age", "hh_income")) {
  n_miss <- sum(is.na(frame_inscope[[col]]))
  if (n_miss > 0) {
    cat(sprintf("  %-15s: %d missing (%.1f%%)\n",
                col, n_miss, n_miss / nrow(frame_inscope) * 100))

    # Impute with governorate median
    gov_medians <- tapply(frame_inscope[[col]], frame_inscope$gov_id,
                          median, na.rm = TRUE)
    for (g in names(gov_medians)) {
      mask <- is.na(frame_inscope[[col]]) & frame_inscope$gov_id == g
      frame_inscope[mask, col] <- gov_medians[g]
    }
  }
}

# --- STEP 4: Coverage ---
cat("\n============================================================\n")
cat("  STEP 4: COVERAGE ANALYSIS\n")
cat("============================================================\n")

external <- c(GOV_01 = 12000, GOV_02 = 9500, GOV_03 = 8800,
              GOV_04 = 7200, GOV_05 = 6500, GOV_06 = 5500)

frame_counts <- table(frame_inscope$gov_id)

for (g in names(external)) {
  fc <- ifelse(g %in% names(frame_counts), frame_counts[g], 0)
  cr <- fc / external[g] * 100
  status <- ifelse(cr >= 90 & cr <= 110, "OK", "WARNING")
  cat(sprintf("  %-8s: Frame=%6d, External=%6d, Coverage=%.1f%% [%s]\n",
              g, fc, external[g], cr, status))
}

# --- Summary ---
cat("\n============================================================\n")
cat("  FINAL SUMMARY\n")
cat("============================================================\n")
cat(sprintf("  Original      : %s\n", format(nrow(frame), big.mark = ",")))
cat(sprintf("  After cleaning: %s\n", format(nrow(frame_inscope), big.mark = ",")))

stopifnot(sum(is.na(frame_inscope$hh_size)) == 0)
stopifnot(sum(is.na(frame_inscope$head_age)) == 0)
stopifnot(sum(is.na(frame_inscope$hh_income)) == 0)
stopifnot(nrow(frame_inscope) < nrow(frame))
cat("\n[PASS] Frame cleaning completed.\n")

# ============================================================
# USE IT: Production Frame Cleaning Pipeline
# ============================================================

# In production, load the full 500K frame:
# frame <- read.csv('census_frame.csv')

# Production-grade pipeline using the same steps:
# 1. frame <- frame[!duplicated(frame[, key_cols]), ]
# 2. frame <- frame[frame$status == "Occupied", ]
# 3. Validate EA sizes:
#    ea_sizes <- table(frame$ea_id)
#    small_eas <- names(ea_sizes[ea_sizes < 30])
#    large_eas <- names(ea_sizes[ea_sizes > 200])
# 4. Export clean frame: write.csv(frame, 'clean_frame.csv')
