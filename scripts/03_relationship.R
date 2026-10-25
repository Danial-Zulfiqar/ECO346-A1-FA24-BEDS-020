# ============================================================================
# 03_relationship.R  -  Question 3 (and the redesign of Question 4):
# earnings vs age: every earner as a point + weighted band means
# ============================================================================
source("scripts/00_helpers.R")
library(svglite)

d <- load_earners()

# ---- Five-year bands 15-19, ..., 60-64; midpoint 17, 22, ..., 62 ------------
band_labels <- paste0(seq(15, 60, 5), "-", seq(19, 64, 5))
d <- d |>
  mutate(band = cut(age, breaks = seq(15, 65, 5), right = FALSE, labels = band_labels),
         mid  = as.integer(band) * 5 + 12)

tab <- d |>
  group_by(band, mid) |>
  summarise(n = n(), wmean = wmean(earn_annual, hhweight), .groups = "drop") |>
  mutate(thin = n < 30,                     # fewer than 30 unweighted observations
         wmean_rs = round(wmean))

print(as.data.frame(tab))
write_csv(tab, "results/band_table_R.csv")

top <- tab |> slice_max(wmean, n = 1)       # band with the highest weighted mean
cat("Highest weighted mean:", as.character(top$band), "Rs", top$wmean_rs, "\n")

# ---- Figure -----------------------------------------------------------------
g <- ggplot(d, aes(age, earn_annual)) +
  # every earner: semi-transparent, jittered horizontally by at most 0.4 years
  geom_point(alpha = 0.15, size = 0.9, colour = "grey25",
             position = position_jitter(width = 0.4, height = 0, seed = 1)) +
  # band means joined by a line; larger markers; hollow if the band is thin
  geom_line(data = tab, aes(mid, wmean), colour = "firebrick", linewidth = 0.9) +
  geom_point(data = tab, aes(mid, wmean, fill = thin), shape = 21, size = 3.8,
             colour = "firebrick", stroke = 1.1) +
  scale_fill_manual(values = c(`FALSE` = "firebrick", `TRUE` = "white"), guide = "none") +
  # direct annotation of the highest band
  annotate("text", x = min(top$mid, 58), y = top$wmean * 2.1, colour = "firebrick", fontface = "bold",
           label = paste0("Highest: ages ", top$band, "\nmean Rs ", comma(top$wmean_rs))) +
  scale_y_log10(breaks = RS_BREAKS, labels = RS_LABELS) +
  scale_x_continuous(breaks = seq(15, 65, 10)) +
  coord_cartesian(xlim = c(14, 65), ylim = c(1e4, 1e7)) +
  labs(title = paste0("Average earnings in ", LABEL, " peak at ages ", top$band,
                      " (Rs ", comma(top$wmean_rs), ")"),
       x = "Age (years)", y = "Annual earnings (log scale)",
       caption = paste0("Source: PSLM 2019-20. Sample: ", comma(nrow(d)), " earners aged 15-64 in ", LABEL, ".\n",
                        "Points: individual earners (jittered, transparent).\n",
                        "Markers: weighted mean of each five-year band (weights: hhweight).\n",
                        "Hollow markers = bands with fewer than 30 observations.")) +
  theme_minimal(base_size = 12) +
  theme(plot.title.position = "plot", plot.caption = element_text(hjust = 0),
        panel.grid.minor = element_blank(),
        plot.margin = margin(8, 16, 8, 8))

ggsave("figures/relationship.svg", g, width = 9, height = 5.5)
cat("Saved figures/relationship.svg\n")
