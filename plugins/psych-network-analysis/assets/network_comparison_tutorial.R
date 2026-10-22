# Cross-sectional network comparison tutorial: independent groups only.
# Requires readxl and NetworkComparisonTest.
library(readxl)
library(NetworkComparisonTest)

# ---- Edit configuration ----
file <- "data.xlsx"
group_var <- "group"
group_1 <- "A"
group_2 <- "B"
nodes <- c("Item1", "Item2", "Item3", "Item4")
measurement <- "continuous" # "continuous" or "binary" in this simple tutorial
binary_network <- identical(measurement, "binary")
it <- 1000L             # fewer only for a labeled pilot
seed <- 20261022L
# This direct-data example is Gaussian or binary only. For ordinal/mixed nodes,
# configure a validated common estimator explicitly; do not recode by storage type.
# ----------------------------

dat <- as.data.frame(read_excel(file))
stopifnot(all(c(group_var, nodes) %in% names(dat)))
if (!measurement %in% c("continuous", "binary"))
  stop("This tutorial supports continuous or binary nodes only.")
dat <- dat[dat[[group_var]] %in% c(group_1, group_2), c(group_var, nodes)]
g1 <- dat[dat[[group_var]] == group_1, nodes, drop = FALSE]
g2 <- dat[dat[[group_var]] == group_2, nodes, drop = FALSE]
if (!all(vapply(c(g1, g2), function(x) all(vapply(x, is.numeric, logical(1))), logical(1))))
  stop("Recode and document node measurement levels before NCT.")
if (measurement == "binary" && any(vapply(c(g1, g2), function(x) !all(na.omit(unique(x)) %in% c(0, 1)), logical(1))))
  stop("For binary.data=TRUE, recode nodes explicitly to 0/1 first.")
if (any(vapply(c(g1, g2), function(x) anyNA(x), logical(1))))
  stop("Choose and report a missing-data strategy before NCT; no silent deletion.")

set.seed(seed)
nct <- NCT(data1 = g1, data2 = g2, paired = FALSE,
           binary.data = binary_network, it = it,
           test.edges = FALSE, test.centrality = FALSE,
           progressbar = TRUE)
print(nct)
saveRDS(nct, "nct_primary.rds")
capture.output(print(nct), file = "nct_primary.txt")
sessionInfo()
