# ============================================================================
# 02_distribution.R  -  Question 2: weighted histogram of earnings (log10 bins)
# ============================================================================
source("scripts/00_helpers.R")
library(svglite)

d <- load_earners()
x <- d$earn_annual
w <- d$hhweight

# ---- Numbers to report (computed on ALL earners in my variant) --------------
n_earners <- nrow(d)
med_w     <- wq(x, w, 0.50)          # weighted median
med_u     <- median(x)               # unweighted median
p10       <- wq(x, w, 0.10)
p90       <- wq(x, w, 0.90)
ratio     <- round(p90 / p10, 2)

# ---- Histogram sample: only earners with Rs 10,000 <= earnings <= Rs 10,000,000
h <- d |>
  filter(earn_annual >= 1e4, earn_annual <= 1e7) |>
  mutate(lx = log10(earn_annual))
n_excluded <- n_earners - nrow(h)

# ---- Bins 0.1 wide in log10 units from 4.0 to 7.0 (= 30 bins) ----------------
# bin 0 = [4.0, 4.1), ..., bin 29 = [6.9, 7.0]  (7.0 itself goes in the last bin)
bins <- h |>
  mutate(bin = pmin(floor((lx - 4) / 0.1 + 1e-9), 29)) |>
  group_by(bin) |>
  summarise(wsum = sum(hhweight), .groups = "drop") |>
  mutate(density = wsum / sum(wsum) / 0.1,          # share of weight per log10 unit
         xmin = 4 + bin * 0.1,
         xmax = xmin + 0.1)

cat(sprintf("earners=%d | weighted median=%s | unweighted median=%s | p10=%s | p90=%s | ratio=%.2f | excluded=%d\n",
            n_earners, med_w, med_u, p10, p90, ratio, n_excluded))

write_csv(data.frame(variant = VARIANT, label = LABEL, n_earners = n_earners,
                     median_weighted = med_w, median_unweighted = med_u,
                     p10 = p10, p90 = p90, ratio = ratio, n_excluded = n_excluded),
          "results/q2_numbers.csv")

# ---- Figure -----------------------------------------------------------------
ytop <- max(bins$density) * 1.18
g <- ggplot(bins) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = density),
            fill = "grey55", colour = "white") +
  geom_vline(xintercept = log10(c(med_w, p90)), linetype = "dashed", colour = "firebrick") +
  annotate("text", x = log10(med_w), y = ytop * 0.96, hjust = 1.12, vjust = 1, colour = "firebrick",
           label = paste0("Weighted median\nRs ", comma(round(med_w)))) +
  annotate("text", x = log10(p90), y = ytop * 0.96, hjust = -0.12, vjust = 1, colour = "firebrick",
           label = paste0("90th percentile\nRs ", comma(round(p90)))) +
  scale_x_continuous(breaks = 4:7, labels = RS_LABELS, limits = c(4, 7)) +
  scale_y_continuous(limits = c(0, ytop), expand = c(0, 0)) +
  labs(title = paste0("The top-decile cutoff in ", LABEL, " is ", format(ratio, nsmall = 2),
                      " times the bottom-decile cutoff"),
       x = "Annual earnings (log scale)",
       y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20. Sample: ", comma(n_earners), " earners aged 15-64 in ", LABEL, ".\n",
                        "Excluded from the histogram: ", n_excluded, " ", ifelse(n_excluded == 1, "earner", "earners"),
                        " outside Rs 10,000 - Rs 10,000,000.\n",
                        "Weighted by hhweight; percentiles use the cumulative-weight definition.")) +
  theme_minimal(base_size = 12) +
  theme(plot.title.position = "plot", plot.caption = element_text(hjust = 0),
        panel.grid.minor = element_blank(),
        plot.margin = margin(8, 24, 8, 8))

ggsave("figures/distribution.svg", g, width = 9, height = 5.5)
cat("Saved figures/distribution.svg\n")
