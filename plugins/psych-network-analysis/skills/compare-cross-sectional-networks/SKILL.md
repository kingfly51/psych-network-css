---
name: compare-cross-sectional-networks
description: Compare psychological symptom networks between independent cross-sectional groups using matched nodes and settings, NetworkComparisonTest, focused multiplicity-aware follow-ups, and manuscript-ready Sections 2.4 and 3. Use for 横断面网络比较、NCT、网络结构不变性、网络强度比较、组间网络比较.
---

# Compare cross-sectional psychological networks

## Analysis-to-manuscript workflow

Before running NCT, use [analysis-reporting-frameworks.md](../../references/analysis-reporting-frameworks.md) to define the independent-group eligibility checks, primary hypotheses, exact outputs, and Results outline. Then run only those tests, verify the manuscript numbers against exported output, and write connected, paper-style `2.4 Data Analysis` and supported `3 Results` subsections. Export both `manuscript_sections.md` and `manuscript_sections.docx` by default. Use supplied data; do not invent data/results unless explicitly asked for a labeled simulation example.

Use for independent groups measured on the same nodes. This is not a repeated-wave, within-person, or causal comparison. For longitudinal questions, use the cross-lagged or dynamic-network skill.

1. Verify group independence, sample sizes, node identity/order, coding, missingness, and measurement levels. Record exclusions.
2. Fit the same model family, preprocessing, tuning settings, and node set in each group. The bundled example covers continuous Gaussian or genuinely binary nodes; ordinal/mixed networks require an estimator supported and explicitly configured for both groups. If assumptions/estimators differ, do not frame the result as a clean group contrast.
3. Start from [network_comparison_tutorial.R](../../assets/network_comparison_tutorial.R). In the standard workflow, run one NCT for global structure, global strength, all individual edges, and Strength/Expected Influence centrality contrasts; use a prespecified permutation count (e.g., 1,000 final; smaller only for a labeled pilot).
4. Correct edge tests and node-by-centrality tests as separate multiplicity families, retaining raw and adjusted p values. Do not gate local tests on a significant global structure test. Add Closeness/Betweenness only when justified and interpret them in light of their within-network stability.
5. Export group-specific edge and centrality estimates, differences, raw/adjusted p values, including null tests. Within-group accuracy/stability is not itself a group-difference test.
6. Report group flow, analytic n, matched-node/model decisions, permutation count/seed, global and local tests, supported differences, and null local findings in connected prose. Describe differences, not causes.
7. Create `claim_traceability.csv`, then export matching Markdown and Word manuscripts containing only Sections 2.4 and 3 unless the user asks otherwise.

Do not use independent-sample NCT for repeated observations from the same participants. Do not infer an edge difference because one within-group estimate is significant and the other is not; test the contrast directly. Avoid unplanned subgroup, edge, and centrality batteries.
