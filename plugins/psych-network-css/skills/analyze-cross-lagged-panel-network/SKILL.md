---
name: analyze-cross-lagged-panel-network
description: Analyze longitudinal wide-format psychological panel data with cross-lagged panel network models in R using regularized nodewise regressions for prospective associations. Use for 交叉滞后网络、CLPN、纵向面板网络、跨时网络、T1预测T2症状.
---

# Cross-lagged panel network analysis

## Analysis-to-manuscript workflow

Before fitting models, follow [analysis-reporting-frameworks.md](../../references/analysis-reporting-frameworks.md): define panel flow, node correspondence, transition-specific model families, tuning, covariates, uncertainty, required tables/figures, and the Results outline. Then analyze the user's supplied data, trace every reported number to an output, and write full, connected manuscript prose for `2.4 Data Analysis` and supported `3 Results` subsections. Export both `manuscript_sections.md` and `manuscript_sections.docx` by default. Do not create synthetic data unless explicitly requested and clearly labeled.

Use for repeated waves of the same participants measured on comparable variables. CLPN edges are conditional prospective associations, not causal effects; CLPN is distinct from intensive EMA or within-person temporal networks.

1. Audit participant IDs, wave structure, duplicate IDs, node correspondence, attrition, variable type, and missingness. Require at least two comparable waves; with more waves, estimate adjacent transitions.
2. Start from [clpn_tutorial.R](../../assets/clpn_tutorial.R). Fit one regularized regression per later-wave node using all prespecified earlier-wave nodes, including its autoregressive predictor. Add only prespecified covariates consistently and keep them out of the symptom network.
3. State orientation clearly: rows are earlier-wave predictors, columns are later-wave outcomes. Separate the autoregressive diagonal from cross-lagged off-diagonal paths.
4. Compute off-diagonal in-/out-strength (absolute sums) and in-/out-expected influence (signed sums), and create separate incoming/outgoing influence figures. Exclude autoregressive diagonal paths from these indices.
5. Include runnable participant-level nonparametric edge bootstrap and case-dropping stability code for in-/out-strength and in-/out-EI. Final reports include edge intervals/difference tests and CS coefficients; a demo may skip the expensive run only if it explicitly states stability was not estimated.
6. Use a spring layout with a recorded seed and clear T1→T2 orientation. Export every transition's coefficient matrix, full path table, nonzero cross-lag table, in/out index table, model settings and bootstrap outputs.
7. Follow the reporting framework; draft only `2.4 Data Analysis` and supported `3 Results` subsections unless asked otherwise. Use prospective-association wording and report all observed uncertainty/robustness.
8. Create `claim_traceability.csv`, then export matching Markdown and Word manuscripts.

Use one primary model and few theory-driven sensitivity checks. Do not fabricate or silently omit bootstrap results. A standard wide CLPN is not appropriate for irregularly timed EMA without a timing/dependence model.
