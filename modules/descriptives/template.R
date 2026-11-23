run_module <- function(df, variables, options, output_dir) {
  deps <- as.character(variables$dependent)
  rows <- lapply(deps, function(name) {
    x <- df[[name]][is.finite(df[[name]])]
    c(variable=name, n=length(x), mean=mean(x), sd=stats::sd(x), median=stats::median(x),
      iqr=stats::IQR(x), min=min(x), max=max(x), skewness=mean(((x-mean(x))/stats::sd(x))^3),
      kurtosis=mean(((x-mean(x))/stats::sd(x))^4)-3)
  })
  result_df <- as.data.frame(do.call(rbind, rows), stringsAsFactors=FALSE)
  result_df[] <- lapply(result_df, function(x) suppressWarnings(if (all(is.na(as.numeric(x)))) x else as.numeric(x)))
  tables <- list(simple_table("descriptive_main", "Descriptive Statistics", result_df))
  plots <- list()
  syntax <- character()
  if (isTRUE(option_value(options,"normalityTest",FALSE))) {
    norm <- do.call(rbind, lapply(deps, function(name) { sh <- stats::shapiro.test(df[[name]][is.finite(df[[name]]) & seq_along(df[[name]]) <= 5000]); data.frame(variable=name, statistic=unname(sh$statistic), p.value=sh$p.value) }))
    tables[[length(tables)+1]] <- simple_table("descriptive_normality","Shapiro-Wilk Normality",norm)
  }
  for (name in deps) {
    if (isTRUE(option_value(options,"plotHistogram",TRUE))) {
      p <- ggplot2::ggplot(df,ggplot2::aes(x=.data[[name]])) + ggplot2::geom_histogram(ggplot2::aes(y=ggplot2::after_stat(density)),bins=20,fill="#78A9C8",alpha=.7) + ggplot2::geom_density(linewidth=.8) + ggplot2::theme_minimal()
      plots[[length(plots)+1]] <- save_plot(p,output_dir,paste0("histogram_",gsub("[^A-Za-z0-9_]","_",name))); plots[[length(plots)]]$title <- paste("Histogram:",name)
    }
    if (isTRUE(option_value(options,"plotBoxplot",TRUE))) {
      p <- ggplot2::ggplot(df,ggplot2::aes(y=.data[[name]]))+ggplot2::geom_boxplot(fill="#78A9C8")+ggplot2::theme_minimal()
      plots[[length(plots)+1]] <- save_plot(p,output_dir,paste0("boxplot_",gsub("[^A-Za-z0-9_]","_",name))); plots[[length(plots)]]$title <- paste("Boxplot:",name)
    }
  }
  syntax <- paste(vapply(deps,function(name) paste0("psych::describe(df[,'",name,"'])"),character(1)),collapse="\n")
  success_result(syntax,tables,plots)
}
