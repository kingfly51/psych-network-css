# Analytical NIRA tutorial (NIRApost >= 1.2.0).
# Exact enumeration computes model-state outcomes without Monte Carlo error;
# participant resampling, if enabled, estimates sampling uncertainty.
library(readxl)
library(bootnet)
library(NIRApost)

# ---- Edit configuration ----
file <- "binary_nodes.xlsx"
nodes <- c("Node1", "Node2", "Node3", "Node4")
mode <- "single" # "single" or "bridge"
perturbation <- "alleviating" # use only the prespecified direction
dose_sd <- 1
n_resample <- 1000L # reduce only for a clearly labeled pilot
seed <- 20261022L
# For bridge mode, define one community per node in the same node order:
groups <- c("Exposure", "Exposure", "Outcome", "Outcome")
# ----------------------------

dat <- as.data.frame(read_excel(file))
stopifnot(all(nodes %in% names(dat)))
dat <- dat[nodes]
if (anyNA(dat)) stop("Choose and document a binary-data missingness strategy before analysis.")
if (!all(vapply(dat, function(x) all(na.omit(unique(x)) %in% c(0, 1)), logical(1))))
  stop("Nodes must be explicitly coded 0/1; resolve other values and missingness first.")
if (any(vapply(dat, function(x) length(unique(na.omit(x))) < 2L, logical(1))))
  stop("Remove/resolve constant nodes before fitting.")

# Fit one Ising network using the prespecified estimator/rule.
fit <- estimateNetwork(dat, default = "IsingFit", rule = "AND")
set.seed(seed)
if (mode == "single") {
  result <- analyticalNIRAtest(
    data = dat, edge_weights = fit$graph, thresholds = fit$intercepts,
    perturbation_type = perturbation,
    amount_of_SDs_perturbation = dose_sd,
    nResample = n_resample, method = "BH", seed = seed,
    parallel = FALSE
  )
} else if (mode == "bridge") {
  result <- analyticalBridgeNIRAtest(
    data = dat, edge_weights = fit$graph, thresholds = fit$intercepts,
    groups = groups, intervention_group = "Exposure", outcome_group = "Outcome",
    perturbation_type = perturbation,
    amount_of_SDs_perturbation = dose_sd,
    nResample = n_resample, method = "BH", seed = seed,
    parallel = FALSE
  )
} else stop("mode must be 'single' or 'bridge'.")

saveRDS(result, "analytical_nira_result.rds")
str(result, max.level = 2) # inspect installed-version result fields before export
sessionInfo()
