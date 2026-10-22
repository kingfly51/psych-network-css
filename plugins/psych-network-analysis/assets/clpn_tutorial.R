# Minimal wide-format CLPN tutorial: regularized nodewise regressions.
# Rows = participants; the same nodes are measured at each wave.
# Requires readxl, glmnet, qgraph. This example assumes continuous nodes.
library(readxl)
library(glmnet)
library(qgraph)

# ---- Edit configuration ----
file <- "panel_data.xlsx"
id_var <- "ID"
wave1 <- c("Dep_T1", "Anx_T1", "Sleep_T1")
wave2 <- c("Dep_T2", "Anx_T2", "Sleep_T2")
covariates <- character(0) # optionally pre-specify, e.g., c("Age", "Sex")
measurement <- "continuous" # this example is Gaussian only
seed <- 20261022L
# ----------------------------

stopifnot(length(wave1) == length(wave2), length(wave1) >= 2L)
if (measurement != "continuous") stop("Use a model matched to the actual node type; this tutorial is Gaussian only.")
dat <- as.data.frame(read_excel(file))
stopifnot(all(c(id_var, wave1, wave2, covariates) %in% names(dat)))
if (anyDuplicated(dat[[id_var]])) stop("Expected one wide-format row per participant.")
if (!all(vapply(dat[c(wave1, wave2)], is.numeric, logical(1))))
  stop("This example is Gaussian only; select a suitable model for categorical nodes.")

# Complete-case handling is for illustration; choose/report a justified method.
keep <- complete.cases(dat[c(wave1, wave2, covariates)])
excluded_n <- sum(!keep)
dat <- dat[keep, , drop = FALSE]
message("Retained n=", nrow(dat), "; excluded for missingness n=", excluded_n)
X <- as.matrix(dat[wave1]); Y <- as.matrix(dat[wave2])
storage.mode(X) <- storage.mode(Y) <- "double"
if (length(covariates)) {
  C <- model.matrix(reformulate(covariates), data = dat)[, -1, drop = FALSE]
  X <- cbind(X, C)
}

# Rows = earlier-wave predictors; columns = later-wave outcomes.
set.seed(seed)
p <- length(wave1)
W <- matrix(0, p, p,
            dimnames = list(sub("_T1$", "", wave1), sub("_T2$", "", wave2)))
lambda <- numeric(p)
for (j in seq_len(p)) {
  cv <- cv.glmnet(X, Y[, j], family = "gaussian", alpha = 1,
                  standardize = TRUE, nfolds = min(10L, nrow(X)))
  lambda[j] <- cv$lambda.min
  b <- as.matrix(coef(cv, s = "lambda.min"))[-1, 1]
  W[, j] <- b[seq_len(p)]
}
write.csv(W, "clpn_temporal_edges.csv", row.names = TRUE)
write.csv(data.frame(outcome = colnames(W), lambda_min = lambda),
          "clpn_model_settings.csv", row.names = FALSE)
qgraph(W, directed = TRUE, layout = "circle", labels = rownames(W),
       theme = "colorblind", edge.labels = TRUE,
       filename = "clpn_temporal_network.pdf")
sessionInfo()
