# Confounder control in a cross-sectional symptom network

## Scope

Treat covariates only as adjustment variables. The target remains the conditional association structure among symptom nodes. Do not use this workflow for moderation, subgroup comparison, prediction-factor discovery, causal direction, or longitudinal networks.

## Selection

Require an a priori substantive or causal rationale for every confounder. Record candidate, decision, coding, reference level, missingness, functional form, and rationale. Do not select confounders solely through univariate significance tests, stepwise regression, or association with a symptom total score. Do not adjust for a variable that may be a mediator or collider without explicit justification.

## Strategy A: residualization

Use as the default only when all symptom nodes are continuous and the conditional mean model is credible.

1. Fit each symptom on the same prespecified covariate design matrix.
2. Include justified nonlinear terms and interactions only when they are part of the confounder mean model, not as network moderation tests.
3. Retain residuals and estimate the symptom GGM from them.
4. Refit all covariate regressions inside every nonparametric or case-dropping bootstrap resample.
5. Report that the network represents symptom associations after removal of covariate-related mean variation.

Do not use ordinary least-squares residuals for binary or ordinal symptoms and then claim that an Ising or ordinal GGM was estimated. Generalized-model residuals are not automatically equivalent to a covariate-adjusted graphical model.

## Strategy B: joint conditional adjustment

Use when symptom or confounder types are mixed, or when residualization would destroy the measurement scale.

1. Encode symptom and covariate types correctly.
2. Estimate a joint model appropriate to all types, commonly an MGM or a specialized covariate-adjusted graphical model.
3. Extract the symptom-to-symptom adjacency submatrix as the target network.
4. Re-estimate the full joint model inside every bootstrap resample before extracting the symptom subnetwork.
5. Exclude covariates from symptom centrality, bridge communities, bridge metrics, primary figures, and intervention-target language.
6. Export symptom-covariate coefficients only as adjustment diagnostics, not primary findings.

Regularization may shrink covariate relations to zero. If covariates must be forced into the adjustment set, use an estimator that supports unpenalized or structurally included covariate effects, or disclose this limitation. Simply placing a covariate in a penalized network does not guarantee complete adjustment.

## Required sensitivity analysis

Estimate an unadjusted symptom-only network using comparable settings. Compare it descriptively with the adjusted network using:

- retained/nonzero edges and edge-weight changes;
- strongest within- and between-community edges;
- symptom strength and expected influence rankings;
- symptom predictability;
- bridge expected influence when applicable;
- edge accuracy and CS coefficients.

Do not apply a two-group Network Comparison Test to adjusted versus unadjusted networks estimated from the same participants as if they were independent groups.

## Reporting language

Use “covariate-adjusted conditional associations” and “after controlling for the prespecified confounders.” Do not say that adjustment removed all confounding, proved independence from demographic characteristics, or established causal symptom relations.
