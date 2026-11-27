# Results summary (revised 27 Nov 2026)

All numbers come from `output/` after `R/run_all.R`. Figure and table numbers are those in the report.

## Answer
1. **Type of accident:** limited evidence of a distinct change at the toll date. S1 AUC 0.59-0.61; two years vs two years (S3) 0.54; fake dates 0.51-0.56.
2. **Place:** severe accidents per month on former toll roads rose 85 % relative to other interurban roads (rate ratio 1.85, 95 % CI 1.50-2.26; 1.85 without still-tolled roads in the control). Counts, not risk per vehicle-km.
3. **Severity on former toll roads:** fatal share 22 % -> 32 % (OR 1.63, p = 0.03), not significant after Bonferroni (0.05/8 = 0.00625).

## Classifiers (`model_cv_metrics.csv`)
| Data | Model | AUC | AP | Bal. acc. |
| --- | --- | --- | --- | --- |
| S1 | Logistic | 0.609 | 0.233 | 0.575 |
| S1 | Tree | 0.592 | 0.225 | 0.566 |
| S1 | Forest | 0.612 | 0.240 | 0.570 |
| S3 | Logistic | 0.542 | 0.590 | 0.533 |
| S4 | Logistic | 0.537 | 0.733 | 0.524 |

Confusion matrix S1 logistic (cut-off 0.5): TP 2,032, FP 7,838, FN 1,803, TN 12,805 (`confusion_matrix_s1.csv`).

## Drivers (`logit_odds_ratios.csv`, reference road group = other interurban)
Other unit OR 2.85 (2.35-3.45); moped OR 0.53 (0.44-0.65); former toll road OR 1.88 (1.40-2.52).

## DiD (`did_counts.csv`, `did_composition.csv`)
Parallel N-roads 0.83 (0.68-1.01). Placebos 1.04 / 1.07 / 1.11.
