run_module <- function(df, variables, options, output_dir) {
  dep <- variables$dependent[[1]]
  group <- variables$grouping[[1]]
  complete <- stats::complete.cases(df[, c(dep, group), drop=FALSE])
  test_df <- df[complete, c(dep, group), drop=FALSE]
  test_df[[group]] <- factor(test_df[[group]])
  if (nlevels(test_df[[group]]) < 2) stop("One-way ANOVA requires at least 2 groups")
  model <- stats::lm(test_df[[dep]] ~ test_df[[group]])
  classic <- stats::anova(model)
  main <- data.frame(term=rownames(classic)[1], sum_squares=classic$`Sum Sq`[1],
    df=classic$Df[1], F=classic$`F value`[1], p.value=classic$`Pr(>F)`[1])
  tables <- list(simple_table("anova_oneway", "One-Way ANOVA", main))
  if (isTRUE(option_value(options,"welch",TRUE))) {
    w <- stats::oneway.test(test_df[[dep]] ~ test_df[[group]])
    tables[[2]] <- simple_table("anova_welch", "Welch ANOVA",
      data.frame(statistic=unname(w$statistic), num_df=unname(w$parameter)[1], p.value=w$p.value))
  }
  p <- ggplot2::ggplot(test_df, ggplot2::aes(x=.data[[group]], y=.data[[dep]])) +
    ggplot2::geom_boxplot() + ggplot2::theme_minimal()
  item <- save_plot(p, output_dir, "anova_means_ci")
  item$title <- "Group Comparison"
  success_result(paste0("stats::aov(df[['", dep, "']] ~ df[['", group, "']], data = df)"), tables, list(item))
}
