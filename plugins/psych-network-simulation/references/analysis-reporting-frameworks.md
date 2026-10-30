# Simulation network analysis and reporting frameworks

Before running either workflow, select and follow the relevant framework below. The required deliverable is a paper-style `manuscript_sections.md` and Word `.docx` containing Section 2.4 Data Analysis and supported subsections of Section 3 Results, not a short executive summary. Every claim must be traceable to a machine-readable output. Use real user data when suitable; never fabricate or silently transform user observations. A synthetic example is permissible only when the user explicitly authorizes it, and every file/report must identify it as non-empirical.

## Cross-sectional NIRA

### Analysis framework

1. Confirm independent observations; establish binary nodes with observed values exactly 0/1 and a declared direction. Do not infer meaning, reverse coding, communities, or thresholds from opaque names. Do not automatically dichotomize ordinal/continuous items.
2. Define one coherent single-network score or a prespecified bridge design with distinct intervention/outcome communities. Audit sample flow, missingness, node prevalence, sparse/constant nodes and roles.
3. Fit one Ising model; record estimator, AND/OR rule, tuning, edge matrix and thresholds. Run the fixed-edge moderation prerequisite and retain its corrected output.
4. Current NIRApost >=1.2 analytical workflow is primary when tractable: exact enumeration with participant resampling, both alleviating and aggravating directions, and one prespecified dose per direction. It yields sampling uncertainty and top-rank frequency, distinct from the older Monte Carlo pipeline.
5. If exact enumeration is infeasible, use the separate Monte Carlo workflow, including permutation testing and repeated-simulation ranking stability. Do not combine both workflows by default or conflate MC error with participant-sampling uncertainty.
6. Export target-wise projected scores/effects for both directions, baseline values, CIs, adjusted p values, effect-size definition, rank-stability fields and all settings.

### Section 2.4 reporting

Report software/package versions and seed; sample/design, binary coding, missing-data strategy and analytic n; node roles/communities and score; Ising estimator/fixed parameters; moderation model/resamples and result; exact/MC workflow; both intervention directions/doses; participant resampling, multiplicity, effect-size definition, alpha and rank-stability interpretation.

### Section 3 reporting

- **3.1 Sample and node audit:** starting/analytic n, exclusions, missingness, prevalence and sparse/constant flags.
- **3.2 Network context and assumptions:** model and edge context only where exported; fixed-edge/moderation assessment or explicit statement that it was not assessed.
- **3.3 Alleviating and aggravating projections:** baseline/outcome score and target-wise expected score/effect, CI, adjusted inference, effect size and rank stability for each direction. Rank frequency alone is not evidence targets differ significantly.
- **3.4 Assumptions and boundary:** report moderation first; if it challenges fixed edges, label projections assumption-sensitive. State projections are conditional on a cross-sectional Ising model and are not causal treatment effects.

### Required outputs

Node metadata/audit, sample-flow log, edge weights, thresholds, moderation output, both-direction analytical effect/resampling tables and exact plots, settings/session info, and claim traceability.

## Dynamic KimNIRA

### Analysis framework

1. Require dense binary EMA/ESM observations with declared participant ID and ordered day/beep or timestamp. Audit duplicates, missingness, node coding, within-person coverage and transitions per participant.
2. Predefine transition construction, overnight/gap policy, minimum observations, node set, and meaning of each variable. Preserve real data and report exclusions explicitly.
3. Follow the exact `kimNIRA_wf.docx` sequence: synchronous first-order KIM, nodewise logistic mixed estimation and edge screening/refit; temporal and between-person networks and centrality separately; contemporaneous dependence, lag-2 predictive check only with sufficient consecutive occasions, and mixing/stationary-landscape diagnostics. For the landscape, run `kimBistability()` on the NIRA result so it covers baseline plus every target, and plot K (active nodes) against U(K) = −log P(K); the valley is the most likely stable configuration.
4. Define the sustained intercept perturbation and report the reference's alleviating condition at its stated dose; include equal-probability dosing as a planned sensitivity. Use `kimPlotNIRA()` for target comparisons and the trajectory plot for propagation/settling. Add aggravating intervention only when prespecified. Report total, direct, spillover, target rank and participant-resampling ranking stability. Keep the reference's parameter-recovery/network-simulation validation separate from routine empirical analyses; its propagation, feedback, and self-persistence knockout contrasts are independent sensitivity comparisons, not additive components of total effects.
5. Prefer exact stationary-distribution calculation when tractable. Otherwise use paired Monte Carlo rollout, clearly reporting burn-in, retained steps, shared random numbers, ESS/MCSE and convergence checks. Do not conflate simulation precision with participant-sampling uncertainty.

### Section 2.4 reporting

Report software/version; data/transition flow; binary coding/missingness; time/gap/overnight rules; exclusions; random-effects/slope/screening and refit settings; temporal J/h and model orientation; exact/paired-MC method; dose scale and estimand; total/direct/spillover definitions; mixing/landscape and contemporaneous-dependence checks; lag-order check only when eligible triplets exist; bootstrap/resampling and rank stability. Do not describe contemporaneous dependence as moderation. For a two-beep design with overnight transitions omitted, state that the lag-2 diagnostic was unavailable because there are no eligible consecutive triplets.

### Section 3 reporting

- **3.1 Intensive-longitudinal data audit:** records/participants, node prevalence, missingness, valid transitions and exclusions.
- **3.2 Temporal and between-person networks:** temporal J/h and salient lagged paths, then separate between-person edges/centrality.
- **3.3 Model diagnostics:** contemporaneous-dependence check; lag-2 predictive adequacy only when possible; mixing/stationary distribution and bistability; stability/potential landscape (K vs U(K)) with the baseline valley and target-wise valley shifts.
- **3.4 KIM-NIRA intervention:** alleviating condition, `kimPlotNIRA()` target comparison, exact stationary effects, direct/spillover decomposition, and trajectory/settling results. Report equal-probability results only if run; aggravation only when prespecified. Include participant-resampling uncertainty/rank stability.
- **3.5 Boundary:** distinguish finite-time from stationary effects; projections are conditional on fitted KIM assumptions and do not demonstrate clinical efficacy or causal effects.

### Required outputs

Node/transition audit, ID/exclusion reconciliation, temporal and between-person parameters/centrality, supported diagnostics, exact/paired-MC intervention tables, `kimPlotNIRA()` and trajectory figures, participant-bootstrap/rank-stability tables, settings/session info, and claim traceability.

## Word and evidence gate

Write connected academic prose, not a compressed checklist. Match detail to the available analysis. Omit unavailable statistics and state what was not estimated. Export both editable Markdown and a Word document. Use only Section 2.4 and the supported Section 3 Results. If the data are synthetic by explicit user request, mark the synthetic status prominently in both outputs.
