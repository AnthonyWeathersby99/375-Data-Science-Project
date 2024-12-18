# COVID-19 Death Prediction Using Linear Modeling

## Overview

This project analyzes and predicts COVID-19 death rates across countries using linear regression models. By leveraging publicly available datasets, the project explores the relationships between various socioeconomic, demographic, and healthcare-related factors to predict daily deaths two weeks ahead.

## Data Sources

1. **COVID-19 Dataset**: Extracted from [Our World in Data](https://github.com/owid/covid-19-data).
   - Contains COVID-19 cases, deaths, vaccinations, hospitalizations, and other metrics.

2. **Population Data**: Extracted from the [World Bank DataBank](https://databank.worldbank.org/source/population-estimates-and-projections).
   - Includes demographic details such as age-specific population groups.

## Key Features

- **Data Wrangling**:
  - Filtering for country-level data only (ISO codes with three letters).
  - Removing countries with populations under 1 million.
  - Adding a `new_deaths_smoothed_2wk` variable for predicting deaths two weeks ahead.

- **Predictor Variables**:
  - `gdp_per_capita`: Economic status.
  - `hospital_beds_per_thousand`: Healthcare infrastructure.
  - `total_vaccinations_per_hundred`: Vaccination coverage.
  - `Population ages 80 and above`: High-risk demographic.
  - `stringency_index`: Government intervention measures.

- **Transformed Variables**:
  - `gdp_vaccination_interaction`: Interaction between GDP and vaccination rates.
  - `beds_stringency_interaction`: Interaction between hospital beds and stringency measures.
  - `elderly_vaccination_interaction`: Interaction between elderly population and vaccination rates.

- **Modeling**:
  - Built and tested five linear regression models with different combinations of predictors.
  - Split data into training (2022) and testing (2023) subsets.

- **Evaluation**:
  - Used Root Mean Squared Error (RMSE) and R² metrics to assess model performance.
  - Model 5, which incorporates GDP, vaccination metrics, and demographic factors, demonstrated the best performance.

## Results

- Scatterplots:
  - Relationship between smoothed new deaths (two weeks ahead) and new cases.
  - Relationship between smoothed new deaths and the elderly population.
  
- Best Model:
  - RMSE values were calculated for the most populous countries, showcasing the accuracy of predictions.

## Visualizations

- Scatterplots illustrating key variable relationships.
- Tables listing model performance metrics (R², RMSE).

## Requirements

- **R Libraries**:
  - `tidyverse`
  - `modelr`
  - `ggplot2`

## Contributors

- Mariia Nikitash
- Anthony Weathersby
- Abe Oueichek
