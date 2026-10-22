# Psychological network computer-simulated intervention template
# Copy this file into the study output directory and edit the configuration.
# Method basis: nodeIdentifyR + NIRApost (single- and dual-network NIRA).

options(stringsAsFactors = FALSE)

config <- list(
  data_path = "data.xlsx",
  sheet = 1,
  metadata_path = "node_metadata.csv",
  output_dir = "simulation_output",
  mode = "auto",                    # auto, single, dual
  total_score_valid = FALSE,         # confirm substantively before changing
  missing_method = "stop",          # stop, complete_case, mode
  ising_rule = "AND",               # AND or OR; keep consistent below
  lambda_gamma = 0.25,
  formal_analysis = TRUE,
  moderation_reps = 1000,            # >=1000 formal; about 100 preliminary
  stability_reps = 1000,             # >=1000 formal; about 100 preliminary
  perturbation_intensities = c(0.5, 1, 2),
  primary_intensity = 2,
  p_adjust_method = "bonferroni",
  proceed_if_moderation = FALSE,
  parallel = TRUE,
  n_cores = max(1L, parallel::detectCores(logical = FALSE) - 1L),
  seed = 2025
)

dir.create(config$output_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(config$seed)

required <- c("bootnet", "qgraph", "dplyr", "nodeIdentifyR", "NIRApost")
missing_packages <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop(
    "Missing R packages: ", paste(missing_packages, collapse = ", "),
    ". Install CRAN packages normally and GitHub packages with ",
    "devtools::install_github('JasperNaberman/nodeIdentifyR') and ",
    "devtools::install_github('kingfly51/NIRA_post')."
  )
}
# nodeIdentifyR's current data-preparation helper uses the pipe operator from
# an attached dplyr package, so attachment is required in addition to namespace checks.
suppressPackageStartupMessages(library(dplyr))

read_input <- function(path, sheet = 1) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) stop("Install readxl.")
    return(as.data.frame(readxl::read_excel(path, sheet = sheet)))
  }
  if (ext == "csv") return(utils::read.csv(path, check.names = FALSE))
  if (ext %in% c("sav", "dta")) {
    if (!requireNamespace("haven", quietly = TRUE)) stop("Install haven.")
    x <- if (ext == "sav") haven::read_sav(path) else haven::read_dta(path)
    return(as.data.frame(x))
  }
  if (ext == "rds") return(as.data.frame(readRDS(path)))
  stop("Unsupported input extension: ", ext)
}

collapse_values <- function(x) {
  paste(utils::head(sort(unique(x[!is.na(x)])), 20), collapse = " | ")
}

mode_binary <- function(x) {
  observed <- x[!is.na(x)]
  if (!length(observed)) stop("Cannot impute a completely missing node.")
  as.numeric(names(which.max(table(observed))))
}

write_lines <- function(x, file) {
  writeLines(enc2utf8(x), file.path(config$output_dir, file), useBytes = TRUE)
}

raw_data <- read_input(config$data_path, config$sheet)
if (!file.exists(config$metadata_path)) {
  metadata_template <- data.frame(
    variable = names(raw_data),
    short_label = "",
    full_english_label = "",
    community = "",
    role = "exclude",
    reverse = FALSE,
    include = FALSE
  )
  utils::write.csv(metadata_template,
                   file.path(config$output_dir, "node_metadata_template.csv"),
                   row.names = FALSE, na = "")
  stop("Metadata file not found. Complete node_metadata_template.csv and rerun.")
}

metadata <- utils::read.csv(config$metadata_path, check.names = FALSE)
required_meta <- c("variable", "short_label", "full_english_label",
                   "community", "role", "reverse", "include")
if (!all(required_meta %in% names(metadata))) {
  stop("Metadata must contain: ", paste(required_meta, collapse = ", "))
}
metadata <- metadata[as.logical(metadata$include), , drop = FALSE]
if (!nrow(metadata)) stop("No included nodes in metadata.")
if (anyDuplicated(metadata$variable)) stop("Metadata variable names must be unique.")
if (!all(metadata$variable %in% names(raw_data))) {
  stop("Variables missing from data: ",
       paste(setdiff(metadata$variable, names(raw_data)), collapse = ", "))
}
if (any(!nzchar(metadata$short_label)) || any(!nzchar(metadata$full_english_label))) {
  stop("Every included node needs short_label and full_english_label.")
}

node_data_raw <- raw_data[, metadata$variable, drop = FALSE]
audit <- data.frame(
  variable = metadata$variable,
  short_label = metadata$short_label,
  community = metadata$community,
  role = metadata$role,
  storage_class = vapply(node_data_raw, function(x) class(x)[1], character(1)),
  observed_values = vapply(node_data_raw, collapse_values, character(1)),
  missing_n = vapply(node_data_raw, function(x) sum(is.na(x)), integer(1)),
  missing_pct = vapply(node_data_raw, function(x) mean(is.na(x)) * 100, numeric(1)),
  unique_nonmissing = vapply(node_data_raw, function(x) length(unique(x[!is.na(x)])), integer(1)),
  prevalence_1 = NA_real_,
  constant = FALSE,
  sparse = FALSE
)

node_data <- as.data.frame(lapply(node_data_raw, function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x) || is.character(x)) {
    suppressWarnings(y <- as.numeric(as.character(x)))
    if (any(is.na(y) & !is.na(x))) stop("Non-numeric category requires explicit recoding.")
    return(y)
  }
  as.numeric(x)
}), check.names = FALSE)
names(node_data) <- metadata$variable

for (j in seq_along(node_data)) {
  vals <- sort(unique(node_data[[j]][!is.na(node_data[[j]])]))
  if (!identical(vals, c(0, 1)) && !identical(vals, 0) && !identical(vals, 1)) {
    stop("Node ", names(node_data)[j], " is not coded exactly 0/1: ",
         paste(vals, collapse = ", "))
  }
  if (isTRUE(as.logical(metadata$reverse[j]))) node_data[[j]] <- 1 - node_data[[j]]
  audit$prevalence_1[j] <- mean(node_data[[j]], na.rm = TRUE)
  audit$constant[j] <- length(vals) < 2
  audit$sparse[j] <- audit$prevalence_1[j] < 0.05 || audit$prevalence_1[j] > 0.95
}
utils::write.csv(audit, file.path(config$output_dir, "node_audit.csv"), row.names = FALSE)
utils::write.csv(metadata, file.path(config$output_dir, "node_metadata.csv"), row.names = FALSE)
if (any(audit$constant)) stop("Constant nodes found; see node_audit.csv.")

rows_before <- nrow(node_data)
complete_rows <- stats::complete.cases(node_data)
if (any(!complete_rows)) {
  if (config$missing_method == "stop") {
    stop("Missing node values found. Choose and justify an explicit missing_method.")
  } else if (config$missing_method == "complete_case") {
    node_data <- node_data[complete_rows, , drop = FALSE]
  } else if (config$missing_method == "mode") {
    for (j in seq_along(node_data)) {
      node_data[[j]][is.na(node_data[[j]])] <- mode_binary(node_data[[j]])
    }
    utils::write.csv(node_data_raw[complete_rows, , drop = FALSE],
                     file.path(config$output_dir, "complete_case_sensitivity_data.csv"),
                     row.names = FALSE)
  } else {
    stop("missing_method must be stop, complete_case, or mode.")
  }
}
write_lines(c(
  paste0("missing_method=", config$missing_method),
  paste0("rows_before=", rows_before),
  paste0("rows_after=", nrow(node_data)),
  paste0("rows_excluded=", rows_before - nrow(node_data))
), "data_flow_log.txt")

roles <- tolower(trimws(metadata$role))
mode <- tolower(config$mode)
if (mode == "auto") {
  mode <- if (any(roles == "intervention") || any(roles == "outcome")) "dual" else "single"
}
if (!mode %in% c("single", "dual")) stop("mode must be auto, single, or dual.")
if (!isTRUE(config$total_score_valid)) {
  stop("Set total_score_valid=TRUE only after confirming the score is substantively coherent.")
}
if (mode == "single") {
  if (!all(roles %in% c("node", "single"))) {
    stop("Single-network mode requires all included roles to be node/single.")
  }
  intervention_nodes <- metadata$variable
  outcome_nodes <- metadata$variable
} else {
  intervention_nodes <- metadata$variable[roles == "intervention"]
  outcome_nodes <- metadata$variable[roles == "outcome"]
  if (!length(intervention_nodes) || !length(outcome_nodes)) {
    stop("Dual-network mode requires intervention and outcome nodes.")
  }
  if (length(intersect(intervention_nodes, outcome_nodes))) {
    stop("Dual-network intervention and outcome roles must not overlap.")
  }
  if (!all(roles %in% c("intervention", "outcome"))) {
    stop("Included dual-network nodes must be intervention or outcome.")
  }
}

analysis_label <- if (mode == "single") {
  "Single-network NIRA: intervention and coherent outcome-score nodes are identical."
} else {
  paste0("Dual-network NIRA: perturb ", length(intervention_nodes),
         " intervention nodes; score ", length(outcome_nodes), " outcome nodes only.")
}
write_lines(c(
  analysis_label,
  paste0("Ising rule: ", config$ising_rule),
  "Covariates are not included as intervention targets or residualized binary nodes.",
  "Interpretation: model-based projected targets, not verified causal treatment effects."
), "simulation_model_decision.txt")

set.seed(config$seed)
fit <- bootnet::estimateNetwork(node_data, default = "IsingFit", rule = config$ising_rule)
edge_matrix <- fit$graph
thresholds <- fit$intercepts
colnames(edge_matrix) <- rownames(edge_matrix) <- names(node_data)
names(thresholds) <- names(node_data)
utils::write.csv(edge_matrix, file.path(config$output_dir, "edge_weights.csv"))
utils::write.csv(data.frame(node = names(thresholds), threshold = as.numeric(thresholds)),
                 file.path(config$output_dir, "thresholds.csv"), row.names = FALSE)
saveRDS(fit, file.path(config$output_dir, "ising_fit.rds"))

png(file.path(config$output_dir, "ising_network.png"), width = 2400, height = 1800, res = 300)
plot(fit, layout = "spring", nodeNames = metadata$short_label, legend = FALSE)
dev.off()

if (config$formal_analysis && (config$moderation_reps < 1000 || config$stability_reps < 1000)) {
  stop("Formal analysis requires moderation_reps and stability_reps >= 1000.")
}

set.seed(config$seed)
moderation <- NIRApost::runMgmmAnalysis(
  data = as.matrix(node_data),
  plotResults = FALSE,
  rule = config$ising_rule,
  lambdaGam = config$lambda_gamma,
  nB = config$moderation_reps
)
saveRDS(moderation, file.path(config$output_dir, "moderation_test.rds"))
capture.output(print(moderation$significant_moderators),
               file = file.path(config$output_dir, "moderation_test.txt"))
moderation_present <- length(moderation$significant_moderators) > 0
write_lines(c(
  paste0("moderation_resamples=", config$moderation_reps),
  paste0("stable_moderation_detected=", moderation_present),
  if (moderation_present) {
    "Fixed-edge assumption is not fully supported. Primary NIRA interpretation is inappropriate."
  } else {
    "No stable moderation effect was detected; the fixed-edge assumption was not contradicted by this test."
  }
), "assumption_check.md")
if (moderation_present && !isTRUE(config$proceed_if_moderation)) {
  stop("Stable moderation detected. Outputs were saved; primary NIRA stopped by design.")
}

simulate_long <- function(edge_matrix, thresholds, perturbation_type, intensity,
                          intervention_nodes, outcome_nodes) {
  samples <- nodeIdentifyR::simulateResponses(
    edge_weights = edge_matrix,
    thresholds = thresholds,
    perturbation_type = perturbation_type,
    amount_of_SDs_perturbation = intensity
  )
  keep <- c("original", intervention_nodes)
  if (!all(keep %in% names(samples))) stop("Simulation sample names do not match metadata.")
  samples <- samples[keep]
  long <- do.call(rbind, lapply(names(samples), function(condition) {
    x <- as.data.frame(samples[[condition]], check.names = FALSE)
    if (ncol(x) != ncol(edge_matrix)) stop("Unexpected simulated sample width.")
    names(x) <- colnames(edge_matrix)
    data.frame(
      sumscore = rowSums(x[, outcome_nodes, drop = FALSE]),
      sample = condition,
      stringsAsFactors = FALSE
    )
  }))
  rownames(long) <- NULL
  long
}

analyze_condition <- function(direction, intensity) {
  set.seed(config$seed + round(intensity * 100) + match(direction, c("alleviating", "aggravating")))
  long <- simulate_long(edge_matrix, thresholds, direction, intensity,
                        intervention_nodes, outcome_nodes)
  stat_result <- NIRApost::permutationNIRAtest(long, method = config$p_adjust_method)
  tab <- stat_result$stat
  tab$node <- rownames(tab)
  tab$baseline_mean <- mean(long$sumscore[long$sample == "original"])
  tab$mean_difference <- tab$mean_other - tab$baseline_mean
  tab$direction <- direction
  tab$intensity_sd <- intensity
  tab$analysis_mode <- mode
  tab$assumption_violation <- moderation_present
  tab <- tab[, c("node", "direction", "intensity_sd", "analysis_mode",
                 "baseline_mean", "mean_other", "mean_difference",
                 "sd_other", "se_other", "ciLower_other", "ciUpper_other",
                 "cohen_d", "p", "p.adjust", "assumption_violation")]
  prefix <- paste0(direction, "_", gsub("\\.", "p", format(intensity, trim = TRUE)), "sd")
  utils::write.csv(tab, file.path(config$output_dir, paste0(prefix, "_effects.csv")), row.names = FALSE)
  saveRDS(stat_result, file.path(config$output_dir, paste0(prefix, "_permutation.rds")))
  png(file.path(config$output_dir, paste0(prefix, "_effects.png")), width = 2400, height = 1800, res = 300)
  print(NIRApost::plotMeanNIRA(stat_result, direction))
  dev.off()
  tab
}

all_effects <- list()
for (direction in c("alleviating", "aggravating")) {
  for (intensity in config$perturbation_intensities) {
    key <- paste(direction, intensity, sep = "_")
    all_effects[[key]] <- analyze_condition(direction, intensity)
  }
}
all_effects_table <- do.call(rbind, all_effects)
rownames(all_effects_table) <- NULL
utils::write.csv(all_effects_table,
                 file.path(config$output_dir, "all_intensity_effects.csv"), row.names = FALSE)

dual_stability <- function(direction) {
  one_rep <- function(i) {
    long <- simulate_long(edge_matrix, thresholds, direction,
                          config$primary_intensity, intervention_nodes, outcome_nodes)
    tapply(long$sumscore, long$sample, mean)
  }
  if (isTRUE(config$parallel) && config$n_cores > 1) {
    cl <- parallel::makeCluster(config$n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterSetRNGStream(cl, config$seed + match(direction, c("alleviating", "aggravating")))
    parallel::clusterEvalQ(cl, library(nodeIdentifyR))
    parallel::clusterExport(
      cl,
      c("simulate_long", "edge_matrix", "thresholds", "direction", "config",
        "intervention_nodes", "outcome_nodes"),
      envir = environment()
    )
    means <- parallel::parLapply(cl, seq_len(config$stability_reps), one_rep)
  } else {
    means <- lapply(seq_len(config$stability_reps), one_rep)
  }
  list(mean = do.call(rbind, means))
}

for (direction in c("alleviating", "aggravating")) {
  if (mode == "single") {
    sim_result <- NIRApost::stabilityNIRAtest(
      edge_weights = edge_matrix,
      thresholds = thresholds,
      perturbation_type = direction,
      amount_of_SDs_perturbation = config$primary_intensity,
      nReps = config$stability_reps,
      parallel = config$parallel,
      ncores = if (config$parallel) config$n_cores else NULL,
      seed = config$seed
    )
  } else {
    sim_result <- dual_stability(direction)
  }
  rank_raw <- NIRApost::findMaxN(sim_result, n = length(intervention_nodes))
  rank_table <- rank_raw
  rank_table$node <- rownames(rank_raw)
  rank_table$direction <- direction
  rank_table$intensity_sd <- config$primary_intensity
  utils::write.csv(rank_table,
                   file.path(config$output_dir, paste0(direction, "_stability.csv")),
                   row.names = FALSE)
  saveRDS(sim_result, file.path(config$output_dir, paste0(direction, "_stability.rds")))
  png(file.path(config$output_dir, paste0(direction, "_stability.png")),
      width = 2400, height = 1800, res = 300)
  print(NIRApost::plotMaxN(rank_raw, low = 1,
                          high = min(length(intervention_nodes), 7)))
  dev.off()
}

write_lines(capture.output(sessionInfo()), "sessionInfo.txt")
write_lines(c(
  paste0("analysis_mode=", mode),
  paste0("analytic_n=", nrow(node_data)),
  paste0("moderation_present=", moderation_present),
  paste0("formal_analysis=", config$formal_analysis),
  paste0("primary_intensity_sd=", config$primary_intensity),
  paste0("stability_repetitions=", config$stability_reps),
  "All effects are simulated model-based projections and require real-world validation."
), "run_summary.md")

message("Simulation intervention workflow completed: ", normalizePath(config$output_dir))
