---
name: analyze-cross-lagged-panel-network
description: Analyze longitudinal wide-format psychological panel data with cross-lagged panel network models in R using regularized nodewise regressions for prospective associations. Use for 交叉滞后网络、CLPN、纵向面板网络、跨时网络、T1预测T2症状.
---

# Cross-lagged panel network analysis

Use for repeated waves of the same participants measured on comparable variables. CLPN edges are conditional prospective associations, not causal effects; CLPN is distinct from intensive EMA or within-person temporal networks.

1. Audit participant IDs, wave structure, duplicate IDs, node correspondence, attrition, variable type, and missingness. Require at least two comparable waves; with more waves, estimate adjacent transitions.
2. Start from [clpn_tutorial.R](../../assets/clpn_tutorial.R). Fit one regularized regression per later-wave node using all prespecified earlier-wave nodes, including its autoregressive predictor. Add only prespecified covariates consistently and keep them out of the symptom network.
3. State orientation clearly: rows are earlier-wave predictors, columns are later-wave outcomes. Separate the autoregressive diagonal from cross-lagged off-diagonal paths.
4. Report sample/attrition, estimator/tuning, missing-data approach, covariates, temporal edge matrix, and uncertainty/robustness actually estimated. One transition is not temporal replication.
5. Draft only `2.4 Data Analysis` and `3 Results`, unless asked otherwise. Use prospective-association wording.

Use one primary model and few theory-driven sensitivity checks. Bootstrap, wave-equality tests, and subgroup models are optional, can be expensive, and are not run automatically. A standard wide CLPN is not appropriate for irregularly timed EMA without a timing/dependence model.
