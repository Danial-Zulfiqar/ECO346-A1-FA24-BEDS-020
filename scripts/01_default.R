# ============================================================================
# 01_default.R  -  Question 4, part 1: R's DEFAULT scatterplot (nothing added)
# ============================================================================
source("scripts/00_helpers.R")
library(svglite)

d <- load_earners()

p <- ggplot(d, aes(age, earn_annual)) + geom_point()   # R's defaults, untouched

ggsave("figures/default.svg", p)
cat("Saved figures/default.svg with", nrow(d), "earners\n")
