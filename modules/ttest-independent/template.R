option_or <- function(options, id, default) {
  value <- options[[id]]
  if (is.null(value)) default else value
}

sanitize_backticks <- function(name) gsub("`", "\\`", name, fixed = TRUE)

quoted_name <- function(name) paste0("`", sanitize_backticks(name), "`")

run_module <- function(df, variables, options, output_dir) {
  dependent <- variables$dependent
  if (is.character(dependent) && length(dependent) == 1) dependent <- list(dependent)
  grouping <- variables$grouping
  if (is.null(dependent) || length(dependent) == 0) stop("A dependent variable is required")
  if (is.null(grouping) || !nzchar(grouping)) stop("A grouping variable is required")
  if (!all(c(unlist(dependent), grouping) %in% names(df))) stop("Selected variable not found")

  df[[grouping]] <- droplevels(as.factor(df[[grouping]]))
  if (nlevels(df[[grouping]]) != 2) stop("Grouping variable must contain exactly 2 levels")

  var_equal <- isTRUE(option_or(options, "varEqual", FALSE))
  conf_level <- as.numeric(option_or(options, "confLevel", 0.95))
  normality <- isTRUE(option_or(options, "normalityTest", FALSE))
  effect_size <- isTRUE(option_or(options, "effectSize", FALSE))
  plot_desc <- isTRUE(option_or(options, "plotDescriptives", FALSE))
  if (!is.finite(conf_level) || conf_level <= 0 || conf_level >= 1) stop("Confidence level must be between 0 and 1")

  main_rows <- list(); tables <- list(); plots <- list(); normal_rows <- list()
  dep_names <- unlist(dependent)
  for (dep in dep_names) {
    complete <- !is.na(df[[dep]]) & !is.na(df[[grouping]])
    test_df <- df[complete, c(dep, grouping), drop = FALSE]
    formula <- stats::as.formula(paste0("`", dep, "` ~ `", grouping, "`"))
    test <- stats::t.test(formula, data = test_df, var.equal = var_equal, conf.level = conf_level)
    main_rows[[length(main_rows) + 1]] <- list(
      variable = dep, statistic = unname(test$statistic), df = unname(test$parameter),
      p.value = test$p.value, conf.low = test$conf.int[[1]], conf.high = test$conf.int[[2]],
      estimate = unname(test$estimate[[1]] - test$estimate[[2]])
    )

    if (effect_size) {
      groups <- split(test_df[[dep]], test_df[[grouping]])
      pooled_sd <- sqrt(((length(groups[[1]]) - 1) * var(groups[[1]]) +
                         (length(groups[[2]]) - 1) * var(groups[[2]])) /
                        (length(groups[[1]]) + length(groups[[2]]) - 2))
      d_value <- (mean(groups[[1]]) - mean(groups[[2]])) / pooled_sd
      main_rows[[length(main_rows)]][["cohens.d"]] <- d_value
    }

    if (normality) {
      for (level in levels(test_df[[grouping]])) {
        values <- test_df[[dep]][test_df[[grouping]] == level]
        shapiro <- if (length(values) >= 3 && length(values) <= 5000) {
          stats::shapiro.test(values)
        } else NULL
        normal_rows[[length(normal_rows) + 1]] <- list(variable = dep, group = level,
          statistic = if (is.null(shapiro)) NA_real_ else unname(shapiro$statistic),
          p.value = if (is.null(shapiro)) NA_real_ else shapiro$p.value)
      }
    }

    if (plot_desc) {
      plot_id <- paste0("desc_plot_", gsub("[^A-Za-z0-9_]", "_", dep))
      plot_path <- file.path(output_dir, paste0(plot_id, ".png"))
      levels_used <- levels(test_df[[grouping]])
      summary_rows <- lapply(levels_used, function(level) {
        values <- test_df[[dep]][test_df[[grouping]] == level]
        sample_n <- length(values)
        margin <- stats::qt((1 + conf_level) / 2, df = sample_n - 1) *
          stats::sd(values) / sqrt(sample_n)
        mean_value <- mean(values)
        list(group = level, mean = mean_value, low = mean_value - margin,
             high = mean_value + margin)
      })
      summary_df <- do.call(rbind, lapply(summary_rows, as.data.frame,
                                          stringsAsFactors = FALSE))
      p <- ggplot2::ggplot(summary_df, ggplot2::aes(x = group, y = mean,
                                                    ymin = low, ymax = high)) +
        ggplot2::geom_pointrange(size = 0.8) +
        ggplot2::labs(x = grouping, y = dep, title = paste("Means with", conf_level * 100, "% CI")) +
        ggplot2::theme_minimal(base_size = 12)
      ggplot2::ggsave(plot_path, p, width = 7, height = 5, dpi = 300)
      plots[[length(plots) + 1]] <- list(id = plot_id, title = paste("Group Means:", dep), path = plot_path)
    }
  }

  main_df <- do.call(rbind, lapply(main_rows, as.data.frame, stringsAsFactors = FALSE))
  main_columns <- c("variable", "statistic", "df", "p.value", "conf.low", "conf.high")
  if (effect_size) main_columns <- c(main_columns, "cohens.d")
  main_df <- main_df[, intersect(main_columns, names(main_df)), drop = FALSE]
  method_note <- if (var_equal) "Student's t-test used." else "Welch's t-test used."
  tables[[length(tables) + 1]] <- data_frame_table(main_df, "ttest_main",
    "Independent Samples T-Test", c(method_note))

  if (normality) {
    normal_df <- do.call(rbind, lapply(normal_rows, as.data.frame, stringsAsFactors = FALSE))
    tables[[length(tables) + 1]] <- data_frame_table(normal_df, "ttest_normality",
      "Shapiro-Wilk Normality Tests", c("Test unavailable for groups outside n = 3 to 5000."))
  }

  syntax_values <- vapply(dep_names, function(dep) {
    paste0("t.test(", quoted_name(dep), " ~ ", quoted_name(grouping),
      ", data = df, var.equal = ", toupper(as.character(var_equal)),
      ", conf.level = ", format(conf_level, digits = 15, scientific = FALSE), ")")
  }, character(1))

  list(status = "success", rSyntax = paste(syntax_values, collapse = "\n"),
       tables = tables, plots = plots, warnings = list(), error = NULL)
}
