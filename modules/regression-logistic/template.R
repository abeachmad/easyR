run_module <- function(df, variables, options, output_dir) {
  dep <- variables$dependent[[1]]
  preds <- as.character(variables$predictors)
  needed <- c(dep, preds)
  model_df <- df[stats::complete.cases(df[, needed, drop = FALSE]), needed, drop = FALSE]
  values <- model_df[[dep]]
  if (is.numeric(values) || is.integer(values)) {
    numeric_values <- as.integer(values)
  } else {
    labels <- unique(as.character(values)); labels <- labels[!is.na(labels)]
    if (length(labels) != 2) stop("Binary logistic outcome must contain exactly 2 levels")
    numeric_values <- as.integer(as.character(values) == labels[[2]])
  }
  if (!all(numeric_values %in% c(0L, 1L))) stop("Binary logistic outcome must contain exactly 2 levels")
  if (length(unique(numeric_values)) != 2) stop("Binary logistic outcome must contain exactly 2 levels")
  model_df$.binary_outcome <- numeric_values
  formula <- stats::as.formula(paste0(".binary_outcome ~ ", paste(paste0("`", preds, "`"), collapse = " + ")))
  model <- stats::glm(formula, data = model_df, family = stats::binomial())
  coef <- summary(model)$coefficients
  ci <- suppressWarnings(stats::confint(model))
  rows <- data.frame(term = rownames(coef), odds_ratio = exp(coef[,1]), conf.low = exp(ci[,1]), conf.high = exp(ci[,2]), p.value = coef[,4])
  tables <- list(simple_table("logistic_coefficients", "Binary Logistic Regression", rows))
  null <- stats::glm(.binary_outcome ~ 1, data = model_df, family = stats::binomial())
  fit <- data.frame(mcfadden_r2 = 1 - as.numeric(stats::logLik(model)) / as.numeric(stats::logLik(null)), aic = stats::AIC(model))
  tables[[2]] <- simple_table("logistic_fit", "Model Fit", fit)
  success_result(paste0("glm(.binary_outcome ~ `", paste(preds, collapse = "` + `"), "`, data = df, family = binomial)"), tables)
}
