# Source notes

## AMPPS methodological tutorial

Wang and colleagues, *Simulation Intervention for Cross-Sectional Network Models: Based on the R Packages NodeIdentifyR and NIRApost*, Advances in Methods and Practices in Psychological Science, 2026, DOI: 10.1177/25152459261452944.

Plugin requirements drawn from the tutorial and current NIRApost source:

- binary Ising-network basis;
- distinguish analytical exact enumeration from Monte Carlo simulation;
- distinguish participant-sampling uncertainty from Monte Carlo error;
- treat moderation, permutation tests, and repeated-simulation ranking stability as optional diagnostics/legacy routes, not an automatic battery;
- explicit caveats about coherent total scores, dual-network use, missing binary data, perturbation intensity, and noncausal interpretation.

Primary code sources:

- https://github.com/kingfly51/NIRA_post
- https://github.com/JasperNaberman/nodeIdentifyR

Current NIRApost (v1.2.0 in the checked repository) adds `analyticalNIRAtest()` and `analyticalBridgeNIRAtest()`. Use current function names and arguments from installed package documentation; package APIs can change. Exact analysis may include participant resampling, which is not Monte Carlo sampling of model states.

## JAFD applied-report example

Wang and colleagues, *Being insulted by parents is the most severe early adverse experience of anxiety in adulthood*, Journal of Affective Disorders, 369, 321–328, DOI: 10.1016/j.jad.2024.08.157.

Useful reporting pattern:

1. sample characteristics;
2. joint exposure–symptom Ising-network context;
3. separate simulated alleviating and aggravating effects on the symptom outcome;
4. corrected node-wise comparisons with the simulated baseline;
5. prespecified age-group results.

Methodological upgrade: the plugin must add the AMPPS moderation prerequisite and repeated-simulation stability analysis even when an earlier applied paper did not report them.
