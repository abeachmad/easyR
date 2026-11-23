core_packages <- c("jsonlite", "haven", "readxl", "dplyr", "broom", "ggplot2")
optional_packages <- c("car", "rstatix", "afex", "ppcor", "nnet", "MASS", "pROC",
  "psych", "cluster", "survival", "lme4", "lavaan", "forecast", "tseries",
  "metafor", "Hmisc", "vegan", "mirt", "gridExtra", "latticeExtra")
tryCatch({
  r_version <- paste(R.version$major, R.version$minor, sep = ".")
  core_missing <- core_packages[!vapply(core_packages, requireNamespace, logical(1), quietly = TRUE)]
  optional_missing <- optional_packages[!vapply(optional_packages, requireNamespace, logical(1), quietly = TRUE)]
  cat(jsonlite::toJSON(list(status = "success", rscript = "Rscript", rVersion = r_version,
    coreMissing = unname(core_missing), optionalMissing = unname(optional_missing),
    core = core_packages, optional = optional_packages, error = NULL),
    auto_unbox = TRUE, null = "null"))
}, error = function(e) {
  cat(jsonlite::toJSON(list(status = "error", rscript = NULL, rVersion = NULL,
    coreMissing = list(), optionalMissing = list(), core = list(), optional = list(),
    error = trimws(conditionMessage(e))), auto_unbox = TRUE, null = "null"))
})
