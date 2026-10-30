# KimNIRA workflow following the user-provided kimNIRA_wf.docx.
# This script analyzes user data; it does not create or alter observations.
library(readxl)
library(KimNIRA)
library(ggplot2)

# ---- Edit to match the data dictionary and prespecified analysis ----
file <- "ema_long.xlsx"
id <- "ID"
day <- "Day"                 # ordered numeric day or sortable date
beep <- "Beep"               # within-day occasion, e.g., 1/2
vars <- c("Depressed", "Anxious", "Lonely", "Stress")
output_dir <- "kimnira_output"
allow_overnight <- FALSE     # match the planned transition definition
between_person <- "re"      # reference default; consider "res" only if justified
screen <- "fdr"
fdr_q <- 0.10                # BH screening, then unpenalized refit
exact_max_nodes <- 12L       # practical guard; assess memory/time before increasing
primary_method <- "exact"   # choose "mc" only if exact state enumeration is infeasible
run_equal_probability <- TRUE
run_lag2_check <- FALSE      # requires eligible three-consecutive-occasion sequences
run_landscape <- TRUE        # exponential state enumeration; skipped above guard
run_bootstrap <- TRUE
n_boot <- 100L               # matches the supplied worked example; raise for tail precision
target_dp <- 0.10             # sensitivity: equal stationary activation-probability reduction
intervention_sd <- 2          # primary common logit dose in the supplied example
seed <- 20261022L
# -------------------------------------------------------------------

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Save ggplot and qgraph result figures as PNG + PDF.
save_gg <- function(p, base, width = 9, height = 6) {
  ggsave(paste0(base, ".png"), p, width = width, height = height, dpi = 300)
  ggsave(paste0(base, ".pdf"), p, width = width, height = height)
}
save_qgraph <- function(draw, base, width = 8, height = 7) {
  pdf(paste0(base, ".pdf"), width = width, height = height); draw(); dev.off()
  png(paste0(base, ".png"), width = width, height = height, units = "in", res = 300)
  draw(); dev.off()
}

dat <- as.data.frame(read_excel(file))
stopifnot(all(c(id, day, beep, vars) %in% names(dat)))
if (anyNA(dat[[id]]) || anyNA(dat[[day]]) || anyNA(dat[[beep]]))
  stop("Participant ID and time-order columns must not be missing.")
if (anyDuplicated(dat[c(id, day, beep)]))
  stop("Duplicate participant-by-day-by-beep records must be resolved before fitting.")
if (!all(vapply(dat[vars], function(x) all(na.omit(unique(x)) %in% c(0, 1)), logical(1))))
  stop("KimNIRA requires binary 0/1 states. Apply only a prespecified, justified coding rule.")
dat <- dat[order(dat[[id]], dat[[day]], dat[[beep]]), , drop = FALSE]

node_audit <- data.frame(
  node = vars,
  n_valid = vapply(dat[vars], function(x) sum(!is.na(x)), integer(1)),
  n_missing = vapply(dat[vars], function(x) sum(is.na(x)), integer(1)),
  prevalence_1 = vapply(dat[vars], function(x) mean(x == 1, na.rm = TRUE), numeric(1)),
  n_zero = vapply(dat[vars], function(x) sum(x == 0, na.rm = TRUE), integer(1)),
  n_one = vapply(dat[vars], function(x) sum(x == 1, na.rm = TRUE), integer(1))
)
write.csv(node_audit, file.path(output_dir, "node_audit.csv"), row.names = FALSE)

sample_flow <- data.frame(
  n_records = nrow(dat),
  n_participants = length(unique(dat[[id]])),
  n_complete_node_rows = sum(complete.cases(dat[vars])),
  n_nodes = length(vars),
  overnight_transitions_allowed = allow_overnight,
  stringsAsFactors = FALSE
)
write.csv(sample_flow, file.path(output_dir, "sample_flow.csv"), row.names = FALSE)

fit <- fitKIM(
  data = dat, vars = vars, id = id, dayvar = day, beepvar = beep,
  allow_overnight = allow_overnight,
  between_person = between_person,
  screen = screen, fdr_q = fdr_q,
  estimate_between = TRUE, seed = seed, verbose = TRUE
)
saveRDS(fit, file.path(output_dir, "kim_fit.rds"))
write.csv(fit$pair_summary, file.path(output_dir, "transition_audit.csv"), row.names = FALSE)
temporal_edges <- as.data.frame(as.table(fit$J))
names(temporal_edges) <- c("target_node", "source_node", "J_weight")
write.csv(temporal_edges, file.path(output_dir, "temporal_J_edges.csv"), row.names = FALSE)
write.csv(as.data.frame(as.table(fit$stage1_beta)),
          file.path(output_dir, "stage1_unpenalized_coefficients.csv"), row.names = FALSE)
write.csv(as.data.frame(as.table(fit$stage1_se)),
          file.path(output_dir, "stage1_standard_errors.csv"), row.names = FALSE)
write.csv(as.data.frame(as.table(fit$support)),
          file.path(output_dir, "selected_edge_support.csv"), row.names = FALSE)
write.csv(data.frame(node = names(fit$h), h = unname(fit$h)),
          file.path(output_dir, "thresholds_h.csv"), row.names = FALSE)
write.csv(as.data.frame(as.table(fit$between_network)),
          file.path(output_dir, "between_person_edges.csv"), row.names = FALSE)

centrality <- kimCentrality(fit, plot = TRUE, use_ggplot = TRUE, verbose = FALSE)
write.csv(centrality$temporal, file.path(output_dir, "temporal_centrality.csv"), row.names = FALSE)
write.csv(centrality$between, file.path(output_dir, "between_person_centrality.csv"), row.names = FALSE)
if (length(centrality$plots)) {
  for (nm in names(centrality$plots)) {
    p <- centrality$plots[[nm]]
    if (inherits(p, "ggplot"))
      save_gg(p, file.path(output_dir, paste0("centrality_", nm)), width = 8, height = 5)
  }
}

# Temporal and between-person network figures (qgraph objects)
for (tp in c("temporal", "between")) {
  save_qgraph(function() kimPlotNetwork(fit, type = tp),
              file.path(output_dir, paste0("kimPlotNetwork_", tp)))
}

mixing <- kimMixing(fit, persons = "typical")
write.csv(mixing, file.path(output_dir, "mixing_diagnostic.csv"), row.names = FALSE)
write.csv(data.frame(
  diagnostic = c("spectral_radius", "spectral_radius_J", "weighted_Jacobian_radius", "heuristic_relaxation"),
  value = c(fit$spectral_radius, fit$spectral_radius_J,
            fit$spectral_radius_star, fit$mixing_time)
), file.path(output_dir, "KIM_stability_summary.csv"), row.names = FALSE)
capture.output(str(fit$settings), file = file.path(output_dir, "model_settings.txt"))

# This checks within-occasion conditional dependence; it is not a moderation test.
contemporaneous <- tryCatch(
  kimContemporaneousCheck(kim_fit = fit, data = dat, p_adjust = "holm"),
  error = function(e) structure(list(error = conditionMessage(e)), class = "diagnostic_error")
)
saveRDS(contemporaneous, file.path(output_dir, "contemporaneous_check.rds"))
capture.output(print(contemporaneous), file = file.path(output_dir, "contemporaneous_check.txt"))

# The lag-2 diagnostic is only meaningful when the sampling design has eligible triplets.
if (run_lag2_check) {
  lag2 <- tryCatch(
    kimMarkovCheck(fit, dat, n_boot = 1000L, seed = seed, verbose = TRUE),
    error = function(e) structure(list(error = conditionMessage(e)), class = "diagnostic_error")
  )
  saveRDS(lag2, file.path(output_dir, "lag2_predictive_check.rds"))
  capture.output(print(lag2), file = file.path(output_dir, "lag2_predictive_check.txt"))
} else {
  writeLines("Not run: set run_lag2_check=TRUE only when the design contains enough eligible three-consecutive-occasion sequences.",
             file.path(output_dir, "lag2_predictive_check_not_run.txt"))
}

# The stability landscape is computed after the NIRA result, so it can include
# the baseline plus every intervening condition (kimBistability(primary)).
if (length(vars) > exact_max_nodes && primary_method == "exact")
  stop("Node count exceeds exact_max_nodes. Review computational feasibility, then explicitly select method='mc' if needed.")
primary <- runKIMNIRA(
  fit, method = primary_method, intervention_type = "alleviating",
  dose_scale = "logit", intervention_sd = intervention_sd,
  n_sim = 5000L, n_steps = 30L, seed = seed, paired = TRUE,
  trajectory = TRUE, diagnose = TRUE, verbose = TRUE
)
saveRDS(primary, file.path(output_dir, "nira_alleviating_logit.rds"))
write.csv(primary$summary, file.path(output_dir, "nira_alleviating_logit_results.csv"), row.names = FALSE)
if (!is.null(primary$exact_conditions))
  write.csv(primary$exact_conditions, file.path(output_dir, "nira_alleviating_logit_conditions.csv"), row.names = FALSE)
save_gg(suppressWarnings(kimPlotNIRA(primary, perturbation_type = "alleviating",
                                     node_labels = setNames(vars, vars))),
        file.path(output_dir, "kimPlotNIRA_alleviating_logit"))
save_gg(kimPlotTrajectory(primary, type = "summary", node_labels = setNames(vars, vars)),
        file.path(output_dir, "trajectory_summary"))
top_target <- primary$ranked_targets[1]
save_gg(kimPlotTrajectory(primary, type = "node", target = top_target,
                          node_labels = setNames(vars, vars)),
        file.path(output_dir, paste0("trajectory_top_target_", top_target)))

# Stability / potential landscape: baseline plus every alleviating target.
# U(K) = -log P(K); the valley is the system's most likely stable configuration.
if (run_landscape && length(vars) <= exact_max_nodes) {
  landscape <- tryCatch(kimBistability(primary, verbose = FALSE),
                        error = function(e) structure(list(error = conditionMessage(e)),
                                                      class = "diagnostic_error"))
  saveRDS(landscape, file.path(output_dir, "stationary_landscape.rds"))
  if (!is.null(landscape$count_distribution)) {
    write.csv(landscape$count_distribution,
              file.path(output_dir, "stationary_activation_landscape.csv"), row.names = FALSE)
    land_conditions <- c("baseline", vars)
    p_land <- tryCatch(kimPlotLandscape(
      landscape, conditions = land_conditions, per_state = FALSE, type = "potential"),
      error = function(e) NULL)
    if (!is.null(p_land))
      save_gg(p_land, file.path(output_dir, "kimPlotLandscape_potential"), width = 10, height = 6)
    p_land_prob <- tryCatch(kimPlotLandscape(
      landscape, conditions = land_conditions, per_state = FALSE, type = "probability"),
      error = function(e) NULL)
    if (!is.null(p_land_prob))
      save_gg(p_land_prob, file.path(output_dir, "kimPlotLandscape_probability"), width = 10, height = 6)
  }
  if (!is.null(landscape$modes))
    write.csv(landscape$modes, file.path(output_dir, "stationary_modes.csv"), row.names = FALSE)
} else {
  writeLines("Not run: landscape enumeration disabled or node count exceeds the configured computational guard.",
             file.path(output_dir, "stationary_landscape_not_run.txt"))
}

# Equal-probability dose is a separate, prespecified sensitivity analysis.
if (run_equal_probability) {
  equal_prob <- runKIMNIRA(
    fit, method = primary_method, intervention_type = "alleviating",
    dose_scale = "probability", target_dp = target_dp,
    calibrate_on = "stationary", n_sim = 5000L, n_steps = 30L,
    seed = seed, paired = TRUE, trajectory = TRUE, diagnose = TRUE, verbose = TRUE
  )
  saveRDS(equal_prob, file.path(output_dir, "nira_alleviating_equal_probability.rds"))
  write.csv(equal_prob$summary, file.path(output_dir, "nira_alleviating_equal_probability_results.csv"), row.names = FALSE)
  if (!is.null(equal_prob$delta_prob_table))
    write.csv(equal_prob$delta_prob_table, file.path(output_dir, "equal_probability_dose_calibration.csv"), row.names = FALSE)
  save_gg(suppressWarnings(kimPlotNIRA(equal_prob, perturbation_type = "alleviating",
                                       node_labels = setNames(vars, vars))),
          file.path(output_dir, "kimPlotNIRA_alleviating_equal_probability"))
}

# Participant-level resampling quantifies sampling uncertainty and rank stability;
# this is distinct from Monte Carlo precision diagnostics.
if (run_bootstrap) {
  stability <- kimStabilityBootstrap(primary, data = dat, n_boot = n_boot,
                                     seed = seed, parallel = FALSE, progress = TRUE)
  saveRDS(stability, file.path(output_dir, "participant_bootstrap.rds"))
  write.csv(stability$stat, file.path(output_dir, "participant_bootstrap_node_results.csv"), row.names = FALSE)
  write.csv(stability$pairwise, file.path(output_dir, "participant_bootstrap_target_contrasts.csv"), row.names = FALSE)
}

writeLines(capture.output(sessionInfo()), file.path(output_dir, "session_info.txt"))
print(primary$ranked_targets)
print(primary$summary)
