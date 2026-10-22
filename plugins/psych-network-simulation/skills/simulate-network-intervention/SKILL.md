---
name: simulate-network-intervention
description: Run or design cross-sectional binary Ising network simulation interventions using NIRApost and nodeIdentifyR. Choose exact analytical enumeration for small networks, with participant bootstrap for sampling uncertainty; use Monte Carlo for larger networks only when exact enumeration is computationally infeasible. Distinguish single- and dual-network targets, check model assumptions, and report model-based outcomes without causal claims. Use for 横断面计算机模拟干预、NIRA、NIRApost、nodeIdentifyR、解析解、模拟干预靶点.
---

# Psychological network simulation intervention

Use this workflow as a second, independent feature beside the cross-sectional network-analysis plugin. Natural-language requests are sufficient; do not require an explicit `$simulate-network-intervention` invocation.

## Inputs and discovery

Treat user paths, attachments, and plausible tabular files in the current project as candidate inputs. Accept `.xlsx`, `.xls`, `.csv`, `.sav`, `.dta`, and `.rds`. If exactly one plausible dataset exists, inspect it. If several exist and the intended file cannot be inferred, ask which one to use.

Require or create `node_metadata.csv` with these columns:

- `variable`, `short_label`, `full_english_label`;
- `community`;
- `role`: `node` for single-network NIRA, or `intervention` / `outcome` for dual-network NIRA;
- `reverse`: whether 0/1 must be reversed so that 1 consistently denotes activation or greater severity;
- `include`.

Never infer item meaning, reverse coding, communities, or intervention/outcome roles from opaque variable names.

## Model decision

Read [method-and-scope.md](../../references/method-and-scope.md) and start from [analytical_nira_tutorial.R](../../assets/analytical_nira_tutorial.R). The older Monte Carlo template is an optional route, not the default.

1. Use NIRA only for independent observations and nodes coded exactly `0/1` after declared recoding. Integer storage alone is not evidence that a variable is binary.
2. Do not automatically dichotomize ordinal or continuous items. A validated, prespecified clinical cut point may be used only with explicit justification and a sensitivity analysis documenting information loss.
3. Select single-network NIRA only when all included nodes form one coherent construct and their sum score has a defensible interpretation.
4. Select dual-network NIRA when nodes from one subnetwork are intervention candidates and the summed nodes of another coherent subnetwork are the outcome, as in an exposure-to-symptom network. Do not sum disparate constructs into one outcome.
5. Covariates are not intervention nodes. Do not linearly residualize binary symptoms. Classic NIRA does not automatically provide a valid covariate-adjusted Ising simulation; if confounding control is required, document this limitation and do not pretend the simulated effect is adjusted.
6. NIRA is not a replacement for GGM/MGM simulation methods, longitudinal intervention models, network comparison, or causal effect estimation.

Record the decision in `simulation_model_decision.txt`. If NIRA is inapplicable, stop with a precise reason and recommend the appropriate separate workflow.

## Focused workflow

1. Preserve the raw file and create an analysis copy. Record exclusions, missing-value codes, reverse coding, dichotomization, and node roles.
2. Export `node_audit.csv`: data/storage class, observed values, missing n/%, prevalence of 1, sparse/constant flags, label, community, role, and coding direction. Stop for non-binary, constant, or unresolved nodes.
3. Handle missing values explicitly. Do not silently use listwise deletion. Prefer a justified binary-data imputation method plus complete-case sensitivity analysis; report the method and assumptions. If complete-case analysis is selected, report excluded n/% and why it is defensible.
4. Estimate one Ising model using the prespecified estimator and matching edge-selection rule. Export weights and thresholds.
5. Check the fixed-edge assumption with `runMgmmAnalysis()` only when this diagnostic is part of the selected NIRA workflow. Use a small run only as a clearly labeled diagnostic; reserve large resampling counts for the final analysis. If stable moderation is detected, flag the NIRA projection as assumption-sensitive rather than automatically running additional diagnostics.
6. Prefer `NIRApost::analyticalNIRAtest()` (single network) or `analyticalBridgeNIRAtest()` (intervention-to-outcome communities) for small networks. Exact enumeration has exponential cost in node count; obey package limits and do not raise them automatically. These functions enumerate states exactly; participant bootstrap, if requested, quantifies sampling uncertainty and is distinct from Monte Carlo error.
7. Use `method = "mc"` only when exact enumeration is infeasible at the current network size or the user explicitly requests it. Explain Monte Carlo error separately from sampling uncertainty. Do not run exact and MC pipelines, multiple intensity grids, both perturbation directions, or several resampling methods by default. Analyze only the prespecified intervention direction and intensity; sensitivity analyses are optional and should be few and justified.
8. For single-network NIRA, estimate change in the coherent total score. For bridge NIRA, intervene only on the declared source community and score only the declared outcome community.
9. Export each node's estimated outcome change, uncertainty interval, and multiplicity-adjusted inference when supported by the selected analytical function. Do not mislabel Glass's Δ as Cohen's d, or exact enumeration as evidence of statistical significance without the participant-resampling inference.
10. Read [reporting-standard.md](../../references/reporting-standard.md) and write only `2.4 Data Analysis` and `3 Results` unless the user requests more. Include only diagnostics actually run; never invent values.
11. Record seed, package version, model settings, and `sessionInfo()`. Run the quality gate.

## Interpretation boundary

Always call findings “simulated,” “projected,” or “model-based potential intervention targets.” Cross-sectional NIRA perturbs model thresholds under a fixed edge matrix; it does not demonstrate that a real treatment changes the node, that the remaining edges stay fixed, or that the projected downstream change is causal. Real-world intervention validation is required.

## Quality gate

Fail or clearly label the run incomplete when:

- node coding is not exactly 0/1 or direction is inconsistent;
- intervention and outcome roles overlap in dual-network mode;
- a single-network total score mixes incoherent constructs;
- missing data are silently deleted or imputed;
- an assumption check included in the selected analysis is omitted or inconsistent with the Ising rule;
- significant moderation is present but the NIRA result is presented as primary evidence;
- analytical enumeration is described as eliminating participant-sampling uncertainty;
- Monte Carlo error is conflated with participant-sampling uncertainty;
- a conventional 2-SD perturbation is described as a realistic treatment dose without justification;
- the report calls a simulated target an effective clinical intervention or a causal determinant;
- any manuscript statistic cannot be traced to an exported table.

## Deliverables

Create a compact output directory containing:

- `analysis.R`, `sessionInfo.txt`, `simulation_model_decision.txt`, `assumption_check.md`, and a data-flow log;
- `node_metadata.csv`, `node_audit.csv`, `edge_weights.csv`, `thresholds.csv`, and moderation outputs;
- primary model-based effect table and one supporting figure when useful;
- `manuscript_sections.md` with evidence-grounded statistical analysis and Results;
- `run_summary.md` listing warnings, assumption violations, preliminary settings, and unresolved decisions.

Do not claim successful completion unless the R workflow ran without errors and each reported result is traceable.
