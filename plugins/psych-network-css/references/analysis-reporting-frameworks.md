# Analysis and manuscript reporting frameworks

Use this document before writing or running each analysis. First select the applicable framework and define its required estimands, diagnostics, tables, and figures. Then run only the prespecified analysis, verify each number against saved outputs, and write `2.4 Data Analysis` and the supported subsections of `3 Results` in connected manuscript prose. Match the level of detail in the existing cross-sectional manuscript example; do not replace a paper-style account with a brief run summary. Generate a Word `.docx` from the verified manuscript text as the default deliverable, alongside the editable `.md` and reproducibility files. Include only sections 2.4 and 3 unless the user explicitly requests other sections.

The method-specific evidence basis and source-to-framework rationale are documented in [literature-reporting-basis.md](literature-reporting-basis.md). The user-provided network-comparison tutorial and KimNIRA paper are additional controlling references where indicated.

## Cross-sectional symptom network

### Analysis sequence

1. Establish participant-level analytic sample, inclusion/exclusion, node identity, measurement level, coding, missingness, covariate role, and any scoring/reverse-coding rules.
2. Audit every candidate node: observed levels/frequencies, missingness, prevalence or distribution, variability/information, and redundancy. Export the node audit and preserve unresolved labels as unresolved.
3. Prespecify confounders and document coding and adjustment strategy. Confounders are controls only, never symptom nodes. For continuous symptoms use residualization only when the mean model is defensible; otherwise choose a joint conditional model compatible with all types. Re-estimate adjustment inside every resample.
4. Select one primary estimator from observed measurement levels: Gaussian GGM with an appropriate association matrix for continuous variables; ordinal GGM with polychoric correlations for ordered categories; Ising for genuinely binary nodes; MGM for mixed types. Record estimator, association matrix, regularization, gamma, and selection rule.
5. Export the weighted adjacency matrix, edge list, density/sign/weight summaries, and strongest within-/between-community edges. Estimate predictability with a metric matched to node family (Gaussian R-squared; categorical normalized accuracy) and draw node-level predictability rings.
6. Estimate symptom-only Strength and one-step Expected Influence as primary centrality. Add bridge indices only for defensible, declared communities. Estimate nonparametric edge accuracy and case-dropping centrality/bridge stability; preserve the seed and bootstrap counts. Run only a small number of prespecified sensitivity analyses.

### Section 2.4 Data Analysis checklist

Report, in order: software and captured package versions; preprocessing/sample/missingness; node audit and redundancy decisions; confounder rationale, coding and control strategy; observed measurement levels and why the primary estimator fits; edge selection and plotting; predictability metric and covariate contribution; primary/secondary centrality; edge accuracy, case-dropping stability and CS criterion; communities and bridge measures; and only sensitivity analyses actually run. Explicitly distinguish ordinal polychoric GGM from a Gaussian Pearson model.

### Section 3 Results outline

- **3.1 Sample and node audit:** initial/final n, exclusions, missingness, node distributions/information and redundancy decisions.
- **3.2 Network structure and predictability:** nonzero/possible edges and density, sign proportions, average absolute weight if computed, strongest within- and cross-community edges, predictability range/mean and named extrema.
- **3.3 Centrality:** primary centrality extrema and supported differences; avoid declaring a unique rank without uncertainty support.
- **3.4 Accuracy and stability:** edge CI pattern and every relevant CS coefficient against its prespecified threshold.
- **3.5 Bridge analysis:** only when communities are defensible; leading bridge values, uncertainty/differences, and bridge-specific CS.
- **3.6 Sensitivity analyses:** adjusted-versus-unadjusted symptom subnetwork comparison first when applicable, followed by estimator/gamma/missingness alternatives actually run.

### Required machine-readable outputs

`node_audit.csv`, `edges.csv`, `network_summary.csv`, `node_descriptives_predictability.csv`, `centrality.csv`, `stability.csv`, bridge tables if applicable, sensitivity comparison if applicable, and a claim-to-source traceability table. Figures: symptom network with predictability rings, centrality, and only diagnostics actually run.

## Independent cross-sectional network comparison

### Analysis sequence

Verify group independence, group n, matched node identity/order and coding, missingness, and a model family valid for the measurement level in both groups. Fit both groups with identical preprocessing and estimation settings. In one NCT permutation run test global structure invariance and global strength, all individual edges, and prespecified node centralities. The original NCT's core tests are structure, global strength, and edge invariance; centrality invariance is an additional software-supported test included here because the user-provided framework requires it. Local edge and centrality contrasts are planned analyses and are not suppressed because a global test is nonsignificant. Correct edge tests as one family and node-by-centrality tests as a second family; report the method and adjusted p values. Use Strength and Expected Influence as primary node metrics; include Closeness/Betweenness only when justified and interpret in light of each network's stability.

### Section 2.4 Data Analysis checklist

Report grouping variable and independent-group design; group-specific inclusion/missing-data rules and analytic n; matched nodes and measurement/model assumptions; estimator/settings held constant; NCT version, permutation count, seed, global/local tests, and multiplicity procedure. State edge convention and centrality scaling.

### Section 3 Results outline

- **3.1 Group sample and node audit:** n per group, exclusions/missingness, and confirmation of matched node support.
- **3.2 Global network comparison:** structure test statistic and exact p; each group's global strength, difference statistic and exact p.
- **3.3 Edge-level comparisons:** number of edges tested, correction family, and supported group-specific estimates, signed difference, raw/adjusted p for differential edges; summarize null findings and retain the full table.
- **3.4 Node-centrality comparisons:** report group-specific values and corrected node-level differences for each prespecified index; distinguish between-group NCT from within-network bootstrap difference tests and note low stability.
- **3.5 Robustness:** only planned, executed checks. A difference between two within-group p-values is not evidence of a between-group difference.

### Required machine-readable outputs

`group_flow.csv`, `node_audit_by_group.csv`, `nct_summary.csv`, edge-specific estimates and `nct_edge_differences.csv`, node centrality estimates and `nct_centrality_differences.csv`, and adjusted follow-up tables. Accuracy/stability within a group must not be presented as an NCT difference test.

## C. Cross-lagged panel network (CLPN)

### Analysis sequence

Audit participant ID, waves, duplicates, attrition, node correspondence, measurement type, coding and missingness. For every adjacent pair, estimate one prespecified nodewise model per later-wave node from all earlier-wave nodes, including its autoregressive predictor. Choose an outcome-appropriate family/link and penalty; document lambda and standardization. Keep prespecified confounders in models but out of the symptom adjacency matrix. Separate diagonal autoregressive from off-diagonal cross-lagged paths. Compute off-diagonal in-/out-strength (absolute sums) and in-/out-expected influence (signed sums), and plot both directions separately. Include participant-level nonparametric edge bootstrap and case-dropping stability for directional influence in runnable analysis code. Use spring layout and fixed seed. Bootstrap may be skipped only for a labeled demonstration; never supply made-up stability results. Describe the sampled time interval and avoid claiming within-person or causal effects from a standard between-person CLPN; with 3+ waves, flag stable-trait confounding and consider an explicitly justified within-person model or sensitivity analysis rather than silently switching estimands.

### Section 2.4 Data Analysis checklist

Report software/package versions; participant ID and wave construction; n/attrition; node matching, scoring and missingness; per-transition family/link, nodewise regularization, standardization and penalty selection; autoregressive predictors; control-only covariates; matrix orientation and directional-index formulas; bootstrap resamples, edge CIs/difference tests and CS thresholds/values; spring layout/seed. State when only one transition was available and do not imply replication across time.

### Section 3 Results outline

- **3.1 Panel sample and node audit:** participants per wave/transition, exclusions, attrition, missingness and node distributions.
- **3.2 Network structure:** report counts/ranges for diagonal autoregressive and off-diagonal cross-lagged paths, with the spring-layout directed graph.
- **3.3 Cross-lagged paths and predictability:** off-diagonal nonzero count, sign/range, strongest prespecified paths and direction; include estimates/CIs or selection status, and nodewise prediction when estimated.
- **3.4 Incoming/outgoing influence:** plot and report leading nodes for in-/out-strength and in-/out-EI with bootstrap intervals; rank alone is not a significance claim.
- **3.5 Accuracy, stability and limits:** edge CI/difference findings; CS for each directional index and threshold interpretation; cautiously interpret unstable values. CLPN paths are prospective associations, not causal effects.

### Required machine-readable outputs

`panel_flow.csv`, `node_correspondence.csv`, transition-specific full coefficient matrices and path table, nonzero cross-lag edges with uncertainty/selection fields, per-outcome lambda/settings, `clpn_in_out_influence.csv`, edge-bootstrap and case-drop outputs, and `claim_traceability.csv`. Figures: spring-layout directed CLPN, in-/out-influence plots and bootstrap diagnostics.

## Cross-sectional NIRA (Ising intervention simulation)

### Analysis sequence

Require independent observations and substantively interpretable nodes coded exactly 0/1, with declared activation direction. Do not automatically dichotomize ordinal/continuous variables. Define a coherent single-network score or a prespecified bridge source-to-outcome score. Audit missingness, sparse/constant nodes, node metadata and participant flow. Fit one Ising model and record AND/OR rule, edge weights and thresholds. Test the fixed-edge assumption with the moderation procedure before primary interpretation. Current NIRApost 1.2 analytical workflow: enumerate states exactly for both alleviating and aggravating directions at one prespecified dose each; participant resampling supplies sampling uncertainty and `percenttop_1` supplies rank stability. Do not add the older Monte Carlo permutation/repeated-simulation pipeline by default. If exact enumeration is infeasible, use the separate Monte Carlo workflow and label its permutation inference and simulation-rank stability explicitly.

### Section 2.4 Data Analysis checklist

Report R/package versions and seeds; independent sampling and n; exact binary coding/reverse coding, node roles/communities and missing-data treatment; Ising estimator/rule and fitted parameters; moderation model/resamples and whether fixed-edge assumption was contradicted; exact enumeration/state-space rationale; single/bridge score definition; both directions and doses; participant-resample count, multiplicity method, effect-size definition and alpha. Identify bootstrap p values/CIs and top-rank frequencies as analytical outputs, not Monte Carlo permutation results.

### Section 3 Results outline

- **3.1 Sample and binary-node audit:** starting/analytic n, exclusions/missingness, prevalence, sparse/constant flags and node decisions.
- **3.2 Network and prerequisite checks:** model summary/edge context only where exported; moderation/fixed-edge results or explicit non-estimation statement.
- **3.3 Alleviating and aggravating projections:** for each direction report baseline score, target-wise exact projected score/change, intervals, effect-size label, adjusted inference, and `percenttop_1` rank stability. Interpret rank separation only when statistically supported.
- **3.4 Assumptions and limits:** report moderation before interpreting projections; if it challenges fixed edges, mark results assumption-sensitive or stop confirmatory interpretation. Projections are not causal or clinical treatment evidence.

### Required machine-readable outputs

`simulation_model_decision.txt`, node metadata/audit, Ising edge weights and thresholds, assumption-check output when run, projection table, resampling/effect table, package settings, and claim traceability. Do not label Glass's delta as Cohen's d.

## E. Dynamic KimNIRA

### Analysis sequence

Use `kimNIRA_wf.docx` as the controlling method/reporting reference for this skill. Require intensive-longitudinal binary data, participant ID, ordered within-person observations, and declared node coding. Audit usable transitions, within-person coverage, gaps/overnight exclusions, missingness and participant exclusions. (1) Fit the synchronous, first-order kinetic Ising model; report nodewise logistic estimation, random-intercept vs random-slope structure, edge-screening rule (the reference uses BH q=.10 over candidate lagged edges followed by unpenalized refitting), and the temporal J matrix and h vector. (2) Report the between-person network separately from temporal dynamics; summarize out-/in-strength for temporal J and strength/EI for between-person links. (3) Assess the diagnostics actually relevant to the paper: contemporaneous dependence, first-order vs lag-2 predictive adequacy only when sufficient consecutive observations exist, and KIM mixing/stationary landscape or bistability. Do not call any of these a moderation/edge-invariance test. (4) Define the sustained intercept/logit perturbation and outcome estimand. The reference's primary intervention is alleviating; report total, direct and spillover effects, and also its equal-probability-dose comparison when that is part of the planned analysis. (5) For tractable p, calculate the stationary distribution exactly; use paired Monte Carlo rollout only when exact enumeration/linear solution is infeasible, with burn-in, retained steps, paired common random numbers, MCSE/ESS and convergence diagnostics reported. (6) Show intervention results using `kimPlotNIRA()`; use trajectory visualization for time-course results and report target ranking stability from participant-level resampling. Do not add an aggravating intervention unless the research question prespecifies it. Do not substitute generic centrality ranks for simulated intervention targets.

The reference paper also contains a method-validation simulation study (parameter recovery and designed/random networks comparing target rankings with centrality across logit and equal-probability doses). Its propagation, feedback, and self-persistence knockout contrasts are separate sensitivity comparisons, not additive components of the intervention effect. These belong to that algorithm-validation workflow, not every user's empirical analysis; include them only when evaluating or reproducing the method paper itself.

### Section 2.4 Data Analysis checklist

Report R/package versions; initial records/participants and analytic participants; node coding and within-/between-person transition rules; missingness, excluded IDs/counts, gaps and overnight policy; estimator and random-effects structure; global edge-screening multiplicity and refit; J/h parameterization and network orientation; exact stationary vs paired-MC engine and its computational rationale; intervention scale (common logit shift vs equal-probability calibration), dose and baseline estimand; total/direct/spillover definitions; bootstrap/resampling and rank stability; and only diagnostics that the design supports. For two daily observations with overnight transitions excluded, explicitly state that three-consecutive-occasion lag-order checks are unavailable; do not claim the Markov assumption was confirmed. Report contemporaneous dependence as a model adequacy diagnostic, not moderation.

### Section 3 Results outline

- **3.1 Intensive-longitudinal data audit:** initial records/participants, analytic participants, valid transitions, missingness, exclusions and per-node prevalence.
- **3.2 Temporal and between-person networks:** number/distribution of retained directed temporal edges, strongest lagged associations, fitted thresholds/intercepts, and a separately summarized between-person network. Report distinct temporal in-/out-centrality and between-person strength/EI.
- **3.3 Model diagnostics:** contemporaneous dependence; lag-order check if adequate consecutive data exist (otherwise why not estimable); mixing/relaxation and stationary activation landscape/bistability. Distinguish empirical checks from model assumptions.
- **3.4 KIM-NIRA interventions:** report the reference's alleviating result and `kimPlotNIRA()` figure; describe the equal-probability sensitivity only if run. Give baseline and projected stationary activation, total/direct/spillover effects, target ranks, propagated trajectory and settling steps where estimated, and participant-bootstrap ranking uncertainty. Include aggravation only when prespecified. State that model-based interventions do not establish clinical efficacy or causal effects.

### Required machine-readable outputs

`ema_flow.csv`, `node_audit.csv`, `transition_audit.csv`, temporal J/h and between-person parameter/centrality tables, contemporaneous-dependence and supported lag-order diagnostics, mixing/stationary-landscape outputs, intervention estimand/settings, exact or paired-MC results, `kimPlotNIRA()` figure, trajectories, participant-bootstrap/rank-stability tables, and claim traceability. Report sample-flow discrepancies as unresolved.

## Cross-cutting writing and export gate

For all five analysis types: use completed-analysis past tense; write connected, paper-style paragraphs in the requested language; preserve short English node labels and define them once; separate numerical evidence from interpretation; report only generated results; and include a source locator for every numerical claim. Do not substitute `run_summary.md` for the manuscript. Export a Word document containing exactly `2.4 Data Analysis` and the applicable `3 Results` subsections, plus editable Markdown. If data are synthetic for a software demonstration, mark the manuscript and Word document prominently as synthetic and non-empirical. Never create synthetic data to fill gaps in a user's real analysis without clearly labeling the dataset and all downstream results.
