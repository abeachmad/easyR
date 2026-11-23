core_packages <- c("jsonlite", "haven", "readxl", "dplyr", "broom", "ggplot2")
optional_packages <- c("car", "rstatix", "afex", "ppcor", "nnet", "MASS", "pROC",
  "psych", "cluster", "survival", "lme4", "lavaan", "forecast", "tseries",
  "metafor", "Hmisc", "vegan", "mirt", "gridExtra", "latticeExtra")
required_packages <- c(core_packages, optional_packages)

missing <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  cat("Installing missing packages:", paste(missing, collapse = ", "), "\n", file = stderr())
  install.packages(missing, repos = "https://cloud.r-project.org")
}

failed <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(failed) > 0) stop("Unable to load R packages: ", paste(failed, collapse = ", "))
