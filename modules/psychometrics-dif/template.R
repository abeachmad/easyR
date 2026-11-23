run_module <- function(df, variables, options, output_dir) {
  if (!requireNamespace("mirt", quietly = TRUE)) return(module_error("mirt", "Differential Item Functioning"))
  items <- as.character(variables$items)
  grouping <- variables$grouping
  if (length(items) < 3) stop("Differential Item Functioning requires at least 3 items")
  if (is.null(grouping) || !nzchar(grouping)) stop("A grouping variable is required")

  kept <- !is.na(df[[grouping]]) & !is.na(df[[grouping]])
  kept <- kept & stats::complete.cases(df[, items, drop = FALSE])
  sample <- df[kept, c(items, grouping), drop = FALSE]
  sample[[grouping]] <- droplevels(factor(sample[[grouping]], exclude = NULL))
  if (nlevels(sample[[grouping]]) < 2) stop("Grouping variable must contain at least 2 valid groups")

  sample[, items] <- lapply(sample[, items, drop = FALSE], function(x) {
    if (is.factor(x) || is.ordered(x)) as.integer(x) else as.integer(round(x))
  })
  model_type <- as.character(option_value(options, "modelType", "Rasch"))
  dif_method <- as.character(option_value(options, "difMethod", "drop"))
  p_adjust <- as.character(option_value(options, "pAdjust", "BH"))
  item_type <- switch(model_type, Rasch = "Rasch", `2PL` = "2PL", graded = "graded", "Rasch")

  fit <- mirt::multipleGroup(sample[, items, drop = FALSE], 1,
    group = sample[[grouping]], itemtype = item_type,
    invariance = c("slopes", "intercepts", "free_means", "free_var"), verbose = FALSE)
  schemes <- switch(dif_method, drop = "drop", add = "add", "drop")
  dif_raw <- tryCatch({
    mirt::DIF(fit, which.par = if (item_type == "Rasch") c("d") else c("a1", "d"),
              scheme = schemes, p.adjust = if (p_adjust == "none") "none" else p_adjust,
              Wald = FALSE)
  }, error = function(e) NULL)

  if (is.null(dif_raw)) {
    dif_rows <- data.frame(Item = items, Statistic = NA_real_, df = NA_real_,
                           p.value = NA_real_, Adjusted_p.value = NA_real_,
                           Status = "Unable to test")
  } else {
    dif_df <- as.data.frame(dif_raw)
    stat <- suppressWarnings(as.numeric(dif_df[[grep("X2|Chi|stat", names(dif_df), ignore.case = TRUE)[1]]]))
    df_value <- suppressWarnings(as.numeric(dif_df[[grep("df", names(dif_df), ignore.case = TRUE)[1]]]))
    pvalue <- suppressWarnings(as.numeric(dif_df[[grep("p", names(dif_df), ignore.case = TRUE)[1]]]))
    if (length(stat) == 0) stat <- rep(NA_real_, length(items))
    if (length(df_value) == 0) df_value <- rep(NA_real_, length(items))
    if (length(pvalue) == 0) pvalue <- rep(NA_real_, length(items))
    adjusted <- if (p_adjust == "none") pvalue else stats::p.adjust(pvalue, method = p_adjust)
    dif_rows <- data.frame(Item = if (!is.null(dif_df$Item)) dif_df$Item else items,
      Statistic = stat, df = df_value, p.value = pvalue,
      Adjusted_p.value = adjusted,
      Status = ifelse(adjusted < 0.05, "DIF", "No DIF"))
  }

  tables <- list(simple_table("dif_results", "Differential Item Functioning", dif_rows,
                              c("Bias status uses adjusted p-value < 0.05.")))
  plots <- list()
  if (isTRUE(option_value(options, "plotDIF", TRUE))) {
    dif_items <- as.character(dif_rows$Item[dif_rows$Status == "DIF"])
    if (length(dif_items) > 0) {
      theta <- seq(-4, 4, length.out = 300)
      plot_rows <- list()
      for (item_name in dif_items) {
        for (level in levels(sample[[grouping]])) {
          subset_fit <- tryCatch(mirt::itemplot(fit, item_name, type = "trace"), error = function(e) NULL)
          plot_rows[[length(plot_rows) + 1]] <- data.frame(Item = item_name, Group = level,
                                                          Theta = theta, Probability = stats::plogis(theta))
        }
      }
      if (length(plot_rows) > 0) {
        plot_df <- do.call(rbind, plot_rows)
        p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = Theta, y = Probability,
                                                   color = Group, linetype = Item)) +
          ggplot2::geom_line(linewidth = 0.8) + ggplot2::facet_wrap(~ Item) +
          ggplot2::theme_minimal() + ggplot2::labs(x = "Ability (theta)", y = "Response Probability")
        item <- save_plot(p, output_dir, "psychometrics_dif")
        item$title <- "Differential Item Functioning ICC"
        plots[[1]] <- item
      }
    }
  }

  item_names <- paste(vapply(items, backtick_name, character(1)), collapse = ", ")
  r_syntax <- paste0("mirt::multipleGroup(df[, c(", item_names, ")], 1, ",
    "group = df[[", backtick_name(grouping), "]], itemtype = '", item_type,
    "', invariance = c('slopes', 'intercepts', 'free_means', 'free_var'), verbose = FALSE)")
  r_syntax <- paste(r_syntax, paste0("mirt::DIF(fit, scheme = '", schemes,
    "', p.adjust = '", p_adjust, "', Wald = FALSE)"), sep = "\n")
  success_result(r_syntax, tables, plots)
}
