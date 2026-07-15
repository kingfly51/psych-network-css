# Data audit and model selection

## Decision hierarchy

Choose the primary estimator from the measurement scale of the modeled nodes, not merely the file's storage type.

| Node composition | Primary model | Association/estimator | Predictability |
|---|---|---|---|
| All continuous, approximately Gaussian | Gaussian graphical model (GGM) | EBICglasso on Pearson correlations | R-squared |
| All continuous but markedly non-normal | GGM after documented nonparanormal transform, or Spearman sensitivity analysis | EBICglasso | R-squared on the modeled scale |
| All ordinal Likert-type | Ordinal GGM | Polychoric correlation via `cor_auto`/`lavCor`, then EBICglasso | Clearly labeled approximation; alternatively MGM categorical accuracy |
| All truly dichotomous | Ising model | `IsingFit`/eLasso | Normalized classification accuracy |
| Mixed continuous, binary, ordinal/nominal, or count | Mixed graphical model (MGM) | Node types `g`, `c`, and `p` with correct levels | R-squared for Gaussian; normalized accuracy for categorical/count as supported |

Do not call ordinal scores continuous solely because they are coded 0, 1, 2, 3. An ordinal GGM is acceptable when each item has ordered categories and polychoric associations are estimable. When categories are very sparse or polychoric estimation fails, combine categories only with substantive justification or use an MGM sensitivity analysis.

## Audit table

For every modeled node calculate:

- storage class and inferred scale;
- valid and missing counts, missing percentage, unique values, range, and category frequencies;
- mean and SD when meaningful; skewness and kurtosis for continuous/ordinal numeric nodes;
- prevalence for binary nodes;
- zero or near-zero variance and extreme floor/ceiling flags;
- duplicate columns and highly similar correlation profiles;
- community assignment and short/full English labels.

Use `networktools::goldbricker` as a redundancy screen where feasible. Treat its output as a prompt for substantive review, not an automatic deletion rule. If a pair is consolidated or one node is removed, justify the choice and rerun the audit.

## Estimation rules

- Set and report the EBIC hyperparameter gamma. A conventional primary value is 0.50; sensitivity checks may use 0 and 0.25.
- Do not tune `lambda.min.ratio` arbitrarily without justification. If changed, report it and run a sensitivity analysis against package defaults.
- Use signed networks when negative edges are possible. Prefer one-step expected influence over strength for signed interpretation.
- Fix and reuse the layout across related figures or subgroup comparisons.
- Report sample size relative to node count and qualify unstable estimates rather than hiding them.

## Stability rules

Use nonparametric bootstrap for edge-weight accuracy and case-dropping bootstrap for centrality stability. Report the CS coefficient with correlation 0.70 by default. Values should preferably exceed 0.50 and must not be below 0.25 for substantive interpretation. These are guidelines, not proof of validity.

For bridge stability, compute the CS coefficient for the bridge statistic itself. Do not substitute stability of ordinary strength or expected influence.
