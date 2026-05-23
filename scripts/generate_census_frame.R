# ============================================================================
# generate_census_frame.R
# Synthetic National Census Frame Generator
# ============================================================================
# Purpose: Generate a realistic 500,000-household census frame with nested
#          geographic hierarchy (Governorate > District > Enumeration Area)
#          and socio-economic indicators for use in sampling exercises.
#
# Output:  census_frame.csv (500,000 rows)
# Usage:   Rscript scripts/generate_census_frame.R
# ============================================================================

cat("============================================================\n")
cat("  Synthetic Census Frame Generator v1.0\n")
cat("  Target: 500,000 Households\n")
cat("============================================================\n\n")

set.seed(2024)

# --- Configuration --------------------------------------------------------

TARGET_HH <- 500000

# Governorate definitions (12 governorates with varying urbanization)
governorates <- data.frame(
  gov_id   = sprintf("GOV_%02d", 1:12),
  gov_name = c("Al-Aasima", "Al-Shamal", "Al-Janoub", "Al-Sharq",
                "Al-Gharb", "Al-Wusta", "Al-Sahel", "Al-Jabal",
                "Al-Wadi", "Al-Sahra", "Al-Mina", "Al-Reef"),
  urban_pct   = c(0.92, 0.45, 0.38, 0.55, 0.50, 0.65, 0.78, 0.30,
                  0.35, 0.20, 0.85, 0.25),
  pop_share   = c(0.22, 0.08, 0.07, 0.10, 0.09, 0.12, 0.06, 0.05,
                  0.04, 0.03, 0.08, 0.06),
  stringsAsFactors = FALSE
)

# Normalize population shares to sum to 1
governorates$pop_share <- governorates$pop_share / sum(governorates$pop_share)

cat("[1/6] Generating governorate structure...\n")

# --- Step 1: Allocate households to governorates --------------------------

governorates$n_hh <- round(TARGET_HH * governorates$pop_share)
# Adjust to hit exact target
diff_hh <- TARGET_HH - sum(governorates$n_hh)
if (diff_hh != 0) {
  idx <- which.max(governorates$n_hh)
  governorates$n_hh[idx] <- governorates$n_hh[idx] + diff_hh
}

cat(sprintf("   Total households allocated: %s\n", format(sum(governorates$n_hh), big.mark = ",")))

# --- Step 2: Generate districts within governorates -----------------------

cat("[2/6] Generating district hierarchy...\n")

districts <- data.frame()
district_counter <- 0

for (i in 1:nrow(governorates)) {
  # Number of districts proportional to population (5-15 per governorate)
  n_dist <- max(5, min(15, round(governorates$n_hh[i] / 5000)))

  # Distribute HH across districts using Dirichlet-like allocation
  raw_shares <- rgamma(n_dist, shape = 2, rate = 1)
  dist_shares <- raw_shares / sum(raw_shares)
  dist_hh <- round(governorates$n_hh[i] * dist_shares)

  # Correct rounding error
  dist_hh[1] <- dist_hh[1] + (governorates$n_hh[i] - sum(dist_hh))

  for (j in 1:n_dist) {
    district_counter <- district_counter + 1
    districts <- rbind(districts, data.frame(
      gov_id    = governorates$gov_id[i],
      dist_id   = sprintf("DIST_%04d", district_counter),
      n_hh      = dist_hh[j],
      urban_pct = min(1, max(0, governorates$urban_pct[i] +
                                  rnorm(1, 0, 0.15))),
      stringsAsFactors = FALSE
    ))
  }
}

cat(sprintf("   Districts generated: %d\n", nrow(districts)))

# --- Step 3: Generate Enumeration Areas (EAs) within districts ------------

cat("[3/6] Generating enumeration areas (PSUs)...\n")

# Target: each EA should contain 80-150 households
EA_MIN <- 80
EA_MAX <- 150
EA_TARGET <- 110

eas <- data.frame()
ea_counter <- 0

for (i in 1:nrow(districts)) {
  # Number of EAs based on household count
  n_ea <- max(1, round(districts$n_hh[i] / EA_TARGET))
  ea_hh <- rep(floor(districts$n_hh[i] / n_ea), n_ea)
  ea_hh[1] <- ea_hh[1] + (districts$n_hh[i] - sum(ea_hh))

  for (j in 1:n_ea) {
    ea_counter <- ea_counter + 1
    is_urban <- runif(1) < districts$urban_pct[i]
    eas <- rbind(eas, data.frame(
      gov_id     = districts$gov_id[i],
      dist_id    = districts$dist_id[i],
      ea_id      = sprintf("EA_%06d", ea_counter),
      n_hh       = ea_hh[j],
      urban_rural = ifelse(is_urban, "Urban", "Rural"),
      stringsAsFactors = FALSE
    ))
  }
}

cat(sprintf("   Enumeration Areas generated: %s\n", format(nrow(eas), big.mark = ",")))

# --- Step 4: Generate household-level records -----------------------------

cat("[4/6] Generating household records (this may take a moment)...\n")

# Pre-allocate vectors for performance
total_hh <- sum(eas$n_hh)
hh_id      <- character(total_hh)
gov_id     <- character(total_hh)
dist_id    <- character(total_hh)
ea_id_vec  <- character(total_hh)
urban_rural <- character(total_hh)
hh_size    <- integer(total_hh)
n_children <- integer(total_hh)
hh_income  <- numeric(total_hh)
head_age   <- integer(total_hh)
head_sex   <- character(total_hh)
head_educ  <- character(total_hh)
employed   <- integer(total_hh)
has_water  <- integer(total_hh)
has_electricity <- integer(total_hh)

educ_levels <- c("None", "Primary", "Secondary", "University", "Postgraduate")

row_idx <- 0

for (i in 1:nrow(eas)) {
  n <- eas$n_hh[i]
  is_urban <- eas$urban_rural[i] == "Urban"

  for (j in 1:n) {
    row_idx <- row_idx + 1

    hh_id[row_idx]       <- sprintf("HH_%07d", row_idx)
    gov_id[row_idx]      <- eas$gov_id[i]
    dist_id[row_idx]     <- eas$dist_id[i]
    ea_id_vec[row_idx]   <- eas$ea_id[i]
    urban_rural[row_idx] <- eas$urban_rural[i]

    # Household size: Urban tends smaller
    if (is_urban) {
      hh_size[row_idx] <- max(1, rpois(1, lambda = 3.5))
    } else {
      hh_size[row_idx] <- max(1, rpois(1, lambda = 5.2))
    }

    # Children under 18
    n_children[row_idx] <- min(hh_size[row_idx] - 1,
                               max(0, rpois(1, lambda = ifelse(is_urban, 1.2, 2.5))))

    # Household head age
    head_age[row_idx] <- max(18, min(90, round(rnorm(1,
                              mean = ifelse(is_urban, 42, 45),
                              sd = 12))))

    # Head sex (Male-headed ~70%)
    head_sex[row_idx] <- sample(c("Male", "Female"), 1,
                                prob = c(0.70, 0.30))

    # Education (urban skews higher)
    if (is_urban) {
      head_educ[row_idx] <- sample(educ_levels, 1,
                                   prob = c(0.05, 0.15, 0.30, 0.35, 0.15))
    } else {
      head_educ[row_idx] <- sample(educ_levels, 1,
                                   prob = c(0.20, 0.35, 0.25, 0.15, 0.05))
    }

    # Employment status of head (binary)
    employed[row_idx] <- rbinom(1, 1,
                                prob = ifelse(is_urban, 0.65, 0.50))

    # Monthly household income (log-normal, urban higher)
    base_income <- ifelse(is_urban, 7.0, 6.2)
    hh_income[row_idx] <- round(rlnorm(1, meanlog = base_income,
                                       sdlog = 0.8), 2)

    # Infrastructure access
    has_water[row_idx]       <- rbinom(1, 1, prob = ifelse(is_urban, 0.95, 0.60))
    has_electricity[row_idx] <- rbinom(1, 1, prob = ifelse(is_urban, 0.99, 0.75))
  }
}

# --- Step 5: Assemble final data frame -----------------------------------

cat("[5/6] Assembling census frame...\n")

census_frame <- data.frame(
  hh_id           = hh_id,
  gov_id          = gov_id,
  dist_id         = dist_id,
  ea_id           = ea_id_vec,
  urban_rural     = urban_rural,
  hh_size         = hh_size,
  n_children      = n_children,
  head_age        = head_age,
  head_sex        = head_sex,
  head_education  = head_educ,
  head_employed   = employed,
  hh_monthly_income = hh_income,
  has_piped_water   = has_water,
  has_electricity   = has_electricity,
  stringsAsFactors = FALSE
)

# --- Step 6: Inject realistic imperfections (for frame cleaning exercises)

cat("[6/6] Injecting frame imperfections for training exercises...\n")

n_total <- nrow(census_frame)

# 1. Duplicate records (~0.5%)
n_dupes <- round(n_total * 0.005)
dupe_rows <- census_frame[sample(1:n_total, n_dupes, replace = TRUE), ]
dupe_rows$hh_id <- paste0(dupe_rows$hh_id, "_DUP")
census_frame <- rbind(census_frame, dupe_rows)

# 2. Missing values (~2% scattered across key columns)
na_cols <- c("hh_size", "head_age", "hh_monthly_income", "head_education")
for (col in na_cols) {
  na_idx <- sample(1:nrow(census_frame), round(nrow(census_frame) * 0.02))
  census_frame[na_idx, col] <- NA
}

# 3. Out-of-scope records: vacant/demolished (~1%)
n_vacant <- round(n_total * 0.01)
vacant_idx <- sample(1:nrow(census_frame), n_vacant)
census_frame$status <- "Occupied"
census_frame$status[vacant_idx] <- sample(c("Vacant", "Demolished", "Under_Construction"),
                                          n_vacant, replace = TRUE,
                                          prob = c(0.5, 0.3, 0.2))

# Shuffle rows
census_frame <- census_frame[sample(1:nrow(census_frame)), ]
rownames(census_frame) <- NULL

# --- Write output ---------------------------------------------------------

output_path <- "census_frame.csv"
write.csv(census_frame, output_path, row.names = FALSE, fileEncoding = "UTF-8")

cat("\n============================================================\n")
cat(sprintf("  Census frame generated successfully!\n"))
cat(sprintf("  Rows: %s (including %s duplicates)\n",
            format(nrow(census_frame), big.mark = ","),
            format(n_dupes, big.mark = ",")))
cat(sprintf("  Columns: %d\n", ncol(census_frame)))
cat(sprintf("  Governorates: %d\n", length(unique(census_frame$gov_id))))
cat(sprintf("  Districts: %d\n", length(unique(census_frame$dist_id))))
cat(sprintf("  Enumeration Areas: %s\n", format(length(unique(census_frame$ea_id)), big.mark = ",")))
cat(sprintf("  Output: %s\n", output_path))
cat("============================================================\n")

# --- Summary statistics ---------------------------------------------------

cat("\n--- Governorate Summary ---\n")
gov_summary <- aggregate(
  cbind(hh_count = hh_size) ~ gov_id,
  data = census_frame[census_frame$status == "Occupied", ],
  FUN = length
)
gov_summary <- gov_summary[order(-gov_summary$hh_count), ]
print(gov_summary, row.names = FALSE)

cat("\n--- Urban/Rural Split ---\n")
print(table(census_frame$urban_rural[census_frame$status == "Occupied"]))

cat("\nDone.\n")
