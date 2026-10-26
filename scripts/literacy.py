
"""
04_second_language.py -- Question 5: Recreate the age-band table and literacy chart in Python.
Variant 2: Rural Sindh (prov_code 3, urban_rural 1).
Run from the repository root: python scripts/04_second_language.py
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Define the repository directory and prepare output folders
project_dir = Path(__file__).resolve().parent.parent
(project_dir / "figures").mkdir(exist_ok=True)
(project_dir / "tables").mkdir(exist_ok=True)

# Import person-level and household-level records
person_df = pd.read_csv(project_dir / "data" / "pslm_person_subset.csv")

household_df = pd.read_csv(
    project_dir / "data" / "pslm_hh_subset.csv",
    usecols=["hhid", "hhweight", "prov_code", "urban_rural"]
)

# Join household information to each person's record
merged_df = person_df.merge(
    household_df,
    on="hhid",
    how="left"
)

# Select literate-status observations for rural Sindh residents aged 10-64
literacy_df = merged_df[
    (merged_df["prov_code"] == 3) &
    (merged_df["urban_rural"] == 1) &
    merged_df["age"].between(10, 64) &
    merged_df["literate"].notna()
].copy()

# Assign five-year age groups and calculate their midpoints
# Floor division ensures that ages are grouped into the intended intervals
literacy_df["group_start"] = (literacy_df["age"] // 5) * 5
literacy_df["group_midpoint"] = literacy_df["group_start"] + 2

# Calculate sample sizes and weighted literacy percentages for each age group
age_group_results = []

for start_age, group_data in literacy_df.groupby("group_start"):
    result = {
        "band": f"{start_age}-{start_age + 4}",
        "mid": start_age + 2
    }

    # Calculate separate statistics for women and men
    for sex_code, gender in [(2, "women"), (1, "men")]:
        gender_data = group_data[group_data["sex"] == sex_code]

        result[f"n_{gender}"] = len(gender_data)

        result[f"rate_{gender}"] = (
            100 * np.average(
                gender_data["literate"],
                weights=gender_data["hhweight"]
            )
        )

    # Measure the difference between men's and women's literacy rates
    result["gap"] = result["rate_men"] - result["rate_women"]

    age_group_results.append(result)

# Convert the calculated results into a DataFrame
literacy_table = pd.DataFrame(age_group_results)

# Arrange the columns in the required order
literacy_table = literacy_table[
    [
        "band",
        "mid",
        "n_women",
        "rate_women",
        "n_men",
        "rate_men",
        "gap"
    ]
]

# Round percentages and differences for the final output
rounded_table = literacy_table.copy()

rounded_table[["rate_women", "rate_men", "gap"]] = (
    rounded_table[["rate_women", "rate_men", "gap"]].round(1)
)

# Save the results as a CSV file and display the table
rounded_table.to_csv(
    project_dir / "tables" / "band_table_python.csv",
    index=False
)

print(rounded_table.to_string(index=False))

# Retrieve specific literacy rates for the Google Form
def get_literacy_rate(age_band, column):
    selected_rate = literacy_table.loc[
        literacy_table["band"] == age_band,
        column
    ].iloc[0]

    return f"{selected_rate:.1f}"


print(
    "Women 15-19 (Python):",
    get_literacy_rate("15-19", "rate_women")
)

print(
    "Women 55-59:",
    get_literacy_rate("55-59", "rate_women"),
    " Men 15-19:",
    get_literacy_rate("15-19", "rate_men"),
    " Men 55-59:",
    get_literacy_rate("55-59", "rate_men")
)

# Find the age group with the greatest gender literacy gap
maximum_gap = literacy_table.loc[literacy_table["gap"].idxmax()]

print(
    "Largest gap:",
    maximum_gap["band"],
    f"{maximum_gap['gap']:.1f}",
    "points"
)

# Check whether the Python results agree with the R output
r_results_path = project_dir / "tables" / "band_table_R.csv"

if r_results_path.exists():
    r_table = pd.read_csv(r_results_path)

    largest_difference = max(
        (r_table[column] - rounded_table[column]).abs().max()
        for column in ["rate_women", "rate_men"]
    )

    matching_counts = (
        (r_table["n_women"] == rounded_table["n_women"]).all()
        and
        (r_table["n_men"] == rounded_table["n_men"]).all()
    )

    print(
        f"R vs Python: maximum absolute rate difference = "
        f"{largest_difference:.4f}; same sample counts: {matching_counts}"
    )

else:
    print(
        "R results were not found. Run scripts/03_literacy.R "
        "before comparing the two tables."
    )

# Define colours for the two gender groups
gender_palette = {
    "Women": "#b5532a",
    "Men": "#1f4e79"
}

# Initialize the figure and plotting area
fig, ax = plt.subplots(figsize=(9, 5.8))

# Draw a separate line and markers for each gender
for gender_label, gender_key in [("Women", "women"), ("Men", "men")]:
    x_values = literacy_table["mid"]
    y_values = literacy_table[f"rate_{gender_key}"]

    # Identify age groups containing fewer than 30 observations
    small_group = literacy_table[f"n_{gender_key}"] < 30

    # Connect literacy rates across age groups
    ax.plot(
        x_values,
        y_values,
        color=gender_palette[gender_label],
        lw=2,
        zorder=2
    )

    # Display regular observations using filled markers
    ax.scatter(
        x_values[~small_group],
        y_values[~small_group],
        s=55,
        color=gender_palette[gender_label],
        zorder=3
    )

    # Use hollow markers for groups with small sample sizes
    ax.scatter(
        x_values[small_group],
        y_values[small_group],
        s=55,
        facecolor="white",
        edgecolor=gender_palette[gender_label],
        lw=1.6,
        zorder=3
    )

    # Label each line at its final age-group point
    ax.text(
        x_values.iloc[-1] + 1,
        y_values.iloc[-1],
        gender_label,
        color=gender_palette[gender_label],
        fontweight="bold",
        fontsize=12,
        va="center"
    )

# Mark the largest difference between the two literacy rates
ax.annotate(
    "",
    xy=(maximum_gap["mid"], maximum_gap["rate_men"]),
    xytext=(maximum_gap["mid"], maximum_gap["rate_women"]),
    arrowprops=dict(arrowstyle="<->", color="0.3")
)

# Add a label describing the largest gap
ax.text(
    maximum_gap["mid"] + 1,
    (maximum_gap["rate_men"] + maximum_gap["rate_women"]) / 2,
    f"Largest gap, ages {maximum_gap['band']}:\n"
    f"{maximum_gap['gap']:.1f} points",
    fontsize=10.5,
    va="center",
    color="0.15"
)

# Set axis limits and age-group labels to match the R chart
ax.set_ylim(-5, 105)
ax.set_xlim(10, 70)

ax.set_xticks(range(12, 63, 5))
ax.set_xticklabels([
    f"{age}-{age + 4}"
    for age in range(10, 61, 5)
])

# Format the vertical axis as percentages
ax.set_yticks(range(0, 101, 20))
ax.set_yticklabels([
    f"{percentage}%"
    for percentage in range(0, 101, 20)
])

# Add axis titles and gridlines
ax.set_xlabel("Age band (years)")
ax.set_ylabel("Literate (weighted %)")

ax.grid(axis="y", color="0.88", lw=0.8)
ax.grid(axis="x", color="0.88", lw=0.8)
ax.set_axisbelow(True)

# Remove the plot borders for a cleaner appearance
for border in ["top", "right", "left", "bottom"]:
    ax.spines[border].set_visible(False)

ax.tick_params(length=0)

# Add the main heading
fig.suptitle(
    "In rural Sindh, men are at least 22 percentage points more literate\n"
    "than women in every age band",
    x=0.01,
    ha="left",
    fontweight="bold",
    fontsize=13
)

# Check whether any age group has fewer than 30 observations
has_small_groups = (
    (literacy_table["n_women"] < 30) |
    (literacy_table["n_men"] < 30)
).any()

# Prepare the chart's source and sample description
figure_note = (
    "Source: PSLM 2019-20, person file merged with household file. "
    f"Sample: persons aged 10-64 in rural Sindh with non-missing literacy "
    f"(n = {len(literacy_df):,}).\n"
    "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n"
    "Hollow markers: cells with fewer than 30 observations"
    + ("." if has_small_groups else " (none in this sample).")
)

fig.text(
    0.01,
    0.01,
    figure_note,
    fontsize=8.5,
    color="0.3",
    ha="left",
    va="bottom"
)

# Adjust spacing so the title and caption fit properly
fig.subplots_adjust(
    left=0.08,
    right=0.97,
    top=0.85,
    bottom=0.22
)

# Export the final chart as an SVG file
fig.savefig(
    project_dir / "figures" / "literacy_by_age_python.svg"
)
