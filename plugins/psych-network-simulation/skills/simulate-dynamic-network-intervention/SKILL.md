---
name: simulate-dynamic-network-intervention
description: Fit and simulate dynamic intervention targets in intensive longitudinal binary EMA/ESM data with KimNIRA, including exact stationary-state analysis or Monte Carlo when needed. Use for 动态模拟网络干预、KimNIRA、EMA网络干预、个体内二元动态网络、密集纵向网络.
---

# Dynamic simulated network intervention with KimNIRA

Use KimNIRA for dense binary EMA/ESM observations with participant IDs and ordered time points. This is distinct from cross-sectional NIRA and from wide-format CLPN. Interpret output as model-based projections, not causal treatment effects.

1. Audit binary node coding/direction, participant ID, day/beep or timestamp order, duplicate records, missingness, transition counts, and within-person coverage. Do not convert continuous/ordinal measures to binary without a validated, prespecified threshold.
2. Start from [kimnira_tutorial.R](../../assets/kimnira_tutorial.R). Fit one dynamic model with `fitKIM()` using the current package API; verify data columns and temporal ordering before fitting.
3. For intervention projections, prefer `runKIMNIRA(method = "exact")` when the state space is tractable. Exact state enumeration grows exponentially with the number of nodes; respect the package guard. Use `method = "mc"` only when exact enumeration is infeasible or specifically requested, and report its Monte Carlo error separately from participant-sampling uncertainty.
4. Select one intervention type and dose that answer the question. Do not automatically run all nodes, dose grids, pathway decompositions, mixing diagnostics, Markov checks, or bootstrap stability. Add only prespecified, decision-relevant checks.
5. Report transition construction, overnight policy, minimum valid transitions/person, between-person option, screening/multiplicity settings, model fit, intervention dose scale, exact/MC method, target ranking and outcome components, and caveats. Use current fitted object outputs; do not invent field names or estimates.
6. Draft only `2.4 Data Analysis` and `3 Results` unless asked otherwise. Label results dynamic model-based projections and avoid causal/clinical-efficacy claims.

Refer to the bundled tutorial and current KimNIRA package documentation. The API may change; confirm installed version and function arguments before running. Do not install packages or access GitHub without user authorization if network access requires it.
