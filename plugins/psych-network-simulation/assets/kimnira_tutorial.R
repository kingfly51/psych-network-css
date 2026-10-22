# KimNIRA dynamic binary EMA/ESM model tutorial (check installed API/version).
# Requires the current kingfly51/KimNIRA package.
library(readxl)
library(KimNIRA)

# ---- Edit configuration to match the data dictionary ----
file <- "ema_long.xlsx"
id <- "ID"
day <- "Day"
beep <- "Beep"
vars <- c("Depressed", "Anxious", "Lonely", "Stress")
allow_overnight <- FALSE
method <- "exact" # use "mc" only when exact state enumeration is infeasible
intervention_type <- "alleviating"
intervention_sd <- 1
seed <- 20261022L
# --------------------------------------------------------

dat <- as.data.frame(read_excel(file))
stopifnot(all(c(id, day, beep, vars) %in% names(dat)))
dat <- dat[order(dat[[id]], dat[[day]], dat[[beep]]), , drop = FALSE]
if (!all(vapply(dat[vars], function(x) all(na.omit(unique(x)) %in% c(0, 1)), logical(1))))
  stop("KimNIRA expects binary states; recode only with a justified rule.")

fit <- fitKIM(
  data = dat, vars = vars, id = id, dayvar = day, beepvar = beep,
  allow_overnight = allow_overnight,
  between_person = "re", screen = "fdr", fdr_q = 0.10,
  estimate_between = TRUE, verbose = TRUE
)
set.seed(seed)
sim <- runKIMNIRA(
  fit, method = method, intervention_type = intervention_type,
  intervention_sd = intervention_sd
)
saveRDS(fit, "kimnira_fit.rds")
saveRDS(sim, "kimnira_intervention.rds")
print(sim$ranked_targets)
print(sim$summary)
sessionInfo()
