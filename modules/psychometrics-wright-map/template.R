run_module <- function(df, variables, options, output_dir) {
  if (!requireNamespace("mirt", quietly = TRUE)) return(module_error("mirt", "Wright Map"))
  if (!requireNamespace("gridExtra", quietly = TRUE)) return(module_error("gridExtra", "Wright Map layout"))
  items <- as.character(variables$items)
  if (length(items) < 3) stop("Wright Map requires at least 3 items")
  complete <- stats::complete.cases(df[, items, drop = FALSE])
  response <- df[complete, items, drop = FALSE]
  response[] <- lapply(response, function(x) if (is.factor(x) || is.ordered(x)) as.integer(x) else as.integer(round(x)))

  model_type <- as.character(option_value(options, "modelType", "Rasch"))
  theta_method <- toupper(as.character(option_value(options, "thetaMethod", "EAP")))
  item_type <- switch(model_type, Rasch = "Rasch", `2PL` = "2PL", graded = "graded", "Rasch")
  fit <- mirt::mirt(response, 1, itemtype = item_type,
                    method = "EM", verbose = FALSE)
  person <- suppressWarnings(mirt::fscores(fit, method = theta_method, full.scores = TRUE))
  theta <- as.numeric(person[, 1])
  coefficients <- mirt::coef(fit, IRTpars = TRUE, simplify = TRUE)
  item_df <- as.data.frame(coefficients$items)
  item_df$item <- rownames(item_df)

  threshold_names <- grep("^(b|b[0-9]|d)", names(item_df), value = TRUE)
  locations <- do.call(rbind, lapply(seq_along(items), function(i) {
    item_row <- item_df[item_df$item == items[i] | grepl(items[i], item_df$item, fixed = TRUE), , drop = FALSE]
    if (nrow(item_row) == 0) item_row <- item_df[i, , drop = FALSE]
    thresholds <- as.numeric(item_row[1, threshold_names, drop = TRUE])
    thresholds <- thresholds[is.finite(thresholds)]
    if (length(thresholds) == 0) thresholds <- NA_real_
    data.frame(Item = items[i], Location = if (length(thresholds) > 0) mean(thresholds) else NA_real_,
               Threshold = paste(signif(thresholds, 4), collapse = " | "))
  }))

  person_row <- data.frame(Measure = "Person ability theta",
    mean = mean(theta, na.rm = TRUE), median = stats::median(theta, na.rm = TRUE),
    sd = stats::sd(theta, na.rm = TRUE), min = min(theta, na.rm = TRUE),
    max = max(theta, na.rm = TRUE))
  item_row <- data.frame(Measure = "Item difficulty / thresholds",
    mean = mean(locations$Location, na.rm = TRUE), median = stats::median(locations$Location, na.rm = TRUE),
    sd = stats::sd(locations$Location, na.rm = TRUE), min = min(locations$Location, na.rm = TRUE),
    max = max(locations$Location, na.rm = TRUE))

  tables <- list(simple_table("wright_item_locations", "Wright Map Item Locations", locations))
  if (isTRUE(option_value(options, "showStats", TRUE))) {
    tables[[length(tables) + 1]] <- simple_table("wright_scale_stats",
      "Logit Scale Comparison", rbind(person_row, item_row))
  }

  left <- ggplot2::ggplot(data.frame(theta = theta), ggplot2::aes(x = theta)) +
    ggplot2::geom_histogram(bins = 24, fill = "#78A9C8", color = "white") +
    ggplot2::coord_flip() + ggplot2::scale_y_continuous(labels = NULL) +
    ggplot2::labs(x = NULL, y = "Respondents", title = "Person Ability") + ggplot2::theme_minimal()
  right <- ggplot2::ggplot(locations, ggplot2::aes(x = 0, y = Location)) +
    ggplot2::geom_hline(yintercept = seq(-4, 4, 1), color = "grey85") +
    ggplot2::geom_point(size = 3, color = "#C45A45") +
    ggplot2::geom_text(ggplot2::aes(label = Item), hjust = -0.15, size = 3) +
    ggplot2::coord_cartesian(ylim = range(c(-4, 4, theta, locations$Location), na.rm = TRUE)) +
    ggplot2::labs(x = NULL, y = "Logit Scale", title = "Item Difficulties") +
    ggplot2::theme_minimal() + ggplot2::theme(axis.text.x = ggplot2::element_blank())
  grDevices::png(file.path(output_dir, "psychometrics_wright_map.png"),
                 width = 2100, height = 1500, res = 300)
  gridExtra::grid.arrange(left, right, ncol = 2, widths = c(1, 1))
  grDevices::dev.off()
  plots <- list(list(id = "wright_map", title = "Wright Map",
                     path = file.path(output_dir, "psychometrics_wright_map.png")))

  item_names <- paste(vapply(items, backtick_name, character(1)), collapse = ", ")
  r_syntax <- paste0("mirt::mirt(df[, c(", item_names,
    ")][complete.cases(df[, c(", item_names, ")]), ], 1, itemtype = '", item_type,
    "', method = 'EM', verbose = FALSE)")
  r_syntax <- paste(r_syntax, paste0("mirt::fscores(fit, method = '", theta_method,
                                      "', full.scores = TRUE)"), sep = "\n")
  success_result(r_syntax, tables, plots)
}
