
# 03_literacy.R -- Question 3 and redesigned Question 4
# Weighted literacy rates by five-year age groups for men and women
# Variant 2: Rural Sindh
# Run from the repository root: Rscript scripts/03_literacy.R

# Load the required packages
library(ggplot2)
library(svglite)
library(dplyr)

# Verify that the required data file exists
if (!file.exists("data/pslm_person_subset.csv")) {
  stop("Please run this script from the repository root.")
}

# Create directories for saving the figure and results
dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

# Import person and household datasets
person_data <- read.csv("data/pslm_person_subset.csv")
household_data <- read.csv("data/pslm_hh_subset.csv")

# Retain the required household information
household_data <- household_data[
  , c("hhid", "hhweight", "prov_code", "urban_rural")
]

# Join the datasets using the household identifier
merged_data <- merge(
  person_data,
  household_data,
  by = "hhid",
  all.x = TRUE
)

# Select rural Sindh residents aged 10-64 with available literacy data
literacy_data <- merged_data[
  merged_data$prov_code == 3 &
    merged_data$urban_rural == 1 &
    merged_data$age >= 10 &
    merged_data$age <= 64 &
    !is.na(merged_data$literate),
]

# Assign five-year age groups and their midpoints
literacy_data$age_group_start <- floor(literacy_data$age / 5) * 5
literacy_data$age_midpoint <- literacy_data$age_group_start + 2

# Convert the sex variable into readable labels
literacy_data$gender <- ifelse(
  literacy_data$sex == 1,
  "Men",
  "Women"
)

# Calculate sample counts and weighted literacy percentages
age_gender_stats <- literacy_data |>
  group_by(age_group_start, age_midpoint, gender) |>
  summarise(
    sample_count = n(),
    literacy_percent = 100 * sum(hhweight * literate) / sum(hhweight),
    .groups = "drop"
  ) |>
  mutate(
    small_sample = sample_count < 30
  )

# Separate the results for women and men
female_stats <- age_gender_stats[
  age_gender_stats$gender == "Women",
  c("age_group_start", "age_midpoint", "sample_count", "literacy_percent")
]

male_stats <- age_gender_stats[
  age_gender_stats$gender == "Men",
  c("age_group_start", "age_midpoint", "sample_count", "literacy_percent")
]

# Combine both groups into a single age-band table
age_comparison <- merge(
  female_stats,
  male_stats,
  by = c("age_group_start", "age_midpoint"),
  suffixes = c("_women", "_men")
)

# Add age-band labels and calculate the gender literacy gap
age_comparison$age_band <- paste0(
  age_comparison$age_group_start,
  "-",
  age_comparison$age_group_start + 4
)

age_comparison$gender_gap <-
  age_comparison$literacy_percent_men -
  age_comparison$literacy_percent_women

# Arrange the table in ascending age order
age_comparison <- age_comparison[
  order(age_comparison$age_group_start),
  c(
    "age_band",
    "age_midpoint",
    "sample_count_women",
    "literacy_percent_women",
    "sample_count_men",
    "literacy_percent_men",
    "gender_gap"
  )
]

# Assign clear column names
names(age_comparison) <- c(
  "band",
  "mid",
  "n_women",
  "rate_women",
  "n_men",
  "rate_men",
  "gap"
)

# Round percentages and gaps to one decimal place
results_table <- age_comparison

results_table[, c("rate_women", "rate_men", "gap")] <-
  round(results_table[, c("rate_women", "rate_men", "gap")], 1)

# Export the age-group comparison table
write.csv(
  results_table,
  "tables/band_table_R.csv",
  row.names = FALSE
)

# Display the calculated table
print(results_table)

# Retrieve selected values for the Google Form
get_rate <- function(age_band, column_name) {
  sprintf(
    "%.1f",
    age_comparison[[column_name]][age_comparison$age_band == age_band]
  )
}

cat(
  "Women 15-19:", get_rate("15-19", "rate_women"),
  " Men 15-19:", get_rate("15-19", "rate_men"), "\n"
)

cat(
  "Women 55-59:", get_rate("55-59", "rate_women"),
  " Men 55-59:", get_rate("55-59", "rate_men"), "\n"
)

# Identify the age group with the largest literacy gap
largest_gap_row <- age_comparison[
  which.max(age_comparison$gap),
]

cat(
  "Largest gap:", largest_gap_row$band,
  "=", sprintf("%.1f", largest_gap_row$gap),
  "points\n"
)

cat(
  "Literacy sample size:", nrow(literacy_data),
  " Smallest cell:", min(age_gender_stats$sample_count),
  "\n"
)

# Prepare labels and colours for the visualization
age_labels <- paste0(
  seq(10, 60, 5),
  "-",
  seq(14, 64, 5)
)

gender_colours <- c(
  Women = "#b5532a",
  Men = "#1f4e79"
)

# Select the final observation for each gender's line
last_age_points <- age_gender_stats[
  age_gender_stats$age_midpoint == 62,
]

# Find the vertical midpoint of the largest gap
gap_label_position <-
  (largest_gap_row$rate_women + largest_gap_row$rate_men) / 2

# Prepare the figure caption
figure_caption <- paste0(
  "Source: PSLM 2019-20, person file merged with household file. ",
  "Sample: persons aged 10-64 in rural Sindh with non-missing literacy (n = ",
  format(nrow(literacy_data), big.mark = ","), ").\n",
  "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n",
  "Hollow markers: cells with fewer than 30 observations",
  if (any(age_gender_stats$small_sample)) {
    "."
  } else {
    " (none in this sample)."
  }
)

# Construct the literacy comparison graph
literacy_plot <- ggplot(
  age_gender_stats,
  aes(
    x = age_midpoint,
    y = literacy_percent,
    colour = gender,
    group = gender
  )
) +
  geom_line(linewidth = 0.9) +
  geom_point(
    aes(shape = small_sample),
    size = 3.2,
    stroke = 1.1,
    fill = "white"
  ) +
  scale_shape_manual(
    values = c("FALSE" = 16, "TRUE" = 21),
    guide = "none"
  ) +
  scale_colour_manual(
    values = gender_colours,
    guide = "none"
  ) +

  # Place gender labels beside the final points
  geom_text(
    data = last_age_points,
    aes(label = gender),
    hjust = 0,
    nudge_x = 1,
    fontface = "bold",
    size = 4.2
  ) +

  # Highlight the age group with the largest literacy difference
  geom_segment(
    data = largest_gap_row,
    aes(
      x = mid,
      xend = mid,
      y = rate_women,
      yend = rate_men
    ),
    inherit.aes = FALSE,
    colour = "grey30",
    arrow = arrow(
      ends = "both",
      length = unit(0.08, "inches")
    )
  ) +
  annotate(
    "text",
    x = largest_gap_row$mid + 1,
    y = gap_label_position,
    hjust = 0,
    size = 3.8,
    colour = "grey20",
    label = paste0(
      "Largest gap, ages ", largest_gap_row$band, ":\n",
      sprintf("%.1f", largest_gap_row$gap),
      " points"
    )
  ) +
  scale_x_continuous(
    breaks = seq(12, 62, 5),
    labels = age_labels,
    limits = c(10, 70),
    expand = expansion(0)
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title = paste0(
      "In rural Sindh, men are at least 22 percentage points more literate\n",
      "than women in every age band"
    ),
    x = "Age band (years)",
    y = "Literate (weighted %)",
    caption = figure_caption
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

# Save the final visualization as an SVG file
ggsave(
  filename = "figures/literacy_by_age.svg",
  plot = literacy_plot,
  width = 9,
  height = 5.8
)
