---
name: simulate-dynamic-network-intervention
description: Fit and simulate dynamic intervention targets in intensive longitudinal binary EMA/ESM data with KimNIRA, including exact stationary-state analysis or Monte Carlo when needed. Use for 动态模拟网络干预、KimNIRA、EMA网络干预、个体内二元动态网络、密集纵向网络.
---

# Dynamic simulated network intervention with KimNIRA

## Analysis-to-manuscript workflow

Before modeling, follow [analysis-reporting-frameworks.md](../../references/analysis-reporting-frameworks.md) to define the participant/transition flow, binary node audit, time construction, model settings, exact-versus-MC decision, intervention estimand, tables/figures, and Results outline. Use supplied data only; do not create synthetic data unless explicitly authorized and label it as a demonstration. Reconcile all source IDs, package exclusions, and model-retained participants before reporting. Verify each result against saved outputs, write paper-style connected prose for `2.4 Data Analysis` and supported `3 Results` subsections, and export matching Markdown and Word (`manuscript_sections.docx`).

Use KimNIRA for dense binary EMA/ESM observations with participant IDs and ordered time points. This is distinct from cross-sectional NIRA and from wide-format CLPN. Interpret output as model-based projections, not causal treatment effects.

1. Audit binary node coding/direction, participant ID, day/beep or timestamp order, duplicate records, missingness, transition counts, and within-person coverage. Do not convert continuous/ordinal measures to binary without a validated, prespecified threshold.
2. Start from [kimnira_tutorial.R](../../assets/kimnira_tutorial.R). Fit one dynamic model with `fitKIM()` using the current package API; verify data columns and temporal ordering before fitting.
3. Follow `kimNIRA_wf.docx` as the user-provided reference: fit the synchronous first-order KIM using nodewise logistic models; state random-intercept/random-slope structure, global BH edge-screening rule and unpenalized refit; report temporal J/h and the between-person network separately, with temporal in/out-strength and between-person centrality kept distinct.
4. Run only supported diagnostics: contemporaneous dependence; lag-2 predictive adequacy only if eligible consecutive observations exist; and mixing/stationary activation landscape or bistability. Do not describe these as moderation or edge-invariance tests. If two daily observations are used and overnight transitions are excluded, explain that there are no three-consecutive-occasion triplets for a lag-order check.
5. Define the sustained intercept perturbation and exact outcome estimand. The reference's primary condition is alleviating, with common logit dose and an equal-probability-dose comparison. Use exact stationary-distribution computation when tractable; otherwise use paired MC rollout and report burn-in, retained steps, shared random numbers, ESS/MCSE and convergence diagnostics. Use `kimPlotNIRA()` for target comparisons and trajectory plotting for propagation/settling. Add aggravating projections only when prespecified. Report participant-resampling uncertainty and target-ranking stability separately from MC error.
   Keep the paper's parameter-recovery/network-simulation validation study separate from routine empirical analysis. If reproducing that study, the propagation, feedback, and self-persistence knockout contrasts are distinct sensitivity comparisons, not additive components of total intervention effects.
6. Follow the framework and draft only `2.4 Data Analysis` and supported `3 Results` subsections unless asked otherwise. Include exact model settings and estimands, label results dynamic model-based projections, and avoid causal/clinical-efficacy claims.
7. Create `claim_traceability.csv` and export matching Markdown and Word manuscripts.

Refer to the bundled tutorial and current KimNIRA package documentation. The API may change; confirm installed version and function arguments before running. Do not install packages or access GitHub without user authorization if network access requires it.
