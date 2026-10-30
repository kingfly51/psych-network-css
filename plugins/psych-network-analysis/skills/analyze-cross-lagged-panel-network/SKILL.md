---
name: analyze-cross-lagged-panel-network
description: Run a cross-lagged panel network (CLPN) analysis in R following the project's clpn_code.R pipeline, including cross-sectional EBICglasso networks (W1/W2), the covariate-adjusted directed temporal network (all edges plus autoregressive self-loops), total and cross-construct predictability/influence (pred1/infl1 vs pred2/infl2), and a 3-4 wave free-estimation vs equal-weight model comparison. Use for 交叉滞后网络、CLPN、纵向面板网络、跨时网络、T1预测T2、横断面网络加纵向网络、可预测性、影响力、跨结构、自由估计、等权重、多波、scar/vulnerability.
when_to_use: 用户以自然语言要求按 clpn_code.R 做交叉滞后面板网络分析（2–4 波）、横断面 EBICglasso 网络、T1→T2 有向网络、总体/跨构念可预测性与影响力、3–4 波自由估计 vs 等权重比较，或撰写与 Zainal & Newman (2023) 一致的 CLPN 方法与结果时自动调用；不要求用户输入斜杠命令。
argument-hint: "<panel data path> [node/group metadata path]"
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# Cross-lagged panel network analysis

## Source of truth

This skill ports the user's `clpn_code.R` faithfully. Preserve its estimators, seeds, and figure calls; do not substitute a different CLPN definition. The reference analysis has four parts:

1. **Cross-sectional EBICglasso network** for W1 and W2 (`estimateNetwork`, `corMethod = "cor"`, `tuning = 0.5`, Spearman pairwise-complete).
2. **Directed temporal CLPN** (`cv.glmnet`, `alpha = 1`, `standardize = TRUE`, `lambda.min`), covariate-adjusted for the temporal figure, all edges plus autoregressive (AR) self-loops; `set.seed(100)` in the plain loop and `set.seed(1)` in the covariate loop.
3. **Predictability and influence** (`lavaan::sem` fixed-betas R²; squared outgoing paths), reported as `pred0/pred1/pred2` and `infl0/infl1/infl2`: **total** (`pred1`/`infl1`, all other nodes excluding the AR path) and **cross-construct** (`pred2`/`infl2`, other-construct nodes only).
4. **Multi-wave comparison** (when 3–4 waves exist): free per-transition estimates vs a model with equal-weight (equality) constraints across adjacent transitions, compared by `anova()` and fit measures.

Compare against Zainal & Newman (2023), *Psychological Medicine*, 53, 4160–4171: Fig 1 contemporaneous networks, Fig 2 temporal CLPN, Fig 3 in-/out-prediction. Read [analysis-reporting-frameworks.md](../../references/analysis-reporting-frameworks.md) and [literature-reporting-basis.md](../../references/literature-reporting-basis.md).

## Mandatory workflow

1. **Data audit.** Confirm participant structure, the wave column blocks (2–4 waves, e.g. `T1_*` / `T2_*` / `T3_*`), covariates, node groups (`k1`, `k2`), English labels, and missingness. Record the seed and all estimator settings in a config block.
2. **Start from [clpn_tutorial.R](../../assets/clpn_tutorial.R).** Copy it into the output folder and edit only the configuration block; do not edit the bundled template in place.
3. **Cross-sectional networks (Fig 1).** Estimate W1 and W2 with `bootnet::estimateNetwork(..., default = "EBICglasso", tuning = 0.5, corMethod = "cor", corArgs = list(method = "spearman", use = "pairwise.complete.obs"))`. Plot with `layout = "spring"`, `theme = "colorblind"`, `vsize = 5`, group colors, `negDashed = FALSE` (solid negative edges), `curveAll = FALSE`; reuse the W1 layout for W2.
4. **Temporal CLPN (Fig 2).** For each later-wave node, fit `glmnet::cv.glmnet` on all earlier-wave nodes (plain loop) and separately with covariates. Stack coefficients into predictor-row × outcome-column matrices. The covariate-adjusted matrix (covariates dropped) is the plotted temporal network. Keep **all** edges and the AR diagonal; plot with `groups`, `posCol = "blue"`, `negCol = "red"`, `layout = "spring"`, `theme = "colorblind"`, title `W1 -> W2 Network`. Do not threshold or remove self-loops for the reference figure.
5. **Predictability (`pred0/pred1/pred2`).** For each node, fix the selected betas and recover R² with `lavaan::sem(model, sample.cov = cor(data), sample.nobs = n)` then `inspect(fit, "rsquare")`. `pred0` = all previous-wave predictors, `pred1` = exclude own lag, `pred2` = other-construct predictors only. The dependent variable for node `i` is `names(myData)[k + i]` (the corrected form; the original `k + 1` used one fixed DV for every node).
6. **Influence (`infl0/infl1/infl2`).** Re-run the plain loop, then `infl0 = apply(adjMat^2, 1, sum)`, `infl1` after zeroing the diagonal, `infl2` after also zeroing within-construct paths (rows = earlier-wave predictors, columns = later-wave outcomes).
7. **Predictability and influence figures (Fig 3).** Produce **two** versions: **total** (`pred1`/`infl1`) and **cross-construct** (`pred2`/`infl2`). For each, horizontal `barplot(rev(vals), horiz = TRUE, names.arg = rev(labels), col = rainbow(k), ylab = "Predictability" / "Influence")`, plus a combined two-panel figure and separate single panels. Save PDF + high-resolution PNG.
8. **Multi-wave comparison (3–4 waves).** Detect wave prefixes (`T1_`, `T2_`, `T3_`, `T4_`). Fit free per-transition nodewise LASSO for each adjacent pair. Fit two lavaan models with FIML: (a) **free** unconstrained paths per transition; (b) **equal-weight** model with the same path label shared across transitions. Compare with `anova(fit_free, fit_equal)` and `fitMeasures` (chisq, df, AIC, BIC, CFI, RMSEA). With only 2 waves, state that the comparison is not applicable.
9. **Optional stability and bridge.** Provide runnable `bootnet` edge/case bootstrap and `corStability` code; add two-step bridge EI for defensible communities. A demo may skip these only if it states stability was not estimated.
10. **Writing.** Draft only `2.4 Data Analysis` and supported `3 Results` subsections. Follow Zainal & Newman (2023): descriptives; contemporaneous strongest edges and bridge EI; temporal AR vs cross-lagged paths and scar/vulnerability direction; total vs cross-construct predictability/influence ranking; multi-wave free-vs-equal model comparison; CS coefficients. Use prospective-association wording, never causal language. Report only values from exported tables.
11. **Traceability.** Create `claim_traceability.csv`; export Markdown and Word (`manuscript_sections.docx`).

## Figure contract

| Figure | Content | Reference settings |
|---|---|---|
| **Fig 1** | Cross-sectional EBICglasso network, W1 and W2 | `tuning = 0.5`, Spearman pairwise, `layout = "spring"`, `theme = "colorblind"`, `vsize = 5`, group colors, `negDashed = FALSE` (solid negatives), `curveAll = FALSE`, W2 reuses W1 layout |
| **Fig 2** | Temporal CLPN (W1→W2), all edges + AR self-loops | covariate-adjusted matrix, `groups`, `posCol = "blue"`, `negCol = "red"`, `layout = "spring"`, title `W1 -> W2 Network` |
| **Fig 3** | Predictability and influence, **total** and **cross-construct** | horizontal bars, `col = rainbow(k)`, `ylab = "Predictability"` / `"Influence"`; total (`pred1/infl1`) and cross (`pred2/infl2`); separate + combined panels |

## Fidelity notes

- The reference seeds are `set.seed(100)` (plain loop) and `set.seed(1)` (covariate loop); keep them to reproduce the reference estimates.
- Environment-only changes: configurable paths (no hard-coded `D:/...` `source()` or Dropbox `jpeg()` paths), and `use_parallel` instead of `doMC` (doMC is Unix-only; on Windows it silently gives one worker).
- Predictability uses `name.i <- names(myData)[k + i]` so each node gets its own dependent variable. This corrects the original `k + 1`, which applied one fixed DV to every node.
- Do not add edge thresholds or delete AR self-loops from Fig 2; the reference shows the full directed network.
- Fig 1 defaults to solid negative edges (`negDashed = FALSE`). The reference file used `negDashed = TRUE` (dashed negatives); switch back only if dashed negatives are explicitly requested.
- With 3–4 waves, always report the free-estimation vs equal-weight comparison; with 2 waves, explicitly state that the stationarity comparison is not applicable.

## Quality gate

Fail the run rather than overclaim when any item is unresolved:

- node order differs among data, labels, groups, adjacency matrices, or figures;
- covariates appear as symptom nodes or in the plotted networks;
- Fig 2 edges or AR self-loops were silently thresholded/removed;
- predictability or influence contains `NA`/`Inf`;
- total and cross-construct versions are not clearly distinguished in figures/tables;
- with ≥3 waves, the free-vs-equal-weight comparison is missing or its test is misreported;
- a reported strongest/predictive/influential node is not supported by an exported table;
- bootstrap type is mislabeled, or stability is silently omitted in a final (non-demo) report;
- Results contain causal language from panel data.

## Deliverables

Create a stable output directory containing:

- `analysis.R`, `sessionInfo.txt`, `panel_flow.csv`;
- `edges_crosssectional_w1.csv`, `edges_crosssectional_w2.csv`, `clpn_temporal_edges.csv`, `clpn_plain_edges.csv`, `clpn_pred_influence.csv` (contains `pred0/1/2`, `infl0/1/2`);
- Fig 1 W1/W2, Fig 2 CLPN, Fig 3 predictability/influence for **total** and **cross** (separate + combined), each as PDF and PNG;
- multi-wave (≥3 waves) files: `multiwave_free_edges_t*_t*.csv`, `multiwave_free_vs_equal_anova.csv`, `multiwave_fit_measures.csv`, and per-transition free figures;
- bootstrap edge-accuracy and CS stability outputs when enabled;
- `manuscript_sections.md` (Section 2.4 + Section 3) and `manuscript_sections.docx`;
- `claim_traceability.csv` and a concise run summary.

Do not claim successful completion unless the R script ran without errors and every reported statistic can be traced to an output file.
