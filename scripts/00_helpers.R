# ============================================================================
# 00_helpers.R  -  shared setup: variant, sample, weighted statistics
# Run all scripts from the REPOSITORY ROOT (the folder containing data/ and scripts/).
# In RStudio: open ECO346-A1.Rproj, or use Session > Set Working Directory.
# ============================================================================
suppressPackageStartupMessages({
  library(dplyr)    # filter / group_by / summarise
  library(readr)    # read_csv
  library(ggplot2)  # figures
  library(scales)   # comma()
})

if (!file.exists("data/pslm_person_subset.csv")) {
  stop("Working directory is wrong. Set it to the repository root (the folder that contains data/ and scripts/).")
}
dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

# ---- 1. Variant: last two digits of the registration number, mod 8 ----------
REG     <- trimws(readLines("reg.txt", warn = FALSE)[1])          # e.g. "FA24-BEDS-037"
DIGITS  <- as.integer(sub(".*?([0-9]{2})$", "\\1", REG))          # 37
VARIANT <- DIGITS %% 8                                            # 37 %% 8 = 5

variants <- data.frame(
  variant     = 0:7,
  prov_code   = c(2, 2, 3, 3, 1, 1, 4, 4),
  urban_rural = c(1, 2, 1, 2, 1, 2, 1, 2),
  label       = c("Punjab rural", "Punjab urban", "Sindh rural", "Sindh urban",
                  "KP rural", "KP urban", "Balochistan rural", "Balochistan urban")
)
PROV  <- variants$prov_code[variants$variant == VARIANT]
AREA  <- variants$urban_rural[variants$variant == VARIANT]
LABEL <- variants$label[variants$variant == VARIANT]

# ---- 2. Sample: earners aged 15-64 with earn_annual > 0 in my variant -------
load_earners <- function() {
  person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE,
                     col_select = c(hhid, age, earn_annual))
  hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE,
                     col_select = c(hhid, hhweight, prov_code, urban_rural))
  stopifnot(!anyDuplicated(hh$hhid))                  # one row per household
  d <- inner_join(person, hh, by = "hhid")            # attach weight, province, area
  stopifnot(nrow(d) == nrow(person))                  # every person found a household
  d |>
    filter(prov_code == PROV, urban_rural == AREA,    # my variant only
           age >= 15, age <= 64,                      # working age
           earn_annual > 0)                           # earners (NA drops out here)
}

# ---- 3. Weighted statistics, exactly as defined in the assignment -----------
# Weighted p-th quantile: sort by x, cumulative share of weight, smallest x whose share >= p
wq <- function(x, w, p) {
  o <- order(x)
  x <- x[o]; w <- w[o]
  share <- cumsum(w) / sum(w)
  x[which(share >= p)[1]]
}
# Weighted mean: sum(w*x) / sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# ---- 4. Rupee labels used on both figures -----------------------------------
RS_BREAKS <- 10^(4:7)
RS_LABELS <- c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")
