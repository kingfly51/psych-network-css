---
name: compare-cross-sectional-networks
description: Compare psychological symptom networks between independent cross-sectional groups using matched nodes and settings, NetworkComparisonTest, focused multiplicity-aware follow-ups, and manuscript-ready Sections 2.4 and 3. Use for 横断面网络比较、NCT、网络结构不变性、网络强度比较、组间网络比较.
---

# Compare cross-sectional psychological networks

Use for independent groups measured on the same nodes. This is not a repeated-wave, within-person, or causal comparison. For longitudinal questions, use the cross-lagged or dynamic-network skill.

1. Verify group independence, sample sizes, node identity/order, coding, missingness, and measurement levels. Record exclusions.
2. Fit the same model family, preprocessing, tuning settings, and node set in each group. The bundled example covers continuous Gaussian or genuinely binary nodes; ordinal/mixed networks require an estimator supported and explicitly configured for both groups. If assumptions/estimators differ, do not frame the result as a clean group contrast.
3. Start from [network_comparison_tutorial.R](../../assets/network_comparison_tutorial.R). Run a single NCT for global structure and global strength, with a prespecified permutation count (e.g., 1,000 final; smaller only for a labeled pilot).
4. Edge-wise and centrality tests are optional; run only if planned, and correct multiplicity. Accuracy/stability within each group is not itself a group-difference test.
5. Report the hypotheses, permutation count, adjustment, estimates, and uncertainty in `2.4 Data Analysis` and `3 Results`. Describe differences, not causes.

Do not use independent-sample NCT for repeated observations from the same participants. Do not infer an edge difference because one within-group estimate is significant and the other is not; test the contrast directly. Avoid unplanned subgroup, edge, and centrality batteries.
