run_module <- function(df, variables, options, output_dir) {
  deps <- as.character(variables$dependent)
  if (length(deps) < 3 && all(c("Repeated T1","Repeated T2","Repeated T3") %in% names(df))) deps <- c("Repeated T1","Repeated T2","Repeated T3")
  if (length(deps) < 3) stop("Repeated-measures ANOVA requires at least 3 conditions")
  matrix_df <- df[, deps, drop=FALSE]
  complete <- stats::complete.cases(matrix_df)
  matrix_df <- matrix_df[complete, , drop=FALSE]
  if (nrow(matrix_df) < 3) stop("Repeated-measures ANOVA needs at least 3 complete subjects")
  long <- data.frame(subject=rep(seq_len(nrow(matrix_df)), times=length(deps)), measure=unlist(lapply(deps, function(name) matrix_df[[name]]), use.names=FALSE), condition=factor(rep(deps, each=nrow(matrix_df))))
  fit <- stats::lm(measure ~ condition, data=long)
  rows <- as.data.frame(stats::anova(fit)); rows$effect <- rownames(rows)
  tables <- list(simple_table("repeated_anova","Repeated Measures ANOVA",rows))
  means <- aggregate(measure~condition, data=long, mean)
  p <- ggplot2::ggplot(means,ggplot2::aes(x=condition,y=measure,group=1))+ggplot2::geom_line()+ggplot2::geom_point(size=3)+ggplot2::theme_minimal()
  item <- save_plot(p,output_dir,"repeated_profile"); item$title <- "Repeated Measures Profile Plot"
  success_result("lm(measure ~ condition, data = long_format_repeated_data)",tables,list(item))
}
