# Reporting standard: Sections 2.4 and 3 only

Write in the manuscript's requested language while retaining standard English statistical terms and node labels. Use past tense for completed analyses. Keep evidence, interpretation, and limitations distinct.

## 2.4 Data Analysis

Cover, in this order:

1. software and runtime-captured package versions;
2. preprocessing, exclusions, scoring, missing-data handling, and final analytic sample rule;
3. prespecified confounders, selection rationale, coding, missingness, functional form, and whether adjustment used residualization or a joint conditional model;
4. node audit, informativeness, and redundancy screening;
5. observed node types and the chosen model, association matrix, regularization/selection settings, and why the model matched the data;
6. network display conventions and predictability metric by node family, including whether covariates contributed to prediction;
7. primary centrality indices and any secondary indices, calculated for symptoms only;
8. edge accuracy, case-dropping stability, difference tests, bootstrap counts, seed, CS criterion, and confirmation that confounder adjustment was repeated within resamples;
9. community definition, bridge statistic, and bridge stability when applicable, excluding covariates;
10. unadjusted versus adjusted sensitivity analysis and any other sensitivity analyses actually performed.

Do not say ordinal data are handled by a GGM without naming the polychoric correlation step. Do not say `R2` for binary/categorical predictability.

## 3 Results structure

Use only subsections supported by actual outputs:

### 3.1 Sample and node audit

Report initial and analytic sample sizes, exclusions/missingness, node distributions, low-informativeness or redundancy findings, and any resulting node decision. Point to the node-audit table.

### 3.2 Network structure and predictability

Report the number/proportion of nonzero edges, positive/negative edges, average absolute edge weight if calculated, the strongest within- and between-community edges, and mean/range of predictability. Name nodes with short code plus full English label on first mention.

### 3.3 Centrality

Report the highest and lowest primary centrality values and statistically supported differences. Avoid ranking claims based on tiny numerical differences when bootstrap difference tests do not separate nodes.

### 3.4 Accuracy and stability

Describe edge CI width/overlap cautiously, report every relevant CS coefficient numerically, and state which indices do or do not meet the prespecified threshold. Do not call a network "stable" from visual inspection alone.

### 3.5 Bridge analysis

Include only when communities were defined a priori or are otherwise substantively defensible. Report the largest bridge expected influence values, significant bridge differences, and bridge-specific CS coefficients. If bridge stability is inadequate, identify candidates descriptively but do not call them robust bridge targets.

### 3.6 Sensitivity analyses

When covariates are present, report the unadjusted versus adjusted symptom-network comparison first. Then report only other analyses actually run, including estimator/correlation/gamma/missing-data alternatives and whether conclusions materially changed.

## Language constraints

- Say "was associated with," not "caused," "activated," or "led to," for cross-sectional edges.
- Say "more central in the estimated network," not "the most important symptom" unless uncertainty supports a unique ranking.
- Separate numeric results from clinical implications; clinical interpretation belongs in Discussion and is outside this deliverable.
- Include exact p values when available, otherwise thresholds such as `p < .001`; include confidence intervals where generated.
- Every number in the prose must match an exported table or machine-readable summary.

## Traceability check

Before finalizing, build a private claim-to-source check with columns: manuscript sentence, output file, row/field, value, verified. Remove or qualify any sentence that fails the check.
