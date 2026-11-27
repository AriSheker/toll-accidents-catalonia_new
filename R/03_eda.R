# 03_eda.R -- exploratory analysis: what changed before vs after 1 Sep 2021?
# Input : data/processed/accidents_clean.rds  (from 02_clean_features.R)
# Output: figures/fig01-fig04 (numbered as in the report), figures/extra_*.png
#         (made but not used in the report), output/eda_*.csv
#
# Three questions drive the EDA:
#  Q1. Do accident characteristics differ before vs after?      (shares, Cramer's V)
#  Q2. Were these things already changing BEFORE 2021?           (yearly trends)
#  Q3. Is the change concentrated on the former toll roads?      (road-group index)

library(tidyverse)
dir.create("figures", showWarnings = FALSE)
dir.create("output",  showWarnings = FALSE)

d <- readRDS("data/processed/accidents_clean.rds")
features <- readRDS("data/processed/features.rds")
toll_date <- as.Date("2021-09-01")
theme_set(theme_minimal(base_size = 12) + theme(plot.title.position = "plot"))
save_fig <- function(name, w = 7, h = 4) ggsave(file.path("figures", name), width = w, height = h, dpi = 300, bg = "white")

# ---- Class balance -------------------------------------------------------
print(table(d$post)); print(round(prop.table(table(d$post)), 3))

# ---- Report Fig 2: accidents per month -------------------------------------------
d %>%
  count(month = floor_date(date, "month")) %>%
  ggplot(aes(month, n)) +
  annotate("rect", xmin = as.Date("2020-03-14"), xmax = as.Date("2021-05-09"),
           ymin = -Inf, ymax = Inf, alpha = 0.15, fill = "grey40") +
  annotate("text", x = as.Date("2020-10-01"), y = 30, label = "Pandemic\ninterval", size = 3) +
  geom_line() +
  geom_smooth(method = "loess", span = 0.3, se = FALSE, colour = "steelblue", linewidth = 0.6) +
  geom_vline(xintercept = toll_date, linetype = "dashed", colour = "red") +
  labs(x = NULL, y = "Severe accidents per month",
       title = "Severe road accidents in Catalonia, 2010-2023",
       subtitle = "Red line: toll removal 1 Sep 2021")
save_fig("fig02_monthly_accidents.png", w = 8, h = 3)

# ---- Report Fig 4 (Q3): yearly accidents per road group, index 2017-2019 = 100 ---
idx <- d %>%
  filter(road_group != "AP-7 South (free 2020)") %>%       # too few cases per year
  count(year, road_group) %>%
  group_by(road_group) %>%
  mutate(index = 100 * n / mean(n[year %in% 2017:2019])) %>%
  ungroup()
write_csv(idx, "output/eda_road_group_counts.csv")

ggplot(idx, aes(year, index, colour = road_group)) +
  geom_line(linewidth = 0.8) + geom_point(size = 1.5) +
  geom_hline(yintercept = 100, colour = "grey60") +
  geom_vline(xintercept = 2021.67, linetype = "dashed", colour = "red") +
  scale_colour_manual(values = c("#999999", "#56B4E9", "#E69F00", "#D55E00")) +
  scale_x_continuous(breaks = 2010:2023) +
  labs(x = NULL, y = "Index (mean 2017-2019 = 100)", colour = NULL,
       title = "Only the former toll roads have more severe accidents after 2021",
       subtitle = "Yearly number of severe accidents per road group") +
  theme(legend.position = "bottom")
save_fig("fig04_road_group_index.png", w = 8, h = 3.4)

# ---- Q1: before/after shares of every categorical feature ---------------
# With n = 24,478 almost every chi-square test is "significant", so we also
# report Cramer's V (effect size, 0 = no association, 1 = perfect).
cramers_v <- function(tab) {
  chi <- suppressWarnings(chisq.test(tab, correct = FALSE))
  k <- min(dim(tab)) - 1
  c(p = chi$p.value, V = sqrt(unname(chi$statistic) / (sum(tab) * k)))
}
cat_feats <- features[sapply(d[features], is.factor)]
assoc <- map_dfr(cat_feats, function(v) {
  r <- cramers_v(table(d[[v]], d$post))
  tibble(variable = v, p_value = r["p"], cramers_v = r["V"])
}) %>% arrange(desc(cramers_v))
write_csv(assoc, "output/eda_cramers_v.csv")
print(assoc, n = 40)

# Same test, but only within interurban accidents (where tolls matter)
assoc_inter <- map_dfr(setdiff(cat_feats, "zone"), function(v) {
  dd <- filter(d, zone == "Interurban road")
  r <- cramers_v(table(droplevels(dd[[v]]), dd$post))
  tibble(variable = v, p_value = r["p"], cramers_v = r["V"])
}) %>% arrange(desc(cramers_v))
write_csv(assoc_inter, "output/eda_cramers_v_interurban.csv")

# ---- Extra figure (not in report): share of accidents with each characteristic, before vs after -
flags <- c(any_motorcycle = "Motorcycle", any_pedestrian = "Pedestrian",
           any_bicycle = "Bicycle", any_other_unit = "Other unit",
           any_heavy = "Heavy vehicle", single_unit = "Single vehicle",
           fatal = "Fatal")
shares <- d %>%
  mutate(scope = if_else(ex_toll, "Former toll roads", "Rest of network")) %>%
  select(post, scope, all_of(names(flags))) %>%
  pivot_longer(-c(post, scope)) %>%
  group_by(scope, name, post) %>%
  summarise(share = mean(value == "Yes"), n = n(), .groups = "drop") %>%
  mutate(name = flags[name])
write_csv(shares, "output/eda_flag_shares.csv")

ggplot(shares, aes(share, fct_reorder(name, share), fill = post)) +
  geom_col(position = "dodge") +
  facet_wrap(~ scope) +
  scale_x_continuous(labels = scales::percent) +
  scale_fill_manual(values = c(before = "grey60", after = "#D55E00")) +
  labs(x = "Share of severe accidents", y = NULL, fill = NULL,
       title = "Who was involved, before vs after 1 Sep 2021") +
  theme(legend.position = "bottom")
save_fig("extra_flag_shares.png", w = 8, h = 3.4)

# Accident type on the former toll roads
type_toll <- d %>% filter(ex_toll) %>% count(post, accident_type) %>%
  group_by(post) %>% mutate(share = n / sum(n)) %>% ungroup()
write_csv(type_toll, "output/eda_type_former_toll.csv")
print(type_toll)

# ---- Report Fig 3 (Q2): trends that were already there before 2021 --------------
trend <- d %>%
  group_by(year) %>%
  summarise(across(c(any_motorcycle, any_other_unit, any_pedestrian, any_heavy),
                   ~ mean(.x == "Yes"))) %>%
  pivot_longer(-year) %>%
  mutate(name = flags[name])

ggplot(trend, aes(year, value)) +
  geom_line() + geom_point(size = 1.2) +
  geom_vline(xintercept = 2021.67, linetype = "dashed", colour = "red") +
  facet_wrap(~ name, scales = "free_y", nrow = 1) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = NULL, y = "Share of severe accidents",
       title = "Several characteristics were already drifting before the toll removal")
save_fig("fig03_trends.png", w = 8, h = 2.8)

# ---- Report Fig 1: missing-value drift (why some variables were dropped) -------
raw <- read_csv("data/processed/accidents_EN.csv", na = c("", "NA"),
                locale = locale(decimal_mark = ","), show_col_types = FALSE,
                guess_max = 30000)
dropped <- c("speed_limit", "road_profile", "gradient", "directions",
             "special_lane", "infl_road_profile")
miss <- raw %>%
  select(year, all_of(dropped)) %>%
  mutate(across(-year, ~ is.na(.x) | as.character(.x) %in% c("Unspecified", "999")),
         `fog = Yes (not missing)` = raw$fog == "Yes") %>%
  group_by(year) %>% summarise(across(everything(), mean)) %>%
  pivot_longer(-year)

ggplot(miss, aes(year, value, colour = name)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2021.67, linetype = "dashed", colour = "red") +
  scale_y_continuous(labels = scales::percent) +
  labs(x = NULL, y = "Share of accidents", colour = NULL,
       title = "Suspected recording artefacts: missing values grow, fog jumps in 2017",
       subtitle = "Share missing/unspecified per variable. All were dropped from the models") +
  theme(legend.position = "right")
save_fig("fig01_recording_artefacts.png", w = 8, h = 3.2)

cat("EDA done: figures/ and output/ updated\n")
