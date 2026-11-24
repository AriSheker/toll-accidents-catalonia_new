# 02_clean_features.R -- cleaning + derived features
# Input : data/processed/accidents_EN.csv  (translated copy of the raw file)
# Output: data/processed/accidents_clean.rds
#
# Decisions made here (all are explained in the report, section "Data"):
#  1. Hidden missing codes (999, 999999, "Unspecified") are turned into NA.
#  2. Variables whose missing share DRIFTS over time are dropped from modelling,
#     because a classifier could otherwise learn "how much is empty" instead of
#     "what kind of accident it was" (leakage through recording practice).
#  3. road_type is not used (coded inconsistently over the years). Road groups
#     are built from the road NAME instead (AP-7, N-II, ...).
#  4. year and date are kept for plots and windows, but NEVER used as features.

library(tidyverse)

acc <- read_csv("data/processed/accidents_EN.csv",
                na = c("", "NA"),
                locale = locale(decimal_mark = ","),
                show_col_types = FALSE, guess_max = 30000)

# ---- 1. Dates, response, Covid flag ------------------------------------
toll_date <- as.Date("2021-09-01")

acc <- acc %>%
  mutate(date  = dmy(date),
         month = month(date),
         post  = factor(if_else(date >= toll_date, "after", "before"),
                        levels = c("before", "after")),   # glm models P(after)
         # Spanish state of alarm: 14 Mar 2020 - 9 May 2021
         covid = date >= as.Date("2020-03-14") & date <= as.Date("2021-05-09"))

# ---- 2. Hidden missing values ------------------------------------------
acc <- acc %>%
  mutate(km_point    = na_if(km_point, 999999),
         speed_limit = na_if(speed_limit, 999),
         across(where(is.character), ~ na_if(.x, "Unspecified")))

# ---- 3. Road groups (from the road name, not road_type) ----------------
road_up <- toupper(acc$road)
# Counties on the AP-7 south of Vila-seca (km > ~252). Regex instead of exact
# names so accented characters (Montsià) match on every computer.
south <- str_detect(acc$county, "^(Baix Camp|Baix Ebre|Montsi)")

acc <- acc %>%
  mutate(
    road_clean = road_up,
    # freed on 1 Sep 2021
    ex_toll = (road_up == "AP-7" & !south) |
              road_up == "AP-2" |
              (road_up == "C-32" & county %in% c("Maresme", "Selva")) |  # C-32 North only
              road_up == "C-33",
    # AP-7 Tarragona - Ebre was already toll-free from 1 Jan 2020
    ap7_south = road_up == "AP-7" & south,
    # free national roads running parallel to the freed motorways
    parallel  = str_detect(road_up, "^N-II|^N-340|^N-240"),
    motorway  = str_detect(road_up, "^AP-|^A-") | road_up %in% c("C-32", "C-33"),
    road_group = case_when(
      ex_toll   ~ "Former toll road",
      ap7_south ~ "AP-7 South (free 2020)",
      parallel  ~ "Parallel N-road",
      zone == "Urban" ~ "Urban",
      TRUE      ~ "Other interurban"),
    road_group = factor(road_group, levels = c("Urban", "Other interurban",
                                               "Parallel N-road", "Former toll road",
                                               "AP-7 South (free 2020)"))
  )

# ---- 4. Who was involved (counts -> yes/no flags) ----------------------
acc <- acc %>%
  mutate(any_pedestrian = n_pedestrians   > 0,
         any_bicycle    = n_bicycles      > 0,
         any_moped      = n_mopeds        > 0,
         any_motorcycle = n_motorcycles   > 0,
         any_light      = n_light_vehicles > 0,
         any_heavy      = n_heavy_vehicles > 0,
         any_other_unit = n_other_units   > 0,    # probably e-scooters from 2020
         single_unit    = n_units == 1,
         fatal          = severity == "Fatal")

# ---- 5. Collapse rare categories ---------------------------------------
# Levels with very few cases make glm unstable and add nothing.
acc <- acc %>%
  mutate(
    weather = case_when(weather == "Good weather" ~ "Good",
                        str_detect(weather, "rain") ~ "Rain",
                        TRUE ~ "Other"),
    surface = case_when(surface == "Dry and clean" ~ "Dry",
                        surface == "Wet" ~ "Wet",
                        TRUE ~ "Other"),
    # Night is NOT split into lit / poorly lit: that split shifts by ~4 points
    # in 2017, the same year fog jumps -> a recording change, not real light.
    light = case_when(str_detect(light, "^Day") ~ "Day",
                      light == "Dawn/dusk" ~ "Dawn/dusk",
                      TRUE ~ "Night"),
    wind  = if_else(wind == "Calm", "Calm", "Windy", missing = "Calm"),
    special_measures = if_else(special_traffic_measures == "None", "None", "Some",
                               missing = "None"),
    accident_type = replace_na(accident_type, "Other"),
    accident_subtype = fct_lump_min(replace_na(accident_subtype, "Other"), 100,
                                    other_level = "Other"),
    hit_and_run = replace_na(hit_and_run, "No")
  )

# ---- 6. Final variable list --------------------------------------------
# Dropped from modelling because the missing share drifts over time
# (see 03_eda.R, figure fig_missing_drift.png):
#   speed_limit, road_profile, gradient, priority_control, junction_type,
#   directions, road_owner, special_lane, infl_road_profile, infl_visibility
# Dropped because inconsistent coding: road_type, and fog (share "Yes" jumps
#   from 0.5 % to 11 % in 2017 -- a change in how it was recorded, not in fog)
# Dropped because too many levels / pure location: municipality, county, km_point

features <- c(
  # where
  "zone", "province", "road_group", "motorway", "intersection",
  "speed_limit_source",
  # when (within day / week -- never year or date)
  "hour", "time_of_day", "weekday_group",
  # conditions
  "weather", "surface", "light", "wind", "special_measures",
  "infl_weather", "infl_light", "infl_traffic", "infl_fog", "infl_wind",
  # what happened
  "accident_type", "accident_subtype", "hit_and_run", "fatal",
  "n_units", "n_victims", "single_unit",
  # who was involved
  "any_pedestrian", "any_bicycle", "any_moped", "any_motorcycle",
  "any_light", "any_heavy", "any_other_unit"
)

clean <- acc %>%
  select(year, month, date, post, covid, road_clean, county, ex_toll, ap7_south,
         parallel, severity, n_heavy_vehicles, all_of(features)) %>%
  mutate(across(where(is.character), factor),
         across(where(is.logical) & !c(covid, ex_toll, ap7_south, parallel),
                ~ factor(.x, levels = c(FALSE, TRUE), labels = c("No", "Yes"))))

# The few remaining NAs (infl_* with "Unspecified", hour) are stable over time:
# replace them with an explicit level / the median so no rows are lost.
clean <- clean %>%
  mutate(across(starts_with("infl_"), ~ fct_na_value_to_level(.x, "Unknown")),
         hour = replace_na(hour, median(hour, na.rm = TRUE)))

stopifnot(nrow(clean) == 24478, !anyNA(clean[features]))

saveRDS(clean, "data/processed/accidents_clean.rds")
saveRDS(features, "data/processed/features.rds")

cat("Saved", nrow(clean), "rows x", length(features), "model features\n")
print(table(clean$road_group, clean$post))
