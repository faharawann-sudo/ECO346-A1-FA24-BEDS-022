# ECO346 Assignment 1 — Data Visualization Techniques for Economists

## Variant and Study Area

* **Course:** ECO346 — Data Visualization Techniques for Economists
* **Semester:** Fall 2026
* **Section:** B
* **Registration Number:** FA24-BEDS-022
* **Variant:** 6
* **Province:** Balochistan
* **Area:** Rural
* **Dataset:** Pakistan Social and Living Standards Measurement Survey (PSLM) 2019–20

This assignment examines annual education spending among students and differences in literacy rates between women and men across age groups in rural Balochistan. R is used for the education-spending distribution, literacy analysis, and figure redesign. Python is used to reproduce the literacy age-band table and figure.

## Repository Structure

```text
ECO346-A1-FA24-BEDS-022/
│
├── data/
│   ├── pslm_person_subset.csv
│   └── pslm_hh_subset.csv
│
├── scripts/
│   ├── 01_default.R
│   ├── 02_distribution.R
│   ├── 03_literacy.R
│   └── literacy.py
│
├── figures/
│   ├── default.svg
│   ├── distribution.svg
│   ├── literacy_by_age.svg
│   └── literacy_by_age_python.svg
│
├── tables/
│   ├── band_table_R.csv
│   └── band_table_python.csv
│
├── slides/
│   └── FA24-BEDS-022.pptx
│
└── README.md
```

## Question 1 — Repository

The project is organized into separate folders for data, scripts, figures, tables, and presentation slides. The analysis scripts use the local PSLM CSV files and save their outputs in the repository.

The figures are saved in SVG format, and the literacy tables are saved as CSV files. This structure keeps the project organized and allows the results to be checked against the scripts.

## Question 2 — Distribution of Education Spending

### Figure

[View the weighted education-spending histogram](figures/distribution.svg)

### Results

| Statistic                            |    Result |
| ------------------------------------ | --------: |
| Number of students                   |     1,464 |
| Weighted median education spending   |  Rs 3,500 |
| Unweighted median education spending |  Rs 3,000 |
| Weighted 10th percentile             |    Rs 600 |
| Weighted 90th percentile             | Rs 18,700 |
| 90th-to-10th percentile ratio        |     31.17 |
| Observations excluded from histogram |         1 |
| Area under the histogram             |         1 |

### Interpretation

The weighted median annual education spending is Rs 3,500, compared with the unweighted median of Rs 3,000. The 90th percentile is Rs 18,700, while the 10th percentile is Rs 600, indicating substantial variation in spending. The weighted median differs because household weights account for how many people each observation represents, whereas the unweighted median treats every observed student equally.

## Question 3 — Literacy Rates by Age and Sex

### Figure

[View the redesigned literacy-by-age figure in R](figures/literacy_by_age.svg)

### Literacy Sample

The analysis includes **5,677 persons** aged 10–64 whose literacy status is not missing. The sample is restricted to rural Balochistan. Literacy rates are weighted using household weights.

### Complete Age-Band Table

The following table reports the number of women and men in each age band, their weighted literacy rates, and the difference between the rates.

| Age band | Midpoint | Women (n) | Women literacy (%) | Men (n) | Men literacy (%) | Gap (percentage points) |
| -------- | -------: | --------: | -----------------: | ------: | ---------------: | ----------------------: |
| 10–14    |       12 |       428 |               40.9 |     663 |             60.1 |                    19.2 |
| 15–19    |       17 |       293 |               33.3 |     477 |             63.8 |                    30.6 |
| 20–24    |       22 |       307 |               22.8 |     358 |             61.7 |                    38.9 |
| 25–29    |       27 |       347 |               24.8 |     355 |             56.5 |                    31.8 |
| 30–34    |       32 |       309 |               15.1 |     297 |             52.9 |                    37.9 |
| 35–39    |       37 |       252 |               15.0 |     266 |             53.8 |                    38.7 |
| 40–44    |       42 |       198 |                7.5 |     227 |             55.4 |                    47.9 |
| 45–49    |       47 |       149 |                8.2 |     181 |             32.7 |                    24.6 |
| 50–54    |       52 |       111 |               14.9 |     133 |             27.0 |                    12.0 |
| 55–59    |       57 |        79 |                3.5 |      95 |             39.7 |                    36.3 |
| 60–64    |       62 |        59 |                1.0 |      93 |             39.8 |                    38.9 |

**Women aged 15–19:** 33.3%

**Men aged 15–19:** 63.8%

**Women aged 55–59:** 3.5%

**Men aged 55–59:** 39.7%

**Largest literacy gap:** The 40–44 age band, with a gap of 47.9 percentage points.

### Economic Interpretation

The results show a substantial gender gap in literacy in rural Balochistan. In every age band, the weighted literacy rate for men is higher than that for women. The largest difference occurs among people aged 40–44, at 47.9 percentage points. The pattern suggests unequal educational outcomes between women and men across generations. However, these descriptive results cannot establish the causes of the gender gap or prove that age itself causes differences in literacy.

## Question 4 — The Makeover

### Figures

* [View the original default scatterplot](figures/default.svg)
* [View the redesigned literacy figure](figures/literacy_by_age.svg)

### Explanation of the Redesign

The default scatterplot displays individual literacy observations against age. Although it shows individual data points, overlapping observations make it difficult to compare literacy patterns between women and men.

The redesign makes three important changes. First, it uses separate series for women and men, making gender differences easier to identify. Second, it displays weighted literacy rates for five-year age bands instead of relying on a large collection of individual points. This reduces overplotting and summarizes the conditional means of literacy across age groups. Third, it labels the series directly and highlights the age band with the largest gap, reducing the need for a separate legend and helping readers focus on the main finding.

These changes improve visual hierarchy, reduce unnecessary visual clutter, and make comparisons easier. However, unlike the default scatterplot, the redesign does not show every individual observation.

## Question 5 — Reproduction in Python

### Python Script and Outputs

* [View the Python script](scripts/literacy.py)
* [View the Python literacy figure](figures/literacy_by_age_python.svg)
* [View the R literacy table](tables/band_table_R.csv)
* [View the Python literacy table](tables/band_table_python.csv)

### Women’s Literacy Rate: Ages 15–19

| Software | Weighted literacy rate |
| -------- | ---------------------: |
| R        |                  33.3% |
| Python   |                  33.3% |

The R and Python tables agree to one decimal place for the displayed age bands.

### Difference Between R and Python Defaults

R's ggplot2 and Python's Matplotlib can use different default figure dimensions, fonts, margins, and styling. To make the figures comparable, the plotting settings should be specified explicitly in both scripts, including the axis scales, labels, age-band midpoints, and presentation of the two gender series. This helps ensure that differences in appearance do not obscure the same underlying results.

## Question 6 — Presentation

The presentation should contain no more than four PowerPoint slides and be saved in the `slides/` folder.

[View the assignment presentation](slides/FA24-BEDS-022.pptx)

The slides should show:

1. The assignment variant and study area.
2. The default scatterplot and redesigned literacy figure side by side.
3. The education-spending distribution and its main results.
4. The most important finding: the gender gap in literacy, particularly the 47.9-percentage-point difference in the 40–44 age band.

## Main Finding

The analysis identifies substantial differences in literacy rates between women and men in rural Balochistan. The largest observed gap is 47.9 percentage points among people aged 40–44. The education-spending results also show considerable variation: the weighted 90th percentile is Rs 18,700, compared with Rs 600 at the weighted 10th percentile.
