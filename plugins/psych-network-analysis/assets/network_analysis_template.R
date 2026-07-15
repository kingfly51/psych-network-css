# Cross-sectional psychological symptom network analysis template
# Copy this file to the project output directory and edit only the configuration
# and scoring sections before running. Never overwrite the raw data.

set.seed(20260715)

# ---- Configuration: MUST be tailored to the study ----
cfg <- list(
  data_path = "PATH/TO/DATA.xlsx",
  sheet = 1,
  output_dir = "network_output",
  node_names = c(),
  short_labels = c(),
  full_labels = c(),
  communities = c(),
  measurement = c(), # one of: continuous, ordinal, binary, nominal, count
  covariate_names = c(),
  covariate_measurement = c(), # continuous, ordinal, binary, nominal, count
  covariate_strategy = "auto", # auto, residualize, joint
  missing_codes = c(-99, -999),
  gamma = 0.50,
  n_boots = 1000L,
  n_cores = max(1L, parallel::detectCores(logical = FALSE) - 1L),
  seed = 20260715L
)

required_packages <- c(
  "bootnet", "qgraph", "networktools", "mgm", "readxl", "haven",
  "readr", "dplyr", "tidyr", "purrr", "tibble", "stringr", "moments"
)
missing_packages <- required_packages[!vapply(required_packages, requireNamespace,
                                               quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing_packages)) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}

dir.create(cfg$output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(length(cfg$node_names) > 1L)
stopifnot(length(cfg$node_names) == length(cfg$short_labels))
stopifnot(length(cfg$node_names) == length(cfg$full_labels))
stopifnot(length(cfg$node_names) == length(cfg$measurement))
if (length(cfg$communities)) stopifnot(length(cfg$node_names) == length(cfg$communities))
if (length(cfg$covariate_names)) {
  stopifnot(length(cfg$covariate_names) == length(cfg$covariate_measurement))
  stopifnot(!any(cfg$covariate_names %in% cfg$node_names))
}
if (anyDuplicated(cfg$node_names) || anyDuplicated(cfg$short_labels)) {
  stop("Node names and short labels must each be unique.")
}

out <- function(name) file.path(cfg$output_dir, name)
set.seed(cfg$seed)

# ---- Import ----
read_input <- function(path, sheet = 1) {
  ext <- tolower(tools::file_ext(path))
  switch(
    ext,
    xlsx = readxl::read_excel(path, sheet = sheet),
    xls = readxl::read_excel(path, sheet = sheet),
    csv = readr::read_csv(path, show_col_types = FALSE),
    sav = haven::read_sav(path),
    dta = haven::read_dta(path),
    rds = readRDS(path),
    stop("Unsupported data extension: ", ext)
  )
}

raw_data <- read_input(cfg$data_path, cfg$sheet)
required_columns <- c(cfg$node_names, cfg$covariate_names)
if (!all(required_columns %in% names(raw_data))) {
  stop("Missing modeled columns: ",
       paste(setdiff(required_columns, names(raw_data)), collapse = ", "))
}

# ---- Study-specific scoring/reverse coding ----
# Add explicit scoring code here before selecting cfg$node_names. Record every
# transformation in data_flow_log below. Never change raw_data in place.
analysis_data <- raw_data
data_flow_log <- tibble::tibble(
  step = c("Imported raw data", "Selected configured network nodes"),
  n_rows = c(nrow(raw_data), nrow(analysis_data)),
  detail = c(normalizePath(cfg$data_path, winslash = "/", mustWork = FALSE),
             paste(cfg$node_names, collapse = ", "))
)

df <- analysis_data[, cfg$node_names, drop = FALSE]
covariates <- analysis_data[, cfg$covariate_names, drop = FALSE]
for (nm in names(df)) {
  x <- df[[nm]]
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  x[x %in% cfg$missing_codes] <- NA
  df[[nm]] <- x
}
for (nm in names(covariates)) {
  x <- covariates[[nm]]
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  x[x %in% cfg$missing_codes] <- NA
  covariates[[nm]] <- x
}

# Numeric encoding is required for all model branches. For nominal/ordinal
# factors, map levels explicitly and preserve the codebook in the audit table.
non_numeric <- names(df)[!vapply(df, is.numeric, FUN.VALUE = logical(1))]
if (length(non_numeric)) {
  stop("Explicitly encode these non-numeric nodes before modeling: ",
       paste(non_numeric, collapse = ", "))
}

# ---- Node audit ----
safe_skew <- function(x) if (sum(is.finite(x)) >= 3L && stats::sd(x, na.rm = TRUE) > 0)
  moments::skewness(x, na.rm = TRUE) else NA_real_
safe_kurt <- function(x) if (sum(is.finite(x)) >= 4L && stats::sd(x, na.rm = TRUE) > 0)
  moments::kurtosis(x, na.rm = TRUE) else NA_real_

audit <- purrr::map_dfr(seq_along(df), function(i) {
  x <- df[[i]]
  vals <- sort(unique(x[!is.na(x)]))
  m <- cfg$measurement[[i]]
  tibble::tibble(
    variable = names(df)[i],
    short_label = cfg$short_labels[i],
    full_english_label = cfg$full_labels[i],
    community = if (length(cfg$communities)) cfg$communities[i] else NA_character_,
    storage_class = class(x)[1],
    measurement = m,
    n_valid = sum(!is.na(x)),
    n_missing = sum(is.na(x)),
    missing_pct = mean(is.na(x)) * 100,
    n_unique = length(vals),
    observed_values = paste(vals, collapse = "|"),
    mean = if (m %in% c("continuous", "ordinal", "binary", "count")) mean(x, na.rm = TRUE) else NA_real_,
    sd = if (m %in% c("continuous", "ordinal", "binary", "count")) stats::sd(x, na.rm = TRUE) else NA_real_,
    skewness = if (m %in% c("continuous", "ordinal", "binary", "count")) safe_skew(x) else NA_real_,
    kurtosis = if (m %in% c("continuous", "ordinal", "binary", "count")) safe_kurt(x) else NA_real_,
    prevalence = if (m == "binary" && length(vals) == 2L) mean(x == max(vals), na.rm = TRUE) else NA_real_,
    low_informativeness = is.na(stats::sd(x, na.rm = TRUE)) || stats::sd(x, na.rm = TRUE) < .10
  )
})

# Validate declared measurement levels.
for (i in seq_along(df)) {
  k <- length(unique(df[[i]][!is.na(df[[i]])]))
  if (cfg$measurement[i] == "binary" && k != 2L)
    stop(cfg$node_names[i], " is declared binary but has ", k, " observed levels.")
  if (cfg$measurement[i] %in% c("ordinal", "nominal") && k < 2L)
    stop(cfg$node_names[i], " has fewer than two observed levels.")
}

write.csv(audit, out("node_audit.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(data_flow_log, out("data_flow_log.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Redundancy screening. Inspect flagged pairs substantively; do not auto-delete.
redundancy <- tryCatch(
  networktools::goldbricker(df, threshold = .25, p = .05),
  error = function(e) list(error = conditionMessage(e))
)
capture.output(redundancy, file = out("redundancy_screen.txt"))

# ---- Confounder-control gate ----
# Covariates are adjustment variables only. They must never be included in
# symptom centrality, bridge centrality, or intervention rankings. The generic
# template deliberately fails closed until the skill replaces this gate with a
# study-specific, resampling-aware estimator.
if (length(cfg$covariate_names)) {
  if (cfg$covariate_strategy == "auto") {
    cfg$covariate_strategy <- if (all(cfg$measurement == "continuous"))
      "residualize" else "joint"
  }
  if (cfg$covariate_strategy == "residualize" &&
      !all(cfg$measurement == "continuous")) {
    stop("Ordinary residualization is allowed only for continuous symptom nodes. Use a joint conditional model or a specialized adjusted estimator.")
  }
  writeLines(
    c(
      paste0("strategy: ", cfg$covariate_strategy),
      paste0("covariates: ", paste(cfg$covariate_names, collapse = ", ")),
      "scope: confounder control only; exclude covariates from all symptom rankings",
      "required: repeat the complete adjustment inside every bootstrap resample"
    ),
    out("covariate_decision.txt")
  )
  stop(
    "Replace the confounder-control gate with a validated study-specific estimator. ",
    "Residualization must be refitted within every bootstrap resample; a joint ",
    "model must re-estimate all variables and extract the symptom subnetwork in ",
    "every resample. Do not continue with fixed residuals."
  )
}

# ---- Model selection ----
types <- unique(cfg$measurement)
if (all(types %in% "continuous")) {
  model_family <- "ggm-continuous"
} else if (all(types %in% "ordinal")) {
  model_family <- "ggm-ordinal"
} else if (all(types %in% "binary")) {
  model_family <- "ising"
} else {
  model_family <- "mgm"
}

model_rationale <- switch(
  model_family,
  `ggm-continuous` = "All nodes were continuous; an EBICglasso GGM with Pearson correlations was used.",
  `ggm-ordinal` = "All nodes were ordinal; an EBICglasso GGM based on polychoric correlations (cor_auto) was used.",
  ising = "All nodes were dichotomous; an Ising model was used.",
  mgm = "The network contained mixed node types; a mixed graphical model was used."
)
writeLines(c(paste0("model_family: ", model_family), model_rationale,
             paste0("EBIC gamma: ", cfg$gamma)), out("model_decision.txt"))

complete_n <- sum(stats::complete.cases(df))
data_flow_log <- dplyr::bind_rows(
  data_flow_log,
  tibble::tibble(step = "Complete cases (diagnostic only)", n_rows = complete_n,
                 detail = "Primary missing-data handling is estimator-specific; report it explicitly.")
)
write.csv(data_flow_log, out("data_flow_log.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# bootnet handles correlation-based missingness according to corArgs/use. MGM and
# Ising branches generally require complete data here; replace with a justified
# imputation workflow if listwise deletion is not acceptable.
if (model_family %in% c("ising", "mgm")) {
  model_df <- stats::na.omit(df)
} else {
  model_df <- df
}

mgm_type <- ifelse(cfg$measurement == "continuous", "g",
                   ifelse(cfg$measurement == "count", "p", "c"))
mgm_level <- vapply(seq_along(df), function(i) {
  if (mgm_type[i] == "c") length(unique(model_df[[i]][!is.na(model_df[[i]])])) else 1L
}, integer(1))

network <- switch(
  model_family,
  `ggm-continuous` = bootnet::estimateNetwork(
    model_df, default = "EBICglasso", corMethod = "cor",
    corArgs = list(method = "pearson", use = "pairwise.complete.obs"),
    tuning = cfg$gamma, missing = "pairwise"
  ),
  `ggm-ordinal` = bootnet::estimateNetwork(
    model_df, default = "EBICglasso", corMethod = "cor_auto",
    tuning = cfg$gamma, missing = "pairwise"
  ),
  ising = bootnet::estimateNetwork(
    model_df, default = "IsingFit"
  ),
  mgm = bootnet::estimateNetwork(
    model_df, default = "mgm", type = mgm_type, level = mgm_level
  )
)

adj <- network$graph
dimnames(adj) <- list(cfg$short_labels, cfg$short_labels)
write.csv(adj, out("weighted_adjacency_matrix.csv"), fileEncoding = "UTF-8")

edges <- which(upper.tri(adj) & adj != 0, arr.ind = TRUE)
edge_table <- if (nrow(edges)) {
  tibble::tibble(
    node1 = rownames(adj)[edges[, 1]],
    node2 = colnames(adj)[edges[, 2]],
    weight = adj[edges],
    abs_weight = abs(weight),
    sign = ifelse(weight > 0, "positive", "negative")
  ) |> dplyr::arrange(dplyr::desc(abs_weight))
} else tibble::tibble(node1 = character(), node2 = character(), weight = numeric(),
                      abs_weight = numeric(), sign = character())
write.csv(edge_table, out("edges.csv"), row.names = FALSE, fileEncoding = "UTF-8")

network_summary <- tibble::tibble(
  n_nodes = ncol(df),
  n_possible_edges = ncol(df) * (ncol(df) - 1) / 2,
  n_nonzero_edges = nrow(edge_table),
  density = nrow(edge_table) / (ncol(df) * (ncol(df) - 1) / 2),
  positive_pct = if (nrow(edge_table)) mean(edge_table$weight > 0) * 100 else NA_real_,
  negative_pct = if (nrow(edge_table)) mean(edge_table$weight < 0) * 100 else NA_real_,
  mean_abs_edge = if (nrow(edge_table)) mean(edge_table$abs_weight) else NA_real_
)
write.csv(network_summary, out("network_summary.csv"), row.names = FALSE)

# ---- Node predictability ----
# Use MGM nodewise prediction so each node receives the metric appropriate to its family.
pred_data <- as.matrix(stats::na.omit(df))
pred_fit <- mgm::mgm(
  data = pred_data, type = mgm_type, level = mgm_level,
  lambdaSel = "EBIC", lambdaGam = .25, k = 2, ruleReg = "AND"
)
pred <- predict(pred_fit, pred_data)
predictability <- rep(NA_real_, ncol(df))
metric <- rep(NA_character_, ncol(df))
for (i in seq_along(predictability)) {
  if (mgm_type[i] %in% c("g", "p") && !is.null(pred$error$R2)) {
    predictability[i] <- pred$error$R2[i]
    metric[i] <- "R2"
  } else if (mgm_type[i] == "c" && !is.null(pred$error$nCC)) {
    predictability[i] <- pred$error$nCC[i]
    metric[i] <- "normalized classification accuracy"
  } else {
    metric[i] <- "model-specific prediction error; inspect mgm output"
  }
}
predictability[!is.finite(predictability)] <- 0
predictability <- pmin(1, pmax(0, predictability))

descriptives_predictability <- dplyr::mutate(
  audit, predictability = predictability, predictability_metric = metric
)
write.csv(descriptives_predictability, out("node_descriptives_predictability.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ---- Network figure ----
if (length(cfg$communities)) {
  groups <- split(seq_along(cfg$communities), cfg$communities)
} else groups <- NULL
palette <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9")
group_colors <- if (length(groups)) {
  stats::setNames(rep(palette, length.out = length(groups)), names(groups))
} else NULL

# Keep full item wording out of the main figure. qgraph uses nodeNames to create a
# node-by-node legend, which can cover the network when item wording is long.
node_codebook <- tibble::tibble(
  variable = cfg$node_names,
  short_label = cfg$short_labels,
  full_english_label = cfg$full_labels,
  community = if (length(cfg$communities)) cfg$communities else NA_character_
)
write.csv(node_codebook, out("node_codebook.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")

draw_network <- function(layout_value) {
  if (length(groups)) {
    graphics::layout(matrix(c(1, 2), nrow = 1), widths = c(4.5, 1))
  } else {
    graphics::layout(matrix(1, nrow = 1))
  }

  graph_object <- plot(
    network,
    labels = cfg$short_labels,
    nodeNames = NULL,
    groups = groups,
    color = if (length(groups)) unname(group_colors) else palette,
    pie = predictability,
    layout = layout_value,
    legend = FALSE,
    theme = "colorblind"
  )

  # Show community names only, in a separate panel that cannot cover nodes or edges.
  if (length(groups)) {
    graphics::par(mar = c(0, 0, 0, 0))
    graphics::plot.new()
    graphics::legend(
      "center", legend = names(group_colors), pch = 21,
      pt.bg = unname(group_colors), pt.cex = 1.8, cex = 0.9,
      bty = "n", xpd = NA
    )
  }

  graph_object
}

pdf(out("network.pdf"), width = 11, height = 8, useDingbats = FALSE)
graph <- draw_network("spring")
dev.off()
png(out("network.png"), width = 3300, height = 2400, res = 300)
invisible(draw_network(graph$layout))
dev.off()

# ---- Centrality ----
centrality <- qgraph::centrality_auto(adj)$node.centrality
centrality_table <- tibble::rownames_to_column(as.data.frame(centrality), "node")
write.csv(centrality_table, out("centrality.csv"), row.names = FALSE, fileEncoding = "UTF-8")
pdf(out("centrality.pdf"), width = 9, height = 7, useDingbats = FALSE)
qgraph::centralityPlot(graph, include = c("Strength", "ExpectedInfluence",
                                         "Closeness", "Betweenness"),
                      scale = "z-scores")
dev.off()

# ---- Accuracy and stability ----
boot_accuracy <- bootnet::bootnet(
  network, nBoots = cfg$n_boots, nCores = cfg$n_cores,
  type = "nonparametric",
  statistics = c("edge", "strength", "expectedInfluence")
)
boot_case <- bootnet::bootnet(
  network, nBoots = cfg$n_boots, nCores = cfg$n_cores,
  type = "case",
  statistics = c("strength", "expectedInfluence", "closeness", "betweenness")
)
saveRDS(boot_accuracy, out("bootstrap_accuracy.rds"))
saveRDS(boot_case, out("bootstrap_case.rds"))
capture.output(bootnet::corStability(boot_case), file = out("centrality_cs_coefficients.txt"))

pdf(out("edge_accuracy.pdf"), width = 10, height = 8, useDingbats = FALSE)
plot(boot_accuracy, labels = FALSE, order = "sample")
dev.off()
pdf(out("centrality_stability.pdf"), width = 10, height = 8, useDingbats = FALSE)
plot(boot_case, statistics = c("strength", "expectedInfluence", "closeness", "betweenness"))
dev.off()
pdf(out("edge_difference_test.pdf"), width = 11, height = 9, useDingbats = FALSE)
plot(boot_accuracy, "edge", plot = "difference", onlyNonZero = TRUE, order = "sample")
dev.off()
pdf(out("centrality_difference_test.pdf"), width = 11, height = 9, useDingbats = FALSE)
plot(boot_accuracy, "expectedInfluence", plot = "difference")
dev.off()

# ---- Bridge analysis ----
if (length(unique(cfg$communities)) >= 2L) {
  bridge_result <- networktools::bridge(adj, communities = cfg$communities)
  bridge_fields <- c("Bridge Strength", "Bridge Expected Influence (1-step)",
                     "Bridge Closeness", "Bridge Betweenness")
  bridge_table <- purrr::map_dfr(bridge_fields, function(field) {
    value <- bridge_result[[field]]
    if (is.null(value)) return(NULL)
    tibble::tibble(node = names(value), statistic = field, value = as.numeric(value))
  })
  write.csv(bridge_table, out("bridge_centrality.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  pdf(out("bridge_centrality.pdf"), width = 10, height = 8, useDingbats = FALSE)
  plot(bridge_result, order = "value", zscore = TRUE,
       include = bridge_fields, color = TRUE)
  dev.off()

  bridge_boot <- tryCatch(
    bootnet::bootnet(
      network, nBoots = cfg$n_boots, nCores = cfg$n_cores,
      type = "case", communities = cfg$communities,
      statistics = c("bridgeStrength", "bridgeExpectedInfluence",
                     "bridgeCloseness", "bridgeBetweenness")
    ),
    error = function(e) e
  )
  if (inherits(bridge_boot, "error")) {
    writeLines(paste("Bridge stability unavailable:", conditionMessage(bridge_boot)),
               out("bridge_stability_WARNING.txt"))
  } else {
    saveRDS(bridge_boot, out("bootstrap_bridge_case.rds"))
    capture.output(bootnet::corStability(bridge_boot), file = out("bridge_cs_coefficients.txt"))
    pdf(out("bridge_stability.pdf"), width = 10, height = 8, useDingbats = FALSE)
    plot(bridge_boot, statistics = c("bridgeStrength", "bridgeExpectedInfluence",
                                    "bridgeCloseness", "bridgeBetweenness"))
    dev.off()
  }
}

# ---- Reproducibility ----
capture.output(sessionInfo(), file = out("sessionInfo.txt"))
saveRDS(list(config = cfg, network = network, layout = graph$layout,
             predictability = predictability), out("analysis_objects.rds"))
message("Analysis complete. Verify all warnings and output tables before writing Results: ",
        normalizePath(cfg$output_dir, winslash = "/", mustWork = FALSE))
