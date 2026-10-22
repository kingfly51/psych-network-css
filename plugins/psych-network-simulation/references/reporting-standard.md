# Reporting standard for simulation interventions

Use the JAFD application as an organizational model and the AMPPS tutorial as the methodological standard. Paraphrase; do not copy article sentences.

## Statistical analysis

Report, in this order:

1. software, R/package versions, seed, and reproducibility files;
2. binary coding, node roles, reverse coding, missing-data treatment, analytic n, and whether the workflow was single- or dual-network;
3. Ising estimator, AND/OR rule, tuning settings, and the edge/threshold parameters used for simulation;
4. moderation prerequisite test, resampling count, decision rule, and whether the fixed-edge assumption was supported;
5. NIRA simulation mechanism, 5,000 simulated observations per condition as implemented by `nodeIdentifyR`, perturbation direction and intensity, and the score compared with baseline;
6. permutation test, number of permutations used by the installed NIRApost implementation, multiplicity correction, effect size, and alpha;
7. repeated-simulation stability repetitions, ranking definition, and any parallel-computing setting;
8. prespecified intensity, missing-data, subgroup, or alternative-rule sensitivity analyses.

For dual-network NIRA, explicitly state that only intervention-subnetwork nodes were perturbed and only outcome-subnetwork nodes contributed to the score.

## Results order

### Sample and data audit

Report starting n, exclusions, analytic n, missingness, node prevalence, sparse/constant flags, and any recoding. Describe the intervention and outcome subnetworks.

### Network context and prerequisite

Briefly identify the fitted Ising model and the strongest or bridge-relevant findings only when supported by exported tables. Report stable moderation effects with moderator, affected edge, estimate/interval, and decision. If moderation exists, state that the fixed-edge premise was not fully supported before presenting any exploratory simulation.

### Simulated intervention effects

Separate alleviating and aggravating results. Report the projected top-ranked node, baseline and postintervention means, mean difference, confidence interval, Cohen's d, raw p, and adjusted p from the output table. Do not call a node “effective” without the qualifiers simulated/projected/potential.

For dual-network analysis, name both the perturbed subnetwork and the outcome score. Do not report a whole-network total.

### Stability and sensitivity

Report how often each leading node occupied rank 1 and relevant cumulative top-k positions across repeated simulations. State that rank stability is relative and does not itself test differences between ranks. Report whether conclusions changed across intervention intensities, missing-data approaches, edge-selection rules, or prespecified subgroups.

## Mandatory language limits

Prefer:

- “was the highest-ranked projected target under the specified simulation”;
- “the simulated outcome score was lower/higher than baseline”;
- “the model-based result supports prioritizing this node for prospective evaluation.”

Avoid:

- “the intervention worked”;
- “the node caused the outcome”;
- “treating this symptom will reduce the disorder”;
- “the most effective clinical target.”

End the simulation results with a boundary statement: the projections depend on a cross-sectional Ising model and require validation in real longitudinal or experimental interventions.
