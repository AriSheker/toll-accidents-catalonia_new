# 05_toll_effect.R -- was the change caused by the toll removal? (difference-in-differences)
# Input : data/processed/accidents_clean.rds
# Output: output/did_*.csv, figures/fig10_did.png
#
# The classifier (04) answers "did accidents change?". It cannot say "because
# of the tolls", since many things changed over time. Here we use a control group:
#   treated  = former toll roads (freed 1 Sep 2021)
#   control  = other interurban roads (never tolled, same Covid, same trends)
# If the tolls mattered, the treated group must change MORE than the control.
# Year/month fixed effects absorb everything that hit all roads at once
# (Covid, e-scooters, economy), so Covid is controlled for by design.
#
# AP-7 South (free since 2020) is left out of both groups: it is neither
# untreated nor treated at the same date.

library(tidyverse)
theme_set(theme_minimal(base_size = 11) + theme(plot.title.position = "plot"))
d <- readRDS("data/processed/accidents_clean.rds")

inter <- d %>%
  filter(road_group %in% c("Other interurban", "Parallel N-road", "Former toll road")) %>%
  mutate(group = droplevels(road_group),
         ym = floor_date(date, "month"))

# Wald CI for an exponentiated coefficient
ci_row <- function(model, term, label, outcome) {
  s <- summary(model)$coefficients
  est <- s[term, 1]; se <- s[term, 2]
  tibble(comparison = label, outcome = outcome, ratio = exp(est),
         ci_low = exp(est - 1.96 * se), ci_high = exp(est + 1.96 * se),
         p_value = s[term, 4])
}

# ---- (a) Number of severe accidents: monthly counts ----------------------
# n ~ month fixed effect + group + did, where did = 1 for the treated group after the break.
# exp(interaction) = how much the treated group changed RELATIVE to control.
monthly <- inter %>%
  count(ym, group) %>%
  complete(ym, group, fill = list(n = 0)) %>%
  mutate(after = ym >= as.Date("2021-09-01"))

count_did <- function(treated, data = monthly, break_date = "2021-09-01") {
  dd <- data %>% filter(group %in% c("Other interurban", treated)) %>%
    mutate(treat = group == treated, after = ym >= as.Date(break_date),
           did = as.numeric(treat & after))       # 1 = treated group, after the break
  # quasi-Poisson: like Poisson, but allows over-dispersion in the counts.
  # ("after" alone is absorbed by the month fixed effects, so it is not in the model)
  glm(n ~ factor(ym) + treat + did, family = quasipoisson, data = dd)
}

did_counts <- bind_rows(
  ci_row(count_did("Former toll road"), "did",
         "Former toll roads vs other interurban", "Number of severe accidents"),
  ci_row(count_did("Parallel N-road"), "did",
         "Parallel N-roads vs other interurban", "Number of severe accidents"))

# Placebo: same model with fake break dates, only pre-Covid data.
# A real effect should be large in 2021 and ~1 for the fake dates.
pre <- filter(monthly, ym < as.Date("2020-03-01"))
did_placebo <- map_dfr(c("2014-09-01", "2016-09-01", "2018-09-01"), function(b)
  ci_row(count_did("Former toll road", pre, b), "did",
         paste("Placebo", substr(b, 1, 4), "- former toll roads"), "Number of severe accidents"))

did_counts_all <- bind_rows(did_counts, did_placebo)
write_csv(did_counts_all, "output/did_counts.csv")
print(did_counts_all %>% mutate(across(where(is.double), ~ signif(.x, 3))))

# ---- (b) Type of accident: does the MIX change more on toll roads? -------
# Logistic regression per characteristic, within interurban accidents:
#   Y ~ year fixed effect + after + toll road + (toll road AND after)
# exp(interaction) = change in the odds of Y on toll roads, beyond the change
# seen on the other interurban roads.
comp <- inter %>% filter(group != "Parallel N-road") %>%
  mutate(treat = group == "Former toll road", after = post == "after")

outcomes <- list(
  "Fatal"                   = quote(fatal == "Yes"),
  "Heavy vehicle involved"  = quote(any_heavy == "Yes"),
  "Motorcycle involved"     = quote(any_motorcycle == "Yes"),
  "Single vehicle"          = quote(single_unit == "Yes"),
  "Run-off-road"            = quote(accident_type == "Run-off-road"),
  "Rear-end collision"      = quote(accident_subtype == "Rear-end"),
  "Night"                   = quote(light == "Night"),
  "Weekend"                 = quote(weekday_group %in% c("Sat", "Sun")))

did_comp <- imap_dfr(outcomes, function(expr, name) {
  dd <- comp %>% mutate(y = !!expr, did = as.numeric(treat & after))
  m <- glm(y ~ factor(year) + after + treat + did, family = binomial, data = dd)
  shares <- dd %>% filter(treat) %>% group_by(after) %>% summarise(s = mean(y))
  ci_row(m, "did", "Former toll roads vs other interurban", name) %>%
    mutate(share_toll_before = shares$s[!shares$after],
           share_toll_after  = shares$s[shares$after])
})
write_csv(did_comp, "output/did_composition.csv")
print(did_comp %>% mutate(across(where(is.double), ~ signif(.x, 3))), width = 200)

# How many accidents are behind these numbers? (keeps us honest about power)
print(comp %>% count(treat, after))

# ---- Figure: all DiD estimates in one forest plot ------------------------
plot_df <- bind_rows(
  did_counts_all %>% mutate(panel = "How many accidents (rate ratio)"),
  did_comp %>% select(comparison, outcome, ratio, ci_low, ci_high, p_value) %>%
    mutate(panel = "What kind of accident (odds ratio)")) %>%
  mutate(label = if_else(panel == "How many accidents (rate ratio)", comparison, outcome),
         placebo = str_detect(label, "Placebo"))

ggplot(plot_df, aes(ratio, fct_rev(fct_inorder(label)), colour = placebo)) +
  geom_vline(xintercept = 1, colour = "grey50") +
  geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = 0.2) +
  geom_point(size = 2.5) +
  facet_grid(panel ~ ., scales = "free_y", space = "free_y") +
  scale_x_log10() +
  scale_colour_manual(values = c(`FALSE` = "#D55E00", `TRUE` = "grey60"), guide = "none") +
  labs(x = "Ratio (log scale): > 1 = grew more than on other interurban roads; bars = 95 % CI",
       y = NULL,
       title = "Difference-in-differences: change on former toll roads beyond the rest of the network",
       subtitle = "Control: other interurban roads. Month/year fixed effects absorb Covid and common trends") +
  theme(strip.text.y = element_text(angle = 0, hjust = 0))
ggsave("figures/fig10_did.png", width = 8.5, height = 5.5, dpi = 300)

cat("DiD done\n")
