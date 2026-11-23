run_module <- function(df, variables, options, output_dir) {
  if (!requireNamespace("mirt", quietly = TRUE)) return(module_error("mirt", "Item Response Theory"))
  items <- as.character(variables$items)
  if (length(items) < 3) stop("Item Response Theory requires at least 3 items")
  complete <- stats::complete.cases(df[, items, drop = FALSE])
  response <- df[complete, items, drop = FALSE]
  if (nrow(response) < 10) stop("Item Response Theory requires at least 10 complete respondents")

  model_type <- as.character(option_value(options, "modelType", "Rasch"))
  estimation <- as.character(option_value(options, "estimation", "EM"))
  item_type <- switch(model_type,
    Rasch = "Rasch", `2PL` = "2PL", `3PL` = "3PL", graded = "graded", "Rasch")
  response[] <- lapply(response, function(x) if (is.factor(x) || is.ordered(x)) as.integer(x) else as.integer(round(x)))
  response <- response[rowSums(!is.na(response)) == ncol(response), , drop = FALSE]
  if (nrow(response) < 10) stop("Too few complete item responses")

  fit <- mirt::mirt(response, 1, itemtype = item_type, method = estimation, verbose = FALSE)
  tables <- list()
  if (isTRUE(option_value(options, "itemParams", TRUE))) {
    coef_data <- mirt::coef(fit, IRTpars = TRUE, simplify = TRUE)
    item_df <- as.data.frame(coef_data$items)
    item_df$item <- rownames(item_df)
    item_df <- item_df[, c("item", setdiff(names(item_df), "item")), drop = FALSE]
    tables[[length(tables) + 1]] <- simple_table("irt_item_params", "IRT Item Parameters", item_df)
  }
  if (isTRUE(option_value(options, "modelFit", TRUE))) {
    fit_indices <- tryCatch(mirt::M2(fit), error = function(e) NULL)
    fit_row <- data.frame(
      AIC = suppressWarnings(as.numeric(mirt::extract.mirt(fit, "AIC"))),
      BIC = suppressWarnings(as.numeric(mirt::extract.mirt(fit, "BIC"))),
      logLik = suppressWarnings(as.numeric(mirt::extract.mirt(fit, "logLik"))),
      M2 = if (is.null(fit_indices)) NA_real_ else suppressWarnings(as.numeric(fit_indices$M2[[1]])),
      RMSEA = if (is.null(fit_indices)) NA_real_ else suppressWarnings(as.numeric(fit_indices$RMSEA[[1]])),
      CFI = if (is.null(fit_indices)) NA_real_ else suppressWarnings(as.numeric(fit_indices$CFI[[1]])))
    tables[[length(tables) + 1]] <- simple_table("irt_model_fit", "IRT Model Fit", fit_row,
      c("M2/RMSEA/CFI may be unavailable for small or sparse item-response matrices."))
  }

  plots <- list()
  if (isTRUE(option_value(options, "plotICC", TRUE))) {
    grDevices::png(file.path(output_dir, "irt_icc.png"), width = 2100, height = 1500, res = 300)
    mirt::plot(fit, type = "trace", facet_items = TRUE)
    grDevices::dev.off()
    plots[[length(plots) + 1]] <- list(id = "irt_icc", title = "Item Characteristic Curves",
                                      path = file.path(output_dir, "irt_icc.png"))
  }
  if (isTRUE(option_value(options, "plotInfo", TRUE))) {
    grDevices::png(file.path(output_dir, "irt_information.png"), width = 2100, height = 1500, res = 300)
    mirt::plot(fit, type = "infoSE")
    grDevices::dev.off()
    plots[[length(plots) + 1]] <- list(id = "irt_information", title = "Test Information and Standard Error",
                                      path = file.path(output_dir, "irt_information.png"))
  }

  item_names <- paste(vapply(items, backtick_name, character(1)), collapse = ", ")
  r_syntax <- paste0("mirt::mirt(df[, c(", item_names,
    ")][complete.cases(df[, c(", item_names, ")]), ], 1, itemtype = '", item_type,
    "', method = '", estimation, "', verbose = FALSE)")
  success_result(r_syntax, tables, plots)
}
