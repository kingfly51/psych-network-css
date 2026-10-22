# Independent-group network comparison. Local tests are primary planned follow-ups,
# not conditional on whether the global structure test is significant.
library(readxl)
library(NetworkComparisonTest)

file <- "data.xlsx"
group_var <- "group"
group_1 <- "A"
group_2 <- "B"
nodes <- c("Item1", "Item2", "Item3", "Item4")
measurement <- "continuous" # this template: continuous or truly binary only
it <- 1000L
seed <- 20261022L
p_adjust <- "holm" # prespecify one method; adjust edge and centrality families separately

dat <- as.data.frame(read_excel(file))
stopifnot(all(c(group_var, nodes) %in% names(dat)))
dat <- dat[dat[[group_var]] %in% c(group_1, group_2), c(group_var, nodes)]
g1 <- dat[dat[[group_var]] == group_1, nodes, drop = FALSE]
g2 <- dat[dat[[group_var]] == group_2, nodes, drop = FALSE]
if (!measurement %in% c("continuous", "binary"))
  stop("Ordinal/mixed networks need an explicitly validated common estimator.")
if (!all(vapply(c(g1, g2), function(d) all(vapply(d, is.numeric, logical(1))), logical(1))))
  stop("Audit/recode node measurement levels before NCT.")
if (measurement == "binary" && !all(vapply(c(g1, g2), function(d)
  all(vapply(d, function(x) all(na.omit(unique(x)) %in% c(0, 1)), logical(1))), logical(1))))
  stop("Binary nodes must be explicitly coded 0/1 in both groups.")
if (anyNA(g1) || anyNA(g2)) stop("Choose and document missing-data handling before NCT.")
if (nrow(g1) < 20 || nrow(g2) < 20) warning("Small group n; permutation tests may have low power.")

set.seed(seed)
nct <- NCT(data1 = g1, data2 = g2, paired = FALSE,
           binary.data = identical(measurement, "binary"), it = it,
           test.edges = TRUE, edges = "all",
           test.centrality = TRUE,
           centrality = c("strength", "expectedInfluence"),
           p.adjust.methods = "none", progressbar = TRUE)

# Global tests and local estimates/p-values. Correct edge and centrality families
# explicitly; retain the NCT raw values for auditability.
edge_raw <- as.data.frame(nct$einv.pvals)
if (nrow(edge_raw)) {
  names(edge_raw)[names(edge_raw) == "p-value"] <- "p_raw"
  edge_raw$p_adjusted <- p.adjust(edge_raw$p_raw, method = p_adjust)
  edge_raw$estimate_difference <- mapply(function(a, b) {
    nct$einv.real[a, b]
  }, as.character(edge_raw$Var1), as.character(edge_raw$Var2))
  write.csv(edge_raw, "nct_edge_differences.csv", row.names = FALSE)
}
cent_raw <- as.data.frame(as.table(nct$diffcen.pval), responseName = "p_raw")
names(cent_raw)[1:2] <- c("node", "centrality")
cent_raw$estimate_difference <- as.vector(nct$diffcen.real)
cent_raw$p_adjusted <- p.adjust(cent_raw$p_raw, method = p_adjust)
write.csv(cent_raw, "nct_centrality_differences.csv", row.names = FALSE)

global <- data.frame(
  test = c("network_structure", "global_strength"),
  statistic = c(nct$nwinv.real, nct$glstrinv.real),
  p_value = c(nct$nwinv.pval, nct$glstrinv.pval),
  group1_global_strength = c(NA_real_, nct$glstrinv.sep[1]),
  group2_global_strength = c(NA_real_, nct$glstrinv.sep[2]),
  n_group1 = nrow(g1), n_group2 = nrow(g2), permutations = it, seed = seed
)
write.csv(global, "nct_global_tests.csv", row.names = FALSE)
saveRDS(nct, "nct_complete.rds")
capture.output(print(nct), file = "nct_complete.txt")
sessionInfo()
