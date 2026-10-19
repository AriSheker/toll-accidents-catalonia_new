# 01_first_look.R — first look at the dataset (Option 1)
# Open the project via toll-accidents-catalonia.Rproj so the file paths work.
# Run line by line (Cmd+Enter) and READ the output before moving on.

library(tidyverse)

# 1) Load ---------------------------------------------------------------
# NB: "NA" is text in the file, and 999 / 999999 are used as "unknown" codes.
# Translated copy (English names) – see docs/Codebook_variables.md
acc <- read_csv("data/processed/accidents_EN.csv",
                na = c("", "NA"),
                locale = locale(decimal_mark = ","))   # km_point and hour use decimal comma

dim(acc)          # rows x columns
glimpse(acc)      # type per column – check what was read incorrectly
head(acc)
summary(acc)

# 2) Date and response --------------------------------------------------
acc <- acc %>%
  mutate(date = dmy(date),
         post = factor(date >= as.Date("2021-09-01"),
                       labels = c("before", "after")))
range(acc$date)            # which period does the file actually cover?
table(acc$post)
prop.table(table(acc$post))

# 3) Missing values -----------------------------------------------------
# What counts as "missing" here? NA, but also 999, 999999, "Unspecified" ...
colSums(is.na(acc)) %>% sort(decreasing = TRUE) %>% head(15)
table(acc$speed_limit, useNA = "ifany")
sum(acc$km_point == 999999, na.rm = TRUE)

# 4) Categorical variables ----------------------------------------------
acc %>% select(where(is.character)) %>% map_int(n_distinct) %>% sort()
table(acc$accident_type)
table(acc$road_type)
table(acc$zone)

# 5) Time series: accidents per month -----------------------------------
acc %>%
  count(month = floor_date(date, "month")) %>%
  ggplot(aes(month, n)) +
  geom_line() +
  geom_vline(xintercept = as.Date("2021-09-01"), linetype = "dashed", colour = "red") +
  labs(x = NULL, y = "Accidents per month", title = "Severe road accidents in Catalonia")

# 6) Accidents on former toll roads -------------------------------------
# First check how the road names are actually written:
acc %>% count(road, sort = TRUE) %>% filter(str_detect(road, "AP|C-3")) %>% print(n = 30)
# Then: create an ex_toll variable and count per year. What do you see?


