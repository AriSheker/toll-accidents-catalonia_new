# 04_models.R -- classifiers: before vs after 1 Sep 2021
# Input : data/processed/accidents_clean.rds, features.rds
# Output: output/model_*.csv, figures/fig6-9*.png
#
# Idea: the classifier is a MEASURING INSTRUMENT. If accidents after 1 Sep 2021
# look like accidents before, no model can separate them (AUC ~ 0.5). If it can,
# the variables it uses tell us WHAT changed.
#
# Every model gets exactly the same folds, weights and metrics, so the comparison
# is fair. One function per step, so a new model is 3 lines.
#
# Scenarios:
#   S1  all accidents, 2010-2023                (the model the assignment asks for)
#   S2  interurban accidents only, 2010-2023    (tolls only matter outside towns)
#   S3  symmetric window Sep 2019-Aug 2021 vs Sep 2021-Aug 2023 (24 + 24 months)
#   S4  = S3 without the Covid state-of-alarm months
#   P*  PLACEBO windows with a fake "toll date" in 2013, 2015, 2017.
#       If a fake date gives the same AUC as the real one, the model only
#       learns slow time trends, not a break in 2021.

library(tidyverse)
library(rpart)
library(randomForest)
library(pROC)

set.seed(2026)
d <- readRDS("data/processed/accidents_clean.rds")
features <- readRDS("data/processed/features.rds")
theme_set(theme_minimal(base_size = 11) + theme(plot.title.position = "plot"))
save_fig <- function(name, w = 7, h = 4) ggsave(file.path("figures", name), width = w, height = h, dpi = 300)

# ---- Helpers -------------------------------------------------------------

# Class weights: each class gets the same total weight (fixes the 84/16 imbalance)
class_w <- function(y) { tab <- table(y); as.numeric(length(y) / (2 * tab[as.character(y)])) }

# Stratified k-fold: every fold keeps the before/after ratio
make_folds <- function(y, k = 5) {
  f <- integer(length(y))
  for (lv in levels(y)) { i <- which(y == lv); f[i] <- sample(rep(1:k, length.out = length(i))) }
  f
}

# Fit one model on train, return P(after) for test
fit_predict <- function(method, train, test) {
  w <- class_w(train$post)
  switch(method,
    # Logistic regression, class-weighted
    logit = {
      m <- suppressWarnings(glm(post ~ ., data = train, family = binomial, weights = w))
      as.numeric(predict(m, newdata = test, type = "response"))
    },
    # Classification tree; complexity cp chosen by rpart's internal 10-fold CV
    tree = {
      m <- rpart(post ~ ., data = train, weights = w, method = "class",
                 control = rpart.control(cp = 0.0005, minbucket = 30, xval = 10))
      best_cp <- m$cptable[which.min(m$cptable[, "xerror"]), "CP"]
      m <- prune(m, cp = best_cp)
      predict(m, newdata = test, type = "prob")[, "after"]
    },
    # Random forest; balanced bootstrap = undersampling the majority class in every tree
    rf = {
      n_min <- min(table(train$post))
      m <- randomForest(post ~ ., data = train, ntree = 300,
                        mtry = floor(sqrt(ncol(train) - 1)),
                        strata = train$post, sampsize = c(n_min, n_min),
                        nodesize = 5)
      predict(m, newdata = test, type = "prob")[, "after"]
    })
}

# Metrics. Plain accuracy is NOT used: predicting "before" always gives 84 %.
metrics <- function(p, y, thr = 0.5) {
  pos <- y == "after"; pred <- p >= thr
  tp <- sum(pred & pos); fp <- sum(pred & !pos); fn <- sum(!pred & pos); tn <- sum(!pred & !pos)
  sens <- tp / (tp + fn); spec <- tn / (tn + fp); prec <- tp / max(tp + fp, 1)
  # PR-AUC as average precision (baseline = share of "after")
  o <- order(p, decreasing = TRUE); hits <- pos[o]
  ap <- sum((cumsum(hits) / seq_along(hits))[hits]) / sum(hits)
  tibble(auc = as.numeric(auc(roc(y, p, levels = c("before", "after"), direction = "<", quiet = TRUE))),
         pr_auc = ap, pr_baseline = mean(pos),
         bal_acc = (sens + spec) / 2, sensitivity = sens, specificity = spec,
         f1 = 2 * prec * sens / (prec + sens))
}

# Prepare a modelling data set: keep features, merge very rare levels into the
# most common level (a level with 5 cases can be missing from a training fold and
# then crash predict()), drop variables that are constant in this subset.
lump_rare <- function(x, min_n = 40) {
  if (!is.factor(x)) return(x)
  tab <- table(x); rare <- names(tab)[tab < min_n]
  if (length(rare) == 0) return(x)
  x[x %in% rare] <- names(which.max(tab))
  droplevels(x)
}
prep <- function(data) {
  data <- droplevels(data[, c("post", features)])
  data[features] <- lapply(data[features], lump_rare)
  data[, sapply(data, function(x) length(unique(x)) > 1)]
}

# Run k-fold CV for several methods on one data set; keeps out-of-fold predictions
run_cv <- function(data, methods = c("logit", "tree", "rf"), k = 5, label = "") {
  data <- prep(data)
  folds <- make_folds(data$post, k)
  oof <- map_dfr(methods, function(mth) {
    p <- numeric(nrow(data))
    for (i in 1:k) p[folds == i] <- fit_predict(mth, data[folds != i, ], data[folds == i, ])
    tibble(scenario = label, method = mth, y = data$post, p = p)
  })
  res <- oof %>% group_by(scenario, method) %>%
    group_modify(~ metrics(.x$p, .x$y)) %>% ungroup() %>%
    mutate(n_before = sum(data$post == "before"), n_after = sum(data$post == "after"))
  list(metrics = res, oof = oof)
}

# Symmetric window around a (real or fake) break date: 24 months each side.
# Whole years on both sides -> the same calendar months, so season cannot leak.
window_data <- function(break_date, drop_covid = FALSE) {
  b <- as.Date(break_date)
  w <- d %>% filter(date >= b %m-% months(24), date < b %m+% months(24))
  if (drop_covid) w <- filter(w, !covid)
  w %>% mutate(post = factor(if_else(date >= b, "after", "before"), levels = c("before", "after")))
}

# ---- Main scenarios -------------------------------------------------------
cat("S1 all accidents ...\n")
s1 <- run_cv(d, label = "S1 All accidents 2010-2023")
cat("S2 interurban ...\n")
s2 <- run_cv(filter(d, zone == "Interurban road"), label = "S2 Interurban 2010-2023")
cat("S3/S4 windows ...\n")
s3 <- run_cv(window_data("2021-09-01"), c("logit", "rf"), label = "S3 Window 2019-2023")
s4 <- run_cv(window_data("2021-09-01", drop_covid = TRUE), c("logit", "rf"),
             label = "S4 Window 2019-2023, no Covid")

cv_metrics <- bind_rows(s1$metrics, s2$metrics, s3$metrics, s4$metrics)
write_csv(cv_metrics, "output/model_cv_metrics.csv")
print(cv_metrics %>% mutate(across(where(is.double), ~ round(.x, 3))), width = 200)

# ---- Placebo test ---------------------------------------------------------
cat("Placebo windows ...\n")
placebo_dates <- c("2013-09-01", "2015-09-01", "2017-09-01")
placebo <- map_dfr(placebo_dates, function(b)
  run_cv(window_data(b), c("logit", "rf"), label = paste("Placebo", substr(b, 1, 4)))$metrics)
placebo_all <- bind_rows(placebo, s3$metrics, s4$metrics) %>%
  mutate(real = !str_detect(scenario, "Placebo"))
write_csv(placebo_all, "output/model_placebo.csv")
print(placebo_all %>% select(scenario, method, auc, bal_acc) %>% mutate(across(where(is.double), ~ round(.x, 3))))

ggplot(placebo_all, aes(auc, fct_rev(scenario), colour = method, shape = real)) +
  geom_vline(xintercept = 0.5, colour = "grey60") +
  geom_point(size = 3) +
  scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16), labels = c("Fake date", "Real date (2021)")) +
  scale_colour_manual(values = c(logit = "#0072B2", rf = "#D55E00"),
                      labels = c(logit = "Logistic regression", rf = "Random forest")) +
  labs(x = "Cross-validated ROC-AUC", y = NULL, colour = NULL, shape = NULL,
       title = "Placebo test: real (2021) vs fake break dates",
       subtitle = "24 months before vs 24 months after each date") +
  theme(legend.position = "bottom", legend.box = "vertical")
save_fig("fig8_placebo_auc.png", h = 4.2)

# ---- ROC curves for S1 ----------------------------------------------------
roc_df <- s1$oof %>% group_by(method) %>% group_modify(~ {
  r <- roc(.x$y, .x$p, levels = c("before", "after"), direction = "<", quiet = TRUE)
  tibble(fpr = 1 - r$specificities, tpr = r$sensitivities)
}) %>% ungroup()
auc_lab <- s1$metrics %>% transmute(method, lab = sprintf("%s (AUC %.2f)", method, auc))
roc_df <- left_join(roc_df, auc_lab, by = "method")
ggplot(roc_df, aes(fpr, tpr, colour = lab)) +
  geom_abline(linetype = "dashed", colour = "grey60") +
  geom_path(linewidth = 0.8) + coord_equal() +
  labs(x = "False positive rate (1 - specificity)", y = "True positive rate (sensitivity)",
       colour = NULL, title = "ROC curves, S1 all accidents (5-fold CV)") +
  theme(legend.position = "bottom")
save_fig("fig6_roc_s1.png", w = 5.5, h = 5.5)

# ---- Interpretation models, fitted on all S1 data -------------------------
dm <- prep(d)

# (a) Logistic regression: odds ratios (unweighted -- weights only shift the intercept)
logit_full <- glm(post ~ ., data = dm, family = binomial)
or_tab <- broom_like <- {
  s <- summary(logit_full)$coefficients
  tibble(term = rownames(s), estimate = s[, 1], se = s[, 2], p_value = s[, 4]) %>%
    filter(term != "(Intercept)") %>%
    mutate(odds_ratio = exp(estimate),
           ci_low = exp(estimate - 1.96 * se), ci_high = exp(estimate + 1.96 * se)) %>%
    arrange(p_value)
}
write_csv(or_tab, "output/logit_odds_ratios.csv")
cat("\nLogistic regression, 15 strongest terms:\n")
print(or_tab %>% select(term, odds_ratio, ci_low, ci_high, p_value) %>% head(15) %>%
        mutate(across(where(is.double), ~ signif(.x, 3))))
# Which variables matter as a block? (likelihood-ratio test per variable)
lrt <- drop1(logit_full, test = "LRT") %>% as.data.frame() %>% rownames_to_column("variable") %>%
  filter(variable != "<none>") %>% arrange(`Pr(>Chi)`)
write_csv(lrt, "output/logit_lrt_per_variable.csv")

# (b) Random forest: permutation importance (mean decrease in accuracy).
#     Unlike Gini importance, it is not biased towards variables with many levels.
n_min <- min(table(dm$post))
rf_full <- randomForest(post ~ ., data = dm, ntree = 500, importance = TRUE,
                        strata = dm$post, sampsize = c(n_min, n_min), nodesize = 5)
imp <- importance(rf_full, type = 1, scale = FALSE) %>% as.data.frame() %>%
  rownames_to_column("variable") %>% rename(importance = MeanDecreaseAccuracy) %>%
  arrange(desc(importance))
write_csv(imp, "output/rf_importance.csv")
print(head(imp, 15))

ggplot(head(imp, 15), aes(importance, fct_reorder(variable, importance))) +
  geom_col(fill = "#D55E00") +
  labs(x = "Mean decrease in accuracy when the variable is permuted", y = NULL,
       title = "Random forest: which variables separate before from after?",
       subtitle = "S1, all accidents, balanced random forest (500 trees)")
save_fig("fig7_rf_importance.png", h = 4.5)

# (c) One pruned tree on all data: a readable picture of the main splits
w <- class_w(dm$post)
tree_raw <- rpart(post ~ ., data = dm, weights = w, method = "class",
                  control = rpart.control(cp = 0.0005, minbucket = 30, xval = 10))
cpt <- tree_raw$cptable
tree_full  <- prune(tree_raw, cp = cpt[which.min(cpt[, "xerror"]), "CP"])   # CV-optimal
tree_small <- prune(tree_raw, cp = cpt[max(which(cpt[, "nsplit"] <= 6)), "CP"])  # for the figure
cat("\nTree cp table (first rows):\n"); print(head(cpt, 10))
# Nicer alternative if installed: rpart.plot::rpart.plot(tree_small, extra = 104)
png("figures/fig9_tree.png", width = 2400, height = 1500, res = 250)
plot(tree_small, uniform = TRUE, margin = 0.08, main = "Pruned classification tree (max 6 splits)")
text(tree_small, use.n = FALSE, cex = 0.7, pretty = 0)
dev.off()
cat("\nTree splits:\n"); print(tree_small)

saveRDS(list(logit = logit_full, rf = rf_full, tree = tree_full), "output/final_models.rds")
cat("Models done\n")
