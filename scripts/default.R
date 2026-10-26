
# 01_default.R -- Question 4: Create a basic scatterplot using default settings
# Variant 2: Rural Sindh (prov_code 3, urban_rural 1)
# Execute from the repository's root directory

library(ggplot2)
library(svglite)

# Check whether the required data files are available
if (!file.exists("data/pslm_person_subset.csv")) {
  stop("Please run this script from the repository root directory.")
}

# Prepare the folder for saving figures
dir.create("figures", showWarnings = FALSE)

# Import the person-level and household-level datasets
person_data <- read.csv("data/pslm_person_subset.csv")
household_data <- read.csv("data/pslm_hh_subset.csv")

# Select the household variables needed for analysis
household_data <- household_data[
  , c("hhid", "hhweight", "prov_code", "urban_rural")
]

# Combine both datasets using the household ID
combined_data <- merge(
  person_data,
  household_data,
  by = "hhid",
  all.x = TRUE
)

# Filter the literacy data for rural Sindh residents aged 10 to 64
literacy_data <- combined_data[
  combined_data$prov_code == 3 &
    combined_data$urban_rural == 1 &
    combined_data$age >= 10 &
    combined_data$age <= 64 &
    !is.na(combined_data$literate),
]

# Display the number of observations in the selected sample
cat("Literacy sample size:", nrow(literacy_data), "\n")

# Draw the default scatterplot of literacy against age
scatter_plot <- ggplot(
  literacy_data,
  aes(x = age, y = literate)
) +
  geom_point()

# Save the scatterplot as an SVG file
ggsave(
  filename = "figures/default.svg",
  plot = scatter_plot
)
