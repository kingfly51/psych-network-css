# Analytical NIRA tutorial (NIRApost >= 1.2.0): moderation prerequisite,
# exact-state enumeration and participant-bootstrap uncertainty/rank stability.
library(readxl)
library(bootnet)
library(NIRApost)

# ---- Edit configuration ----
file <- "binary_nodes.xlsx"
nodes <- c("Node1", "Node2", "Node3", "Node4")
mode <- "single" # "single" or "bridge"
dose_sd <- 2 # justify the standardized intervention intensity
n_resample <- 1000L # use >=1000 for final analyses; label any pilot
moderation_resamples <- 1000L
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
if (utils::packageVersion("NIRApost") < "1.2.0")
  stop("Update NIRApost to >=1.2.0 for analytical NIRA. Do not silently fall back to MC.")
if (!all(c("nResample", "method", "seed") %in%
         names(formals(NIRApost::analyticalNIRAtest))))
  stop("Installed NIRApost analytical API is older/different; inspect help() before running.")

# Moderation challenges the fixed-edge assumption underlying NIRA; run before
# interpreting intervention targets. Stop the primary analysis if moderation is found.
moderation <- NIRApost::runMgmmAnalysis(
  data = as.matrix(dat), plotResults = FALSE, rule = "AND",
  lambdaGam = 0.25, nB = moderation_resamples, ncores = 1L
)
saveRDS(moderation, "nira_moderation.rds")
write.csv(as.data.frame(moderation$significant_moderators),
          "nira_moderation_significant.csv", row.names = FALSE)
if (length(moderation$significant_moderators))
  stop("Stable moderation detected: do not interpret fixed-edge NIRA as primary results.")

run_direction <- function(direction) {
  args <- list(
    data = dat, perturbation_type = direction,
    edge_weights = fit$graph, thresholds = fit$intercepts,
    amount_of_SDs_perturbation = dose_sd, nResample = n_resample,
    method = "BH", seed = seed + match(direction, c("alleviating", "aggravating")),
    parallel = FALSE
  )
  if (mode == "bridge") {
    args <- c(args, list(groups = groups,
                         intervention_group = "Exposure", outcome_group = "Outcome"))
    result <- do.call(NIRApost::analyticalBridgeNIRAtest, args)
  } else if (mode == "single") {
    result <- do.call(NIRApost::analyticalNIRAtest, args)
  } else stop("mode must be 'single' or 'bridge'.")

  saveRDS(result, paste0("analytical_nira_", direction, ".rds"))
  utils::write.csv(result$stat, paste0("analytical_nira_", direction, "_effects.csv"),
                   row.names = FALSE)
  utils::write.csv(result$exact, paste0("analytical_nira_", direction, "_exact.csv"),
                   row.names = FALSE)
  if (!is.null(result$plot))
    ggplot2::ggsave(paste0("analytical_nira_", direction, ".png"),
                    result$plot, width = 9, height = 6, dpi = 300)
  result
}

results <- lapply(c("alleviating", "aggravating"), run_direction)
names(results) <- c("alleviating", "aggravating")
saveRDS(results, "analytical_nira_both_directions.rds")
for (direction in names(results)) {
  cat("\n---", direction, "---\n")
  print(results[[direction]]$stat)
  # percenttop_1 is rank stability across participant resamples, not a test that
  # the top target differs significantly from the next target.
}
sessionInfo()
