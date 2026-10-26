
# 02_distribution.R -- Question 2: weighted histogram of education spending.
# Variant 6 = Balochistan rural.
# Run from the repository root: Rscript scripts/02_distribution.R

library(ggplot2)
library(svglite)

if (!file.exists("data/pslm_person_subset.csv")) {
  stop("Run this script from the repository root.")
}

dir.create("figures", showWarnings = FALSE)

# --- Merge household weight, province and area onto persons ---
pp <- read.csv("data/pslm_person_subset.csv")
hh <- read.csv("data/pslm_hh_subset.csv")

hh <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]

d <- merge(pp, hh, by = "hhid", all.x = TRUE)

# --- Select students from rural Balochistan with ed_total > 0 ---
students <- d[
  d$prov_code == 4 &
    d$urban_rural == 1 &
    !is.na(d$ed_total) &
    d$ed_total > 0,
]

# --- Calculate weighted quantiles using the assignment's definition ---
wquantile <- function(x, w, p) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  cum <- cumsum(w) / sum(w)
  x[which(cum >= p)[1]]
}

n_students <- nrow(students)

w_median <- wquantile(
  students$ed_total, students$hhweight, 0.5
)

u_median <- median(students$ed_total)

p10 <- wquantile(
  students$ed_total, students$hhweight, 0.1
)

p90 <- wquantile(
  students$ed_total, students$hhweight, 0.9
)

ratio <- p90 / p10

# --- Identify students outside the histogram's spending range ---
n_excluded <- sum(
  students$ed_total < 100 | students$ed_total > 1e6
)

in_range <- students[
  students$ed_total >= 100 &
    students$ed_total <= 1e6,
]

# --- Print the results ---
cat("Number of students:        ", n_students, "\n")
cat("Weighted median (Rs):      ", w_median, "\n")
cat("Unweighted median (Rs):    ", u_median, "\n")
cat("Weighted 10th pct (Rs):    ", p10, "\n")
cat("Weighted 90th pct (Rs):    ", p90, "\n")
cat("p90 / p10 ratio:           ", sprintf("%.2f", ratio), "\n")
cat("Excluded from histogram:   ", n_excluded, "\n")

fmt <- function(x) {
  format(
    round(x),
    big.mark = ",",
    scientific = FALSE,
    trim = TRUE
  )
}

# --- Create a weighted histogram with a log10 scale ---
p0 <- ggplot(
  in_range,
  aes(x = ed_total, weight = hhweight)
) +
  geom_histogram(
    aes(y = after_stat(density)),
    binwidth = 0.1,
    boundary = 2,
    closed = "left",
    fill = "#1f4e79",
    colour = "white"
  ) +
  scale_x_log10(
    breaks = 10^(2:6),
    labels = c(
      "Rs 100",
      "Rs 1,000",
      "Rs 10,000",
      "Rs 100,000",
      "Rs 1,000,000"
    )
  )

# --- Check whether the histogram density integrates to 1 ---
b <- ggplot_build(p0)$data[[1]]

cat(
  "Area under histogram (should be 1):",
  round(sum(b$density * (b$xmax - b$xmin)), 4),
  "\n"
)

ymax <- max(b$density)

# --- Add weighted median and 90th percentile lines ---
p <- p0 +
  geom_vline(
    xintercept = c(w_median, p90),
    linetype = "dashed",
    colour = "#b5532a",
    linewidth = 0.7
  ) +
  annotate(
    "text",
    x = w_median,
    y = ymax * 1.12,
    hjust = 1.08,
    vjust = 0,
    colour = "#b5532a",
    fontface = "bold",
    size = 3.8,
    label = paste0(
      "Weighted median\nRs ",
      fmt(w_median)
    )
  ) +
  annotate(
    "text",
    x = p90,
    y = ymax * 1.12,
    hjust = -0.08,
    vjust = 0,
    colour = "#b5532a",
    fontface = "bold",
    size = 3.8,
    label = paste0(
      "90th percentile\nRs ",
      fmt(p90)
    )
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.25))
  ) +
  labs(
    title = paste0(
      "The middle 80% of rural Balochistan's students cost their families\n",
      "between Rs ", fmt(p10), " and Rs ", fmt(p90), " a year"
    ),
    x = "Annual spending on the student's education (rupees, log scale)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019-20, person file merged with household file. ",
      "Sample: ", fmt(n_students),
      " students (ed_total > 0), rural Balochistan.\n",
      n_excluded,
      " student(s) outside Rs 100 - Rs 1,000,000 excluded from the histogram.\n",
      "Weighted by hhweight; bins 0.1 wide in log10 units."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(
      hjust = 0,
      size = 9,
      colour = "grey30"
    ),
    plot.title = element_text(face = "bold")
  )

# --- Save the histogram as an SVG file ---
ggsave(
  "figures/distribution.svg",
  p,
  width = 9,
  height = 5.8
)
