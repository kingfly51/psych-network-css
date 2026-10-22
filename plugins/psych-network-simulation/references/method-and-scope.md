# NIRA method and scope

## Core algorithm and estimator choice

NIRA uses a fitted binary Ising model and perturbs node thresholds while holding the estimated edge matrix fixed. For tractable networks, current NIRApost provides `analyticalNIRAtest()` and `analyticalBridgeNIRAtest()`: these enumerate model states exactly and calculate model-based expected outcomes without Monte Carlo estimation error. Exact enumeration has exponential cost in the number of nodes, so obey package limits rather than raising them automatically.

Participant bootstrap in the analytical functions addresses sampling uncertainty in the fitted network/data; it is conceptually distinct from Monte Carlo error. Use `method = "mc"` only when exact enumeration is infeasible or explicitly requested. Do not run both estimators by default. Legacy Monte Carlo workflows (`simulateResponses()`, permutation tests, and repeated simulation stability) remain optional and should be selected only when they answer a prespecified question and match the installed package API.

Use one primary intervention direction and dose. Moderation/fixed-edge checks, dose sensitivity, and ranking-stability analysis are optional rather than a mandatory multi-analysis battery. If a fixed-edge diagnostic is run and stable moderation is found, label the projection assumption-sensitive.

## Single versus dual network

Use single-network NIRA only when every node belongs to one coherent measurement framework and the sum of all included 0/1 nodes is substantively meaningful. The intervention candidates and outcome-score nodes are the same set.

Use dual-network NIRA when one subnetwork supplies intervention candidates and another supplies the outcome. Fit the joint Ising network, perturb only intervention-subnetwork thresholds, and sum only the prespecified outcome-subnetwork nodes. Compare simulation rankings with bridge-network findings rather than treating whole-network strength as an equivalent metric.

Never use a whole-network sum that combines conceptually different constructs such as childhood adversity events and current anxiety symptoms.

## Assumptions and stopping rules

- Observations are independent and nonnested unless dependence is explicitly modeled elsewhere.
- Nodes are genuinely binary and coded consistently, usually 0 = absent and 1 = active/more severe.
- The Ising representation uses pairwise interactions; omitted higher-order structure can matter.
- Included nodes are substantively appropriate. Irrelevant or omitted variables can bias the thresholds interpreted as spontaneous activation tendencies.
- The edge matrix is assumed not to change when a threshold is perturbed. Stable moderation effects directly challenge this assumption.
- A non-empty stable-moderator result normally prevents primary NIRA interpretation. Continuing is an explicitly assumption-violating sensitivity analysis.

## Perturbation intensity

Two threshold SDs is a common demonstration setting, not a universal treatment dose. Prespecify one plausible primary intensity; use a small number of sensitivity values only when justified. Do not choose intensity solely to obtain significance. The unit is SD of the estimated threshold vector, not the observed item score SD or a clinical dose.

## Covariates

Covariates are never candidate intervention targets in this workflow. Ordinary residualization is unsuitable for preserving binary symptom nodes. Classic nodeIdentifyR/NIRApost code does not automatically turn a joint covariate model into a valid confounder-adjusted Ising intervention. If confounding control is essential, state that the standard NIRA estimate is unadjusted and obtain methodological guidance for a defensible adjusted simulation rather than silently inserting covariates or residuals.

## Interpretation

NIRA outputs model-based projections conditional on the fitted cross-sectional Ising network, perturbation rule, fixed-edge assumption, and simulated sample size. They identify potential targets for future intervention research; they do not establish causal treatment effects, clinical efficacy, prevention efficacy, or individual prognosis.
