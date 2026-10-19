# Toll removal and severe road accidents in Catalonia

Term project – *Data Science and AI for Industry* (2400200), UPC ETSEIB, Fall 2026. Option 1.
Supervisor: Marta Castellano. **Deadline: Friday 27 November, 23:59 (Atenea).** Weight: 25 % of the course grade.

---

## 1. The question

> **Did the removal of highway tolls on 1 September 2021 change the characteristics of severe traffic accidents in Catalonia?**

On 1 September 2021 the tolls were removed on:

| Road | Freed section |
|---|---|
| AP-7 | Vila-seca – La Jonquera (French border) |
| AP-2 | Zaragoza – El Vendrell (Penedès) |
| C-32 North | Montgat – Blanes (Maresme) |
| C-33 | Barcelona – Montmeló |

Roughly 550–600 km of motorway became free overnight. Reported effects: AP-7 traffic +20 % (Sept 2021 vs Sept 2019), more truck accidents on the former toll roads, and fewer fatal accidents on the parallel national roads N-II and N-340.

## 2. What we have to deliver

1. **EDA** – explore whether accident characteristics changed before vs. after 1 Sep 2021.
2. **Classifier** – predict whether an accident happened *before* or *after* 1 Sep 2021 (the assignment text says "2025" – a typo).
3. **Interpretation** – explain which variables drive the classification. *This is what actually answers the question.*

Marta's critical points: **class imbalance · changes over time · derived features · validation strategy · appropriate metrics.**

**Report:** 11–14 pages (11 pt, single spacing), excluding title page, TOC and appendix:

| Section | Length |
|---|---|
| Executive summary | max 1 p |
| Project structure | max 1 p |
| Data and exploratory analysis | 3–4 p |
| Model | 3–4 p |
| Results | 2–3 p |
| Next steps | 1 p |
| Annex: R code | separate file, not counted |

## 3. The data

- **Source:** [Accidents de trànsit amb morts o ferits greus a Catalunya](https://analisi.transparenciacatalunya.cat/Transport/Accidents-de-tr-nsit-amb-morts-o-ferits-greus-a-Ca/rmgc-ncpb) – Dades Obertes Catalunya (Departament d'Interior i Seguretat Pública). Updated annually, last update Dec 2024.
- **Size:** 24,478 accidents × 58 variables. One row = one accident with at least one death or serious injury (urban + interurban).
- **Period:** 2010–2023. *Note: the assignment says 2010–2024, but 2024 is not in the published file.*
- **Classes:** before = 20,643 (84.3 %), after = 3,835 (15.7 %).
- Variable descriptions: [`docs/Codebook_variables.md`](docs/Codebook_variables.md).

## 4. Why this is harder than it looks

A before/after classifier tests **"before vs. after"**, not **"because of the tolls"**. Many other things changed between 2010 and 2023:

- **Covid 2020** – ~30 % fewer accidents than 2019.
- **E-scooters** – "other units" involved jumps from ~2 % to ~7 % from 2020.
- **Earlier toll/traffic changes** – trucks forced from N-340/N-240 onto AP-7/AP-2 (Sept 2018); AP-7 South (Tarragona–Alacant) toll-free since 1 Jan 2020.
- **Recording practice** – `road_type` is inconsistent over time ("Autopista" used almost only 2013–2015); missingness rises over time for several variables.

A model trained naively on all accidents will learn these trends and get a good score for the wrong reason.

**First findings:**

| | Before | After |
|---|---|---|
| Accidents on former toll roads (share) | 3.1 % | 5.1 % |
| Fatal accidents (share) | 12.6 % | 12.7 % |
| "Other units" involved | 2.1 % | 6.6 % |

Accidents on the former toll roads rose from ~50–70/year to 91 (2022) and 83 (2023), while the rest of the network did not increase correspondingly.

## 5. Our plan (preliminary – to be confirmed with Marta)

1. **Clean the data** – recode hidden missing values (`999`, `999999`, `Unspecified`), fix decimal commas, decide on structurally missing variables.
2. **Derived features**
   - `ex_toll` – accident on AP-7 / AP-2 / C-32 / C-33 (from `road`, not `road_type`)
   - `parallel_road` – N-II, N-340, N-240
   - AP-7 North/South split via `km_point`
   - motorway flag from road prefix; weekend × night interactions
3. **Remove leakage** – drop `year`, `date` and variables that only exist in one period.
4. **Time window** – compare full 2010–2023 with a symmetric window (e.g. Sep 2018–Aug 2021 vs. Sep 2021–Dec 2023), with/without 2020.
5. **Control-group thinking** – compare changes on former toll roads vs. other interurban roads (difference-in-differences idea). If the "effect" is equally large on unaffected roads, it is not the tolls.
6. **Models** – logistic regression (interpretable odds ratios) as baseline; tree-based model (random forest / boosting) with variable importance.
7. **Imbalance** – class weights or resampling *on training data only*; tune the decision threshold.
8. **Validation & metrics** – stratified k-fold vs. time-based split; report ROC-AUC, PR-AUC, balanced accuracy, sensitivity/specificity. Not plain accuracy (84/16 split).

## 6. Timeline

| When | What |
|---|---|
| Oct 2026 | Review meeting with Marta: rough EDA + questions |
| Late Oct – early Nov | Cleaning, features, time window decision |
| Early – mid Nov | Models, validation, interpretation |
| Mid – late Nov | Write report, figures, final check |
| **27 Nov, 23:59** | **Submit in Atenea** |

Tasks and owners are tracked in **Issues** and the **Project board**.

## 7. Repository structure

| Folder | Content |
|---|---|
| `data/raw/` | Original dataset (**never edit**) |
| `data/processed/` | Translated / cleaned data (`accidents_EN.csv`) |
| `R/` | Analysis scripts, numbered in run order |
| `python/` | Helper scripts (translation of the raw file) |
| `figures/` | Figures for the report |
| `docs/` | Assignment text, overview PDF, codebook |

## 8. How to run

1. Open `toll-accidents-catalonia.Rproj` in RStudio (sets the working directory).
2. Run the scripts in `R/` in numeric order.
3. Packages: `tidyverse` (more will be added as we go).

New to Git? Read [`GIT_GUIDE.md`](GIT_GUIDE.md). Rule: **pull before you start, push when you're done.**

Test suiiiiiiiiiidfwefwfee