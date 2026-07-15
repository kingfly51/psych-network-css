---
name: analyze
description: Run or design a cross-sectional psychological symptom network analysis from tabular data in R, including optional sociodemographic or clinical covariates used only to control confounding. Automatically use when the user asks for 横断面网络分析、心理症状网络分析、协变量调整的症状网络、症状网络、网络图、中心性分析、桥接网络、桥接中心性、节点可预测性、网络稳定性检验, or mentions GGM/EBICglasso, Ising, mixed graphical models/MGM, node predictability, centrality, bootstrap stability, bridge centrality, or manuscript-ready Sections 2.4 Data Analysis and 3 Results. Inspect variable types before choosing the model and produce reproducible code, tables, figures, and evidence-grounded reporting.
when_to_use: 用户以自然语言要求开展横断面心理症状网络分析、判断数据适合 GGM/Ising/MGM、绘制带可预测性圆环的网络图、中心性图、桥接网络图、进行 bootstrap 稳定性检验，或撰写网络分析方法与结果时自动调用；不要求用户输入斜杠命令。
argument-hint: "<data path> [node/group metadata path]"
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# Psychological symptom network analysis

Perform a reproducible cross-sectional symptom-network workflow in R. Treat `$ARGUMENTS` as candidate input paths or user instructions. Never infer substantive node meaning from opaque column names.

## Natural-language invocation

Allow automatic model invocation. The user may simply say, for example, “请对这个数据做横断面网络分析” or “帮我完成心理症状网络分析并报告结果.” Do not require `/psych-network-analysis:analyze` when the intent is clear.

When no explicit path is supplied, search the current project for supported tabular files. If exactly one plausible data file exists, inspect it and proceed. If several plausible files exist, ask the user to identify the intended file. If none exists, ask the user to attach the data or provide its path. The slash command remains an optional way to force a particular file or workflow.

## Required inputs

Locate or request only what cannot be inferred safely:

- tabular data (`.xlsx`, `.xls`, `.csv`, `.sav`, `.dta`, or `.rds`);
- node columns or a rule that identifies them;
- an English short label and full English label for each node;
- optional community/category for each node;
- optional confounder columns, their measurement types, coding, missing-value rules, and an a priori substantive rationale for adjustment;
- missing-value codes and any reverse scoring or composite scoring rules.

If labels or communities are absent, create `node_metadata_template.csv`, populate only defensible fields, and mark unresolved fields for the user. Do not fabricate labels or communities.

## Accepted data shape

Require a rectangular participant-by-variable table: one row per participant/observation and one column per symptom or study variable. A header row with unique column names is mandatory. Modeled node columns may originate as numeric, logical, factor, labelled, or text-coded categories, but convert them to an explicit numeric/categorical coding before estimation and retain a codebook.

Accept `.xlsx`, `.xls`, `.csv`, SPSS `.sav`, Stata `.dta`, and R `.rds`. Do not require the user to convert SPSS or Excel files manually. Reject merged cells, multiple header rows, subtotal/footer rows, duplicated participant rows that are not repeated measurements by design, and symptom values mixed with free-text notes in the same column until they are cleaned.

Prefer a separate node metadata file with columns `variable`, `short_label`, `full_english_label`, `community`, and `measurement`. If absent, infer only technical properties from the data and request confirmation for substantive labels, communities, missing-value codes, reverse scoring, and composite scoring.

## Covariate scope boundary

Use covariates only to control confounding in this plugin. Read [covariate-control.md](../../references/covariate-control.md) whenever covariates are supplied or plausible sociodemographic/clinical variables are present.

Do not use this plugin to test moderation, estimate covariate-specific edges as substantive findings, compare subgroup networks, infer causal direction, or fit longitudinal/temporal networks. Those require separate workflows. If requested, finish the cross-sectional confounder-adjusted deliverable and mark the additional request as out of scope for this plugin.

Covariates may be included internally in a joint conditional model, but never treat them as substantive symptom nodes. Exclude them from the displayed symptom network, symptom centrality ranking, bridge communities, bridge centrality, intervention-target language, and primary predictability ring. Export covariate-related coefficients only as an adjustment diagnostic.

## Mandatory workflow

1. Preserve the raw file. Create a separate analysis dataset and record every exclusion, recode, reverse score, and composite score.
2. Audit data types, ranges, missingness, sparse categories, zero/near-zero variance, and duplicate or redundant nodes. Separately classify symptom nodes and potential confounders. Read [model-selection.md](../../references/model-selection.md) before choosing a model.
3. Export `node_audit.csv` with at least: variable, English label, community, storage class, inferred measurement level, observed range/categories, missing n/%, mean, SD, skewness, kurtosis, variance/informativeness flag, and redundancy flag. For binary variables report prevalence; for ordinal variables report category frequencies.
4. Run redundancy screening before estimation. Prefer `networktools::goldbricker` for highly overlapping node pairs and report the decision for every flagged pair. Never delete a node automatically solely because it is flagged.
5. If covariates are present, create `covariate_decision.txt` listing every candidate, inclusion/exclusion decision, coding, missingness, causal/substantive rationale, and adjustment strategy. Never select confounders solely because a univariate test or regression screening produced `p < .05`.
6. Choose one prespecified confounder-control strategy. Use residualization when all symptom nodes are continuous and the covariate mean model is defensible. Otherwise prefer a joint conditional model appropriate to all symptom and covariate types, then extract the symptom-to-symptom subnetwork. Do not apply ordinary linear residualization to binary or ordinal symptoms and then describe the residuals as binary or ordinal nodes.
7. Choose exactly one primary symptom-network model from the observed node types and adjustment strategy: GGM, Ising, or MGM. Record the decision and rationale in `model_decision.txt`. Do not choose from the spreadsheet storage class alone; integer storage does not prove ordinal or binary measurement.
8. Start from [network_analysis_template.R](../../assets/network_analysis_template.R). Copy it into the analysis output folder and tailor the configuration block, node metadata, scoring rules, covariate adjustment, and model branch. Do not edit the bundled template in place.
9. Estimate both the prespecified adjusted network and an unadjusted symptom-only sensitivity network using otherwise comparable settings. The adjusted network is primary when confounder control was prespecified. Re-run the complete adjustment step inside every bootstrap resample.
10. Estimate the network and export the weighted adjacency matrix, nonzero edge list, density/sparsity, sign distribution, strongest edges, and model settings. Use a fixed seed. Record R and package versions with `sessionInfo()`.
11. Estimate node predictability with a model appropriate to each symptom family. Draw it as a ring around each symptom node. State the metric: R-squared for Gaussian nodes and normalized accuracy for categorical/binary nodes. Do not label classification accuracy as R-squared. When covariates are used internally, label whether predictability includes their contribution.
12. Draw the symptom-only network with short English node labels, a colorblind-safe community palette, signed edges, and a fixed reusable layout. Export PDF plus a high-resolution PNG or TIFF. Never show covariates as ordinary symptom nodes in the primary figure.
13. Export a symptom-only centrality table and plot. Make strength and one-step expected influence the primary indices. Closeness and betweenness may be shown when requested, but interpret them only if the corresponding case-dropping stability is adequate and explicitly acknowledge their limitations in regularized psychological networks.
14. Assess edge-weight accuracy with nonparametric bootstrap confidence intervals and edge/centrality difference tests. Assess centrality stability with case-dropping bootstrap and report the correlation-stability coefficient. Use at least 1,000 bootstrap samples for final analysis unless computational limits are disclosed; small trial runs must be labeled preliminary.
15. If there are at least two defensible symptom communities, run bridge analysis on symptom nodes only. Make bridge expected influence the primary signed bridge index; export bridge indices and plots. Run case-dropping stability for bridge indices when the installed `bootnet` version supports them. If unsupported, use a documented custom case-dropping re-estimation routine or state that bridge stability was not estimated; never present ordinary centrality stability as bridge stability.
16. Compare adjusted and unadjusted networks descriptively as a sensitivity analysis. Do not use NCT merely to compare these two dependent estimates from the same participants. Report material changes in key edges, rankings, predictability, and stability without treating adjustment differences as formal group effects.
17. Write only `2.4 Data Analysis` and all subsections of `3 Results` unless the user asks for more. Read [reporting-standard.md](../../references/reporting-standard.md) and [reference-paper-notes.md](../../references/reference-paper-notes.md). Report observed values from generated tables, never placeholders or invented statistics.
18. Run the quality gate below before delivery.

## Missing data

Report missingness by node and the final analytic sample. Do not silently default to listwise deletion. Use pairwise correlations only when justified for the selected estimator and describe it. If imputation is used, keep it outside the network estimator, document the method and number of imputations, and state how network estimates were pooled or sensitivity-checked.

## Quality gate

Fail the run rather than overclaim when any item below is unresolved:

- non-numeric cells remain in modeled columns without an explicit categorical encoding;
- binary levels are not exactly two after missing-value handling;
- a categorical node has an unmodeled empty or extremely sparse level;
- node order differs among data, labels, communities, adjacency matrix, or figures;
- predictability vector length or order differs from the node list;
- a reported strongest/central/bridge node is not supported by an exported table;
- bootstrap type is mislabeled (`case`, `nonparametric`, or custom);
- residualization was performed once before bootstrap rather than refitted within each resample;
- a binary or ordinal symptom was linearly residualized without an explicit, defensible justification;
- covariates appear in symptom centrality, bridge centrality, or intervention-target rankings;
- confounders were selected only through significance screening rather than a priori rationale;
- CS coefficients are missing from the text or interpreted against the wrong index;
- Results contain causal language from cross-sectional data;
- the manuscript reports software/package versions that were not captured at runtime.

## Deliverables

Create a stable output directory containing:

- `analysis.R`, `sessionInfo.txt`, `model_decision.txt`, `covariate_decision.txt`, and a data-flow/exclusion log;
- `node_audit.csv`, `node_descriptives_predictability.csv`, `edges.csv`, `centrality.csv`, `stability.csv`, and bridge tables when applicable;
- adjusted and unadjusted symptom-network summaries plus a sensitivity comparison table when covariates are present;
- network, centrality, accuracy/stability, difference-test, and bridge figures;
- `manuscript_sections.md` containing only Section 2.4 and Section 3;
- a concise run summary listing warnings, sensitivity analyses, and unresolved decisions.

Do not claim successful completion unless the R script ran without errors and every reported statistic can be traced to an output file.
