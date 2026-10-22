# CLPN example for continuous nodes in wide data; rows are participants.
# A single transition is shown. Repeat the same workflow for each adjacent pair.
library(readxl)
library(glmnet)
library(qgraph)

file <- "panel_data.xlsx"
id_var <- "ID"
wave1 <- c("Dep_T1", "Anx_T1", "Sleep_T1")
wave2 <- c("Dep_T2", "Anx_T2", "Sleep_T2")
seed <- 20261022L
lambda_rule <- "lambda.min" # prespecify lambda.min or lambda.1se
run_bootstrap <- TRUE
n_boots <- 1000L
n_cores <- 4L

stopifnot(length(wave1) == length(wave2), length(wave1) >= 2L)
dat <- as.data.frame(read_excel(file))
stopifnot(all(c(id_var, wave1, wave2) %in% names(dat)))
if (anyDuplicated(dat[[id_var]])) stop("Expected one wide-format row per participant.")
if (!all(vapply(dat[c(wave1, wave2)], is.numeric, logical(1))))
  stop("This template is for continuous nodes; use a justified outcome/link family otherwise.")
keep <- complete.cases(dat[c(wave1, wave2)])
flow <- data.frame(n_initial = nrow(dat), n_retained = sum(keep), n_excluded = sum(!keep))
write.csv(flow, "panel_flow.csv", row.names = FALSE)
dat <- dat[keep, , drop = FALSE]
if (nrow(dat) < 20L) warning("Small complete-case n; estimates and bootstrap results may be unstable.")
labels <- sub("_T[12]$", "", wave1)

# Each outcome is regressed on all previous-wave nodes, including its AR path.
# The matrix orientation is predictor rows -> later-wave outcome columns.
fit_clpn <- function(d) {
  X <- as.matrix(d[wave1]); Y <- as.matrix(d[wave2])
  storage.mode(X) <- storage.mode(Y) <- "double"
  p <- length(wave1)
  W <- matrix(0, p, p, dimnames = list(labels, labels))
  lambdas <- numeric(p)
  for (j in seq_len(p)) {
    cv <- cv.glmnet(X, Y[, j], family = "gaussian", alpha = 1,
                    standardize = TRUE, nfolds = min(10L, nrow(X)))
    lambdas[j] <- if (lambda_rule == "lambda.1se") cv$lambda.1se else cv$lambda.min
    b <- as.matrix(coef(cv, s = lambdas[j]))[-1, 1]
    W[, j] <- b
  }
  list(W = W, lambda = lambdas)
}
set.seed(seed)
main <- fit_clpn(dat)
W <- main$W
write.csv(W, "clpn_temporal_edges.csv", row.names = TRUE)
write.csv(data.frame(outcome = labels, lambda = main$lambda, lambda_rule = lambda_rule),
          "clpn_model_settings.csv", row.names = FALSE)

offdiag <- W
diag(offdiag) <- 0
influence <- data.frame(
  node = labels,
  out_strength = rowSums(abs(offdiag)),
  in_strength = colSums(abs(offdiag)),
  out_expected_influence = rowSums(offdiag),
  in_expected_influence = colSums(offdiag)
)
write.csv(influence, "clpn_in_out_influence.csv", row.names = FALSE)
crosslag <- data.frame(
  predictor = rownames(W)[row(W)], outcome = colnames(W)[col(W)],
  estimate = as.vector(W), is_autoregressive = row(W) == col(W)
)
write.csv(crosslag, "clpn_all_paths.csv", row.names = FALSE)
write.csv(subset(crosslag, !is_autoregressive & estimate != 0),
          "clpn_nonzero_crosslag_edges.csv", row.names = FALSE)

pdf("clpn_temporal_network.pdf", width = 8, height = 7)
qgraph(W, directed = TRUE, layout = "spring", labels = labels,
       theme = "colorblind", edge.labels = TRUE, mar = c(4, 4, 4, 4))
dev.off()

# Required in-/out-influence panels; bootstrap intervals are added when enabled.
pdf("clpn_in_out_influence.pdf", width = 10, height = 8)
par(mfrow = c(2, 2), mar = c(8, 4, 3, 1))
for (metric in names(influence)[2:5]) {
  vals <- influence[[metric]]
  barplot(vals, names.arg = labels, las = 2, col = "steelblue",
          main = metric, ylab = "Cross-lagged influence")
  abline(h = 0, lty = 2)
}
dev.off()

# Expensive by design: use the saved code for formal edge accuracy and CS stability.
# bootnet resamples participants and re-fits the complete nodewise LASSO procedure.
if (run_bootstrap) {
  if (!requireNamespace("bootnet", quietly = TRUE)) stop("Install bootnet to run bootstrap checks.")
  boot_estimator <- function(data) fit_clpn(as.data.frame(data))$W
  net <- bootnet::estimateNetwork(
    dat[c(wave1, wave2)], fun = boot_estimator, labels = labels, directed = TRUE
  )
  boot_edges <- bootnet::bootnet(net, type = "nonparametric", nBoots = n_boots,
                                 nCores = n_cores, directed = TRUE,
                                 statistics = "edge")
  boot_case <- bootnet::bootnet(
    net, type = "case", nBoots = n_boots, nCores = n_cores, directed = TRUE,
    statistics = c("outStrength", "inStrength", "outExpectedInfluence", "inExpectedInfluence")
  )
  saveRDS(list(edge = boot_edges, case = boot_case), "clpn_bootstrap.rds")
  if (!is.null(boot_edges$bootTable))
    write.csv(boot_edges$bootTable, "clpn_edge_bootstrap_table.csv", row.names = FALSE)
  if (!is.null(boot_case$bootTable))
    write.csv(boot_case$bootTable, "clpn_case_bootstrap_table.csv", row.names = FALSE)
  capture.output(bootnet::corStability(boot_case), file = "clpn_cs_coefficients.txt")
  pdf("clpn_bootstrap_edge_accuracy.pdf", width = 10, height = 8)
  plot(boot_edges, statistics = "edge", order = "sample", labels = FALSE)
  dev.off()
  pdf("clpn_bootstrap_influence_stability.pdf", width = 10, height = 8)
  plot(boot_case, statistics = c("outStrength", "inStrength",
                                 "outExpectedInfluence", "inExpectedInfluence"))
  dev.off()
}
sessionInfo()
