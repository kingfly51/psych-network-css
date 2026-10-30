# =============================================================
# Cross-lagged panel network (CLPN) template
# Ported faithfully from the user's clpn_code.R (lines 1-424).
# Only environment fixes: configurable paths, no hard-coded Dropbox
# or personal `source()` paths, and an optional parallel switch.
# =============================================================
suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(qgraph)
  library(bootnet); library(glmnet); library(lavaan); library(networktools)
})

# ----------------------- CONFIGURATION -----------------------
data_file    <- "data.xlsx"                 # wide format, one row per participant
covariate_idx <- 1:3                        # covariate columns (gender, age, love_state)
wave1_cols   <- 4:23                        # T1 node columns
wave2_cols   <- 24:43                       # T2 node columns

k        <- 20L
k1       <- 5L                              # BFI nodes; rest = SA / IAS nodes
groups   <- c(rep("BFI", k1), rep("SA", k - k1))
labels   <- c("extraversion", "agreeableness", "conscientiousness", "neuroticism", "openness",
              "IAS1", "IAS2", "IAS3", "IAS4", "IAS5", "IAS6", "IAS7", "IAS8", "IAS9", "IAS10",
              "IAS11", "IAS12", "IAS13", "IAS14", "IAS15")
node_colors <- c(rep("orange", k1), rep("light blue", k - k1))

tuning       <- 0.5                         # EBIC gamma
seed_plain   <- 100L                        # reference seed for the plain CLPN loop
seed_cov     <- 1L                          # reference seed for the covariate loop
lambda_rule  <- "lambda.min"                # or "lambda.1se"
nfolds       <- 10L
numCovar     <- length(covariate_idx)
use_parallel <- FALSE                       # TRUE needs a registered backend
run_bootstrap <- FALSE
n_boots      <- 1000L
n_cores      <- max(1L, parallel::detectCores() - 1L)
neg_dashed   <- FALSE                       # FALSE = solid negative edges (default)
run_multiwave <- TRUE                       # free vs equal-weight comparison when >=3 waves
wave_prefixes <- c("T1_", "T2_", "T3_", "T4_")

out_dir <- "clpn_output"
# --------------------- END CONFIGURATION ---------------------

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

save_pdf_png <- function(base, width, height, draw) {
  pdf(paste0(base, ".pdf"), width = width, height = height); draw(); dev.off()
  png(paste0(base, ".png"), width = width, height = height, units = "in", res = 300)
  draw(); dev.off()
}

#### 1. data ####
data <- readxl::read_excel(data_file)
swan7 <- as.data.frame(data)
if (length(covariate_idx) == 3L)
  colnames(swan7)[covariate_idx] <- c("age", "gender", "love_state")  # as in reference
swan.w8r <- swan7[, wave1_cols, drop = FALSE]
swan.w9r <- swan7[, wave2_cols, drop = FALSE]
write.csv(data.frame(n_initial = nrow(swan7)),
          file.path(out_dir, "panel_flow.csv"), row.names = FALSE)

#### 2. cross-sectional networks (Fig 1) ####
swan.network.t1 <- estimateNetwork(
  swan.w8r, corMethod = "cor", default = "EBICglasso", tuning = tuning,
  corArgs = list(method = "spearman", use = "pairwise.complete.obs"))
swan.network.t2 <- estimateNetwork(
  swan.w9r, corMethod = "cor", default = "EBICglasso", tuning = tuning,
  corArgs = list(method = "spearman", use = "pairwise.complete.obs"))

lay_t1 <- qgraph(swan.network.t1$graph, layout = "spring", DoNotPlot = TRUE)$layout
plot_cs <- function(net, lay) {
  plot(net, layout = lay, theme = "colorblind", labels = labels,
       vsize = 5, shape = "circle", color = node_colors,
       negDashed = neg_dashed, curveAll = FALSE)
}
save_pdf_png(file.path(out_dir, "fig1_crosssectional_w1"), 8, 7,
             function() plot_cs(swan.network.t1, lay_t1))
save_pdf_png(file.path(out_dir, "fig1_crosssectional_w2"), 8, 7,
             function() plot_cs(swan.network.t2, lay_t1))

export_cs <- function(g, file) {
  idx <- which(g != 0 & upper.tri(g), arr.ind = TRUE)
  e <- data.frame(from = rownames(g)[idx[, 1]], to = colnames(g)[idx[, 2]], weight = g[idx])
  write.csv(e[order(-abs(e$weight)), , drop = FALSE], file, row.names = FALSE)
}
export_cs(swan.network.t1$graph, file.path(out_dir, "edges_crosssectional_w1.csv"))
export_cs(swan.network.t2$graph, file.path(out_dir, "edges_crosssectional_w2.csv"))

#### 3. CLPN (Fig 2) ####
net.t1.t2.swan.df <- swan7[, wave1_cols, drop = FALSE]
net.t1.t2.swan.df <- cbind(net.t1.t2.swan.df, swan7[, wave2_cols, drop = FALSE])
coVar.swan <- swan7[, covariate_idx, drop = FALSE]
net.t1.t2.swan.df.cov <- as.data.frame(dplyr::bind_cols(net.t1.t2.swan.df, coVar.swan))

# plain nodewise LASSO (used for predictability/influence)
myData <- as.matrix(net.t1.t2.swan.df)
adjMat <- matrix(0, k, k)
for (i in 1:k) {
  set.seed(seed_plain)
  lassoreg <- cv.glmnet(as.matrix(myData[, 1:k]), myData[, (k + i)],
                        family = "gaussian", alpha = 1, standardize = TRUE)
  lambda <- lassoreg$lambda.min
  adjMat[1:k, i] <- coef(lassoreg, s = lambda, exact = FALSE)[2:(k + 1)]
}

# covariate-adjusted nodewise LASSO (used for the temporal network figure)
adjMatCov.t1.t2 <- matrix(0, numCovar + k, numCovar + k)
for (i in 1:k) {
  set.seed(seed_cov)
  lassoregCov.t1.t2 <- cv.glmnet(
    as.matrix(net.t1.t2.swan.df.cov[, c(1:k, (k * 2 + 1):(k * 2 + numCovar))]),
    net.t1.t2.swan.df.cov[, (k + i)], nfolds = nfolds,
    family = "gaussian", alpha = 1, standardize = TRUE, parallel = use_parallel)
  lambdaCov.t1.t2 <- lassoregCov.t1.t2$lambda.min
  adjMatCov.t1.t2[(1:(k + numCovar)), i] <-
    coef(lassoregCov.t1.t2, s = lambdaCov.t1.t2, exact = FALSE)[2:(numCovar + k + 1)]
}
adjMat.t1.t2 <- adjMatCov.t1.t2[1:k, 1:k]

LabwArrow.t1.t2 <- expression("W1" %->% "W2 Network")
lay_clpn <- qgraph(adjMat.t1.t2, layout = "spring", DoNotPlot = TRUE)$layout
save_pdf_png(file.path(out_dir, "fig2_clpn"), 8, 7, function() {
  qgraph(adjMat.t1.t2, groups = groups, labels = labels, legend = FALSE,
         posCol = "blue", negCol = "red", layout = lay_clpn, theme = "colorblind")
  title(LabwArrow.t1.t2, line = 3, cex.main = 1.75)
})

write.csv(adjMat.t1.t2, file.path(out_dir, "clpn_temporal_edges.csv"))
write.csv(adjMat, file.path(out_dir, "clpn_plain_edges.csv"))

#### 4. predictability (pred0/pred1/pred2) ####
pred0 <- pred1 <- pred2 <- rep(0, k)
myData2 <- net.t1.t2.swan.df
for (i in 1:k) {
  name.i <- names(myData2)[k + i]              # per-node DV (fixed from k+1)
  group.i <- groups[i]
  include.mod0 <- names(myData2)[1:k]
  include.mod1 <- names(myData2)[1:k][-i]
  include.mod2 <- names(myData2)[1:k][groups != group.i]
  betas.mod0 <- adjMat[1:k, i]
  betas.mod1 <- adjMat[1:k, i][-i]
  betas.mod2 <- adjMat[1:k, i][groups != group.i]
  mod0 <- paste(name.i, "~", paste(paste(betas.mod0, "*", include.mod0, sep = ""), collapse = "+"))
  mod1 <- paste(name.i, "~", paste(paste(betas.mod1, "*", include.mod1, sep = ""), collapse = "+"))
  mod2 <- paste(name.i, "~", paste(paste(betas.mod2, "*", include.mod2, sep = ""), collapse = "+"))
  pred0[i] <- inspect(sem(mod0, sample.cov = cor(myData2), sample.nobs = nrow(myData2)), "rsquare")
  pred1[i] <- inspect(sem(mod1, sample.cov = cor(myData2), sample.nobs = nrow(myData2)), "rsquare")
  pred2[i] <- inspect(sem(mod2, sample.cov = cor(myData2), sample.nobs = nrow(myData2)), "rsquare")
}

#### 5. influence (infl0/infl1/infl2) ####
myData <- as.matrix(myData2)
for (i in 1:k) {
  set.seed(seed_plain)
  lassoreg <- cv.glmnet(as.matrix(myData[, 1:k]), myData[, (k + i)],
                        family = "gaussian", alpha = 1, standardize = TRUE)
  lambda <- lassoreg$lambda.min
  adjMat[1:k, i] <- coef(lassoreg, s = lambda, exact = FALSE)[2:(k + 1)]
}
adjMat2 <- adjMat; diag(adjMat2) <- 0
adjMat3 <- adjMat2
adjMat3[groups[row(adjMat3)] == groups[col(adjMat3)]] <- 0
infl0 <- apply(adjMat^2, 1, sum)
infl1 <- apply(adjMat2^2, 1, sum)
infl2 <- apply(adjMat3^2, 1, sum)

write.csv(data.frame(node = labels, group = groups,
                     pred0 = pred0, pred1 = pred1, pred2 = pred2,
                     infl0 = infl0, infl1 = infl1, infl2 = infl2),
          file.path(out_dir, "clpn_pred_influence.csv"), row.names = FALSE)

#### 6. predictability and influence figures (Fig 3) ####
# total: all other nodes, excluding the autoregressive path (pred1/infl1)
# cross: other-construct nodes only (pred2/infl2)
plot_pi <- function(pred, infl, tag) {
  save_pdf_png(file.path(out_dir, paste0("fig3_predictability_influence_", tag)), 13, 7, function() {
    par(mfrow = c(1, 2), mar = c(2, 8, 2, 5), las = 1)
    barplot(rev(pred), horiz = TRUE, names.arg = rev(labels), col = rainbow(k),
            ylab = paste0("Predictability (", tag, ")"))
    barplot(rev(infl), horiz = TRUE, names.arg = rev(labels), col = rainbow(k),
            ylab = paste0("Influence (", tag, ")"))
  })
  save_pdf_png(file.path(out_dir, paste0("fig3_predictability_", tag)), 8, 6, function() {
    par(mar = c(2, 8, 2, 5), las = 1)
    barplot(rev(pred), horiz = TRUE, names.arg = rev(labels), col = rainbow(k),
            ylab = paste0("Predictability (", tag, ")"))
  })
  save_pdf_png(file.path(out_dir, paste0("fig4_influence_", tag)), 8, 6, function() {
    par(mar = c(2, 8, 2, 5), las = 1)
    barplot(rev(infl), horiz = TRUE, names.arg = rev(labels), col = rainbow(k),
            ylab = paste0("Influence (", tag, ")"))
  })
}
plot_pi(pred1, infl1, "total")
plot_pi(pred2, infl2, "cross")

#### 7. multi-wave: free estimation vs equal-weight constraints (3-4 waves) ####
wave_vars <- lapply(wave_prefixes, function(p) grep(paste0("^", p), names(swan7), value = TRUE))
wave_vars <- wave_vars[lengths(wave_vars) > 0]
n_waves <- length(wave_vars)
if (run_multiwave && n_waves >= 3) {
  suffix <- sub("^T[0-9]+_", "", wave_vars[[1]])
  wave_vars <- lapply(wave_vars, function(v) v[match(suffix, sub("^T[0-9]+_", "", v))])
  kk <- length(suffix)
  if (kk != k) warning("Multi-wave node count ", kk, " differs from k=", k, "; using kk.")

  # free per-transition nodewise LASSO
  B_list <- vector("list", n_waves - 1)
  for (t in seq_len(n_waves - 1)) {
    X <- as.matrix(swan7[, wave_vars[[t]], drop = FALSE])
    Y <- as.matrix(swan7[, wave_vars[[t + 1]], drop = FALSE])
    storage.mode(X) <- storage.mode(Y) <- "double"
    Wt <- matrix(0, kk, kk, dimnames = list(suffix, suffix))
    for (j in seq_len(kk)) {
      set.seed(seed_plain)
      cv <- cv.glmnet(X, Y[, j], family = "gaussian", alpha = 1, standardize = TRUE)
      Wt[, j] <- coef(cv, s = cv$lambda.min, exact = FALSE)[2:(kk + 1)]
    }
    B_list[[t]] <- Wt
    write.csv(Wt, file.path(out_dir, paste0("multiwave_free_edges_t", t, "_t", t + 1, ".csv")))
  }

  # paths that are zero in every transition are fixed to 0 in both models
  zero_all <- matrix(TRUE, kk, kk)
  for (B in B_list) zero_all <- zero_all & (B == 0)

  build_syntax <- function(constrain_equal) {
    reg <- character(); res <- character()
    for (t in seq_len(n_waves - 1)) {
      for (j in seq_len(kk)) {
        dv <- wave_vars[[t + 1]][j]
        terms <- character(kk)
        for (i in seq_len(kk)) {
          if (zero_all[i, j]) terms[i] <- paste0("0*", wave_vars[[t]][i])
          else if (constrain_equal) terms[i] <- paste0("b", i, "_", j, "*", wave_vars[[t]][i])
          else terms[i] <- wave_vars[[t]][i]
        }
        reg <- c(reg, paste(dv, "~", paste(terms, collapse = " + ")))
      }
      for (i in seq_len(kk)) for (j in i:kk)
        res <- c(res, paste0(wave_vars[[t + 1]][i], " ~~ ", wave_vars[[t + 1]][j]))
    }
    paste(c(reg, res), collapse = "\n")
  }

  dat_waves <- swan7[, unlist(wave_vars), drop = FALSE]
  fit_free <- tryCatch(
    sem(build_syntax(FALSE), data = dat_waves, missing = "FIML", fixed.x = FALSE),
    error = function(e) { warning("Free multi-wave model failed: ", conditionMessage(e)); NULL })
  fit_equal <- tryCatch(
    sem(build_syntax(TRUE), data = dat_waves, missing = "FIML", fixed.x = FALSE),
    error = function(e) { warning("Equal-weight multi-wave model failed: ", conditionMessage(e)); NULL })

  if (!is.null(fit_free) && !is.null(fit_equal)) {
    cmp <- anova(fit_free, fit_equal)
    write.csv(cmp, file.path(out_dir, "multiwave_free_vs_equal_anova.csv"), row.names = FALSE)
    fm <- rbind(
      free = fitMeasures(fit_free, c("chisq", "df", "aic", "bic", "cfi", "rmsea")),
      equal = fitMeasures(fit_equal, c("chisq", "df", "aic", "bic", "cfi", "rmsea")))
    write.csv(fm, file.path(out_dir, "multiwave_fit_measures.csv"))
  }

  # per-transition free-estimation figures
  kept <- unlist(lapply(B_list, function(B) B[zero_all == FALSE]))
  max_edge <- if (length(kept) && any(is.finite(kept))) max(abs(kept), na.rm = TRUE) else 1
  lay_mw <- qgraph(B_list[[1]], layout = "spring", DoNotPlot = TRUE)$layout
  for (t in seq_len(n_waves - 1)) {
    save_pdf_png(file.path(out_dir, paste0("multiwave_free_t", t, "_t", t + 1)), 8, 7, function() {
      qgraph(B_list[[t]], directed = TRUE, layout = lay_mw, theme = "colorblind",
             labels = suffix, vsize = 5, posCol = "blue", negCol = "red",
             legend = FALSE, maximum = max_edge, edge.width = 2,
             title = paste0("Free estimation: T", t, " -> T", t + 1))
    })
  }
} else if (run_multiwave) {
  message("Multi-wave comparison skipped: need >=3 waves, found ", n_waves, ".")
}

#### 8. optional bootstrap ####
if (run_bootstrap) {
  boot_estimator <- function(data) {
    X <- as.matrix(data[, 1:k]); Y <- as.matrix(data[, (k + 1):(2 * k)])
    W <- matrix(0, k, k)
    for (i in 1:k) {
      cv <- cv.glmnet(X, Y[, i], family = "gaussian", alpha = 1, standardize = TRUE)
      W[, i] <- coef(cv, s = cv$lambda.min, exact = FALSE)[2:(k + 1)]
    }
    W
  }
  net <- bootnet::estimateNetwork(net.t1.t2.swan.df, fun = boot_estimator,
                                  labels = labels, directed = TRUE)
  boot_edges <- bootnet::bootnet(net, type = "nonparametric", nBoots = n_boots,
                                 nCores = n_cores, statistics = "edge")
  boot_case <- bootnet::bootnet(net, type = "case", nBoots = n_boots, nCores = n_cores,
                                statistics = c("outStrength", "inStrength"))
  write.csv(boot_edges$bootTable, file.path(out_dir, "clpn_edge_bootstrap.csv"), row.names = FALSE)
  write.csv(boot_case$bootTable, file.path(out_dir, "clpn_case_bootstrap.csv"), row.names = FALSE)
  capture.output(corStability(boot_case),
                 file = file.path(out_dir, "clpn_cs_coefficients.txt"))
}

writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
cat("\nDONE. Outputs in:", normalizePath(out_dir), "\n")
