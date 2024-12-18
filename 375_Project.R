#Load Required Libraries
library(tidyverse)
library(modelr)
library(ggplot2)

#Start of Part 1: Data Wrangling
#Load and wrangle the Covid Data data table
CovidData <- read_csv("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv") %>%
  filter(nchar(iso_code) == 3) %>% 
  mutate(date = as.Date(date)) %>% 
  group_by(`iso_code`) %>% 
  mutate(new_deaths_smoothed_2wk = lead(new_deaths_smoothed, 14)) %>% 
  filter(date >= as.Date("2022-01-01") & date <= as.Date("2023-12-31"))

#Load and wrangle the Series Info data table
SeriesInfo <- read_csv("covid2.csv") %>% 
  pivot_wider(names_from = `Series Name`, values_from = `2023 [YR2023]`) %>% 
  mutate(`Population ages 80 and above, female` = as.integer(`Population ages 80 and above, female`)) %>% 
  mutate(`Population ages 80 and above, male` = as.integer(`Population ages 80 and above, male`)) %>%
  select(-`Series Code`) %>% 
  group_by(`Country Name`, `Country Code`) %>% summarize(across(1:last_col(), ~ first(na.omit(.x)))) %>% mutate('Total Population' = `Population ages 80 and above, female` + `Population ages 80 and above, male`) %>% 
  filter(`Total Population` >= 1000000) %>% 
  rename('iso_code' = 'Country Code')

#Joining the two data tables together
CombinedData <- CovidData %>% 
  left_join(SeriesInfo %>% select(iso_code, `Population ages 80 and above, female`,     `Population ages 80 and above, male`), by = "iso_code") %>% 
  filter(date >= as.Date("2022-01-01") & date <= as.Date("2023-12-31"))

View(CombinedData)
View(CovidData)
View(SeriesInfo)
#End of Part 1: Data Wrangling


#Start of Part 2: Linear Modeling

# 2b. 3 Transformed Variables
CombinedData <- CombinedData %>%
  mutate(
    gdp_vaccination_interaction = gdp_per_capita * people_fully_vaccinated_per_hundred,
    beds_stringency_interaction = hospital_beds_per_thousand * stringency_index,
    total_population_80_above = `Population ages 80 and above, female` + `Population ages 80 and above, male`,
    elderly_vaccination_interaction = total_population_80_above * total_vaccinations_per_hundred)

# 2c. Split Test and Train Data
train_data <- filter(CombinedData, date < as.Date("2023-01-01"))
test_data <- filter(CombinedData, date >= as.Date("2023-01-01")) %>% 
  filter(date >= as.Date("2023-01-01") & date <= as.Date("2023-06-30"))

# 2d. Model Creation for Linear Regression
model1 <- lm(new_deaths_smoothed_2wk ~ beds_stringency_interaction + gdp_vaccination_interaction, data = train_data)
model2 <- lm(new_deaths_smoothed_2wk ~ beds_stringency_interaction + gdp_vaccination_interaction + total_population_80_above, data = train_data)
model3 <- lm(new_deaths_smoothed_2wk ~ elderly_vaccination_interaction + people_fully_vaccinated_per_hundred, data = train_data)
model4 <- lm(new_deaths_smoothed_2wk ~ new_cases_smoothed + beds_stringency_interaction + elderly_vaccination_interaction + hospital_beds_per_thousand, data = train_data)
model5 <- lm(new_deaths_smoothed_2wk ~ gdp_vaccination_interaction + total_population_80_above + gdp_per_capita + aged_65_older, data = train_data)

View(test_data)
View(train_data)
#End of Part 2: Linear Modeling


#Start of Part 3: Evaluating the Linear Models
#3a.
rmse_model1 <- rmse(model1, test_data)
rmse_model2 <- rmse(model2, test_data)
rmse_model3 <- rmse(model3, test_data)
rmse_model4 <- rmse(model4, test_data)
rmse_model5 <- rmse(model5, test_data)

rmse_data <- tibble(
  model = c("Model 1", "Model 2", "Model 3", "Model 4", "Model 5"),
  rmse = c(rmse_model1, rmse_model2, rmse_model3, rmse_model4, rmse_model5))
View(rmse_data)

test_data <- ungroup(test_data) %>%
  mutate(
    pred_model1 = predict(model1, newdata = .),
    pred_model2 = predict(model2, newdata = .),
    pred_model3 = predict(model3, newdata = .),
    pred_model4 = predict(model4, newdata = .),
    pred_model5 = predict(model5, newdata = .)
  )

daily_summary <- test_data %>%
  select(date, iso_code, new_deaths_smoothed_2wk, pred_model1, pred_model2, pred_model3, pred_model4, pred_model5) %>%
  pivot_longer(
    cols = starts_with("pred"),
    names_to = "model",
    values_to = "predicted_deaths",
    names_prefix = "pred_") %>%
  mutate(
    error = predicted_deaths - new_deaths_smoothed_2wk)

rmse_per_country_model <- daily_summary %>%
  group_by(iso_code, model) %>%
  summarise(
    daily_rmse = sqrt(mean(error^2, na.rm = TRUE)),
    .groups = 'drop')
daily_summary <- na.omit(daily_summary) %>% filter(error >= 0)
View(daily_summary)


#3b. Model 5 seems to be the best
test_data <- test_data %>%
  mutate(pred_model5 = predict(model5, newdata = .))

# Calculate RMSE by country for model5
rmse_by_country_model5 <- test_data %>%
  group_by(iso_code) %>%
  summarise(
    actual = new_deaths_smoothed_2wk,
    predicted = pred_model5,
    rmse = sqrt(mean((actual - predicted)^2, na.rm = TRUE)),
    .groups = 'drop')
rmse_by_country_model5 <- na.omit(rmse_by_country_model5)
View(rmse_by_country_model5)

#End of Part 3: Evaluating the Linear Models

#Evaluation

#Scatterplot Recent Deaths for Every Country
recent_data <- CombinedData %>%
  group_by(iso_code) %>%
  slice_max(order_by = date) %>%
  ungroup()

ggplot(recent_data, aes(x = new_cases_smoothed, y = new_deaths_smoothed_2wk)) +
  geom_point(aes()) +
  labs(x = "New Cases Smoothed",
       y = "New Deaths Smoothed (2 weeks)")

#a scatterplot of only the most recent new deaths (new_deaths_smoothed) in the test dataset (i.e., 2023-06-30) and the total (female+male) population over 80 for every country (i.e., one point per country)
test_data_june30 <- filter(test_data, date == as.Date("2023-06-30"))
ggplot(test_data_june30, aes(x = total_population_80_above, y = new_deaths_smoothed_2wk)) +
      geom_point() +
      labs(x = "Total Population over 80", y = "New Deaths (smoothed)")

# a table listing the R2 and RMSE of all your models
 model_performance <- tibble(
  Model = c("Model 1", "Model 2", "Model 3", "Model 4", "Model 5"), R_squared = c(summary(model1)$r.squared, summary(model2)$r.squared, summary(model3)$r.squared, summary(model4)$r.squared, summary(model5)$r.squared), RMSE = c(rmse_model1, rmse_model2, rmse_model3, rmse_model4, rmse_model5))

# a table showing the RMSE of only your best model for the 20 most populous countries arranged in decreasing order of population
 top_20_populous_countries <- CovidData %>% filter(!is.na(population)) %>% select(iso_code, population) %>% distinct() %>% arrange(desc(population)) %>% head(20)
 top_20_countries_rmse <- rmse_by_country_model5 %>% filter(iso_code %in% top_20_populous_countries$iso_code) %>% arrange(match(iso_code, top_20_populous_countries$iso_code))
 top_20_countries_rmse
 