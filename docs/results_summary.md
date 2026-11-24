# Results summary (for writing the report)

All numbers come from `output/` after running `R/run_all.R`. Figure numbers refer to `figures/`.

## The answer in three sentences

1. **Across Catalonia, the type of severe accident did not change at the toll date.** A classifier separates before/after only weakly (AUC 0.61), and in a fair 24-vs-24-month window it does no better than with fake break dates (AUC 0.52-0.54 vs 0.51-0.56). The 0.61 comes from slow trends (e-scooters, fewer mopeds), not from 2021.
2. **What changed is *where* accidents happen.** Severe accidents on the former toll roads rose by about 85 % relative to other interurban roads (rate ratio 1.85, 95 % CI 1.50-2.26). Fake break dates give about 1.0. The parallel N-roads fell by about 17 % (0.83, CI 0.68-1.01, borderline).
3. **On the former toll roads, accidents may have become more often fatal** (21.9 % -> 32.2 %, odds ratio 1.63, CI 1.05-2.54, p = 0.03), but this rests on 143 accidents and is not significant after correcting for 8 tests. Truck involvement did **not** rise relative to other roads.

## Data (section IV)

- 24,478 severe accidents, 2010-2023 (2024 is not in the published file). Before 20,643 (84.3 %), after 3,835 (15.7 %).
- Hidden missing codes: 999 (speed limit), 999999 (km point), "Unspecified".
- **Recording artefacts** (fig 5) -- dropped or recoded, otherwise a model learns the recording practice:
  - missing share grows over time: speed_limit 13 % -> 26 %, directions 12 % -> 30 %, gradient 51 % -> 66 %, road_profile, special_lane, infl_road_profile, infl_visibility
  - fog = "Yes" jumps from 0.5 % to 11 % in 2017; night lit / poorly lit shifts in the same year -> fog dropped, night kept as one level
  - road_type: "Autopista" used almost only 2013-2015 -> road groups built from the road name instead
- **Derived features:** road_group (former toll road / AP-7 South free 2020 / parallel N-road / other interurban / urban), motorway flag, yes/no flags for who was involved, single vehicle, fatal.
- Former toll road = AP-7 north of Vila-seca, AP-2, C-32 North (Maresme), C-33. AP-7 South was freed in Jan 2020, so it is kept separate.
- **Real trends before 2021** (fig 4): motorcycle share 31 % -> 42 % (2010-2019), "other unit" (e-scooters?) 2 % -> 7 % from 2020, mopeds 13 % -> 4 %.
- Strongest before/after differences (Cramér's V, `eda_cramers_v.csv`): other unit 0.10, accident subtype 0.08, accident type 0.08, road group 0.05. All are small; with n = 24,478 even V = 0.02 is "significant", which is why effect size is reported.

## Model (section V)

- Response: `post` (after = accident on/after 1 Sep 2021).
- Models: logistic regression (glm, binomial), classification tree (rpart, cp chosen by 10-fold internal CV, minbucket 30), random forest (randomForest, 300 trees, mtry = floor(sqrt(p)), nodesize 5).
- **Imbalance:** class weights (each class same total weight) for glm and rpart; balanced bootstrap for the forest (`strata` + `sampsize = c(n_min, n_min)`, i.e. undersampling in each tree). Only on training folds.
- **Validation:** stratified 5-fold CV, same folds for all models. A time-based split is not possible, because the label *is* time. The risk of learning time drift is handled with (a) leakage removal, (b) symmetric 24-month windows with the same calendar months on both sides, (c) a **placebo test** with fake break dates 2013, 2015, 2017.
- **Metrics:** ROC-AUC, PR-AUC (baseline = share of "after"), balanced accuracy, sensitivity, specificity, F1. Not plain accuracy: "always before" gives 84 %.
- **Toll effect:** difference-in-differences. Treated = former toll roads, control = other interurban roads. Counts: quasi-Poisson on monthly counts with month fixed effects (absorbs Covid). Composition: logistic regression with year fixed effects. Placebo DiD at Sep 2014/2016/2018 using pre-Covid data.

## Results (section VI)

**Classifiers** (`model_cv_metrics.csv`, fig 6):

| Scenario | Model | AUC | PR-AUC (baseline) | Bal. acc. |
|---|---|---|---|---|
| S1 all 2010-2023 | logit | 0.609 | 0.235 (0.157) | 0.570 |
| S1 | random forest | 0.611 | 0.237 | 0.567 |
| S1 | tree | 0.594 | 0.220 | 0.566 |
| S2 interurban | logit | 0.622 | 0.219 (0.149) | 0.582 |
| S3 window 2019-23 | logit / rf | 0.539 / 0.533 | | 0.525 / 0.523 |
| S4 window, no Covid | logit / rf | 0.535 / 0.519 | | 0.522 / 0.510 |

The three model types perform almost the same -> the limit is the signal in the data, not the model.

**Placebo** (fig 8, `model_placebo.csv`): fake dates give AUC 0.51-0.56, the real date 0.52-0.54. The real break is not easier to detect than an ordinary two-year period.

**Drivers** (fig 7, `logit_odds_ratios.csv`, `rf_importance.csv`, fig 9):
- other unit involved: OR 3.08 (2.54-3.74) -- e-scooter trend, not tolls
- road group = former toll road: OR 3.22 (1.89-5.48); AP-7 South: OR 2.61 (1.31-5.19)
- moped involved: OR 0.58 (fewer mopeds over time)
- random forest: road_group is the most important variable
- careful: any_pedestrian (OR 2.45) and accident type "pedestrian hit" (OR 0.32) overlap almost completely, so read them together, not one by one

**Toll effect** (fig 2, fig 10, `did_counts.csv`, `did_composition.csv`):

| Road group | Accidents/year 2017-19 | 2022-23 | Change |
|---|---|---|---|
| Former toll roads | 42 | 64 | +52 % |
| Other interurban | 661 | 578 | -13 % |
| Parallel N-roads | 87 | 66 | -25 % |

DiD rate ratio 1.85 (1.50-2.26); placebos 1.04, 1.07, 1.11 (all CIs include 1).

## Limitations / next steps (section VII)

- **No traffic volumes.** More accidents on the former toll roads may just mean more cars (AP-7 traffic +20 %). The right measure is accidents per vehicle-km; the next step is to join traffic counts (IMD) from the Servei Català de Trànsit / Ministry.
- Only severe accidents (death or serious injury) -- minor accidents are not in the data.
- Small numbers on the former toll roads (143 accidents after), so composition changes have wide CIs.
- The after period is short (28 months) and starts right after Covid.
- Earlier changes contaminate the "before" period: trucks moved to AP-7/AP-2 in 2018, AP-7 South free from 2020.
- Doing it again: decide on the control group and the placebo test first, before running any classifier.
