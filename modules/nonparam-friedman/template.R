run_module <- function(df, variables, options, output_dir) {
  measures <- as.character(variables$measures)
  if(length(measures)<3) stop("Friedman test requires at least 3 conditions")
  matrix_df <- df[,measures,drop=FALSE]; complete <- stats::complete.cases(matrix_df); matrix_df <- matrix_df[complete,,drop=FALSE]
  if(nrow(matrix_df)<3) stop("Friedman test needs at least 3 complete rows")
  fit <- stats::friedman.test(as.matrix(matrix_df))
  tables <- list(simple_table("friedman_main","Friedman Test",data.frame(statistic=unname(fit$statistic),df=unname(fit$parameter),p.value=fit$p.value)))
  rank_matrix <- t(apply(as.matrix(matrix_df),1,rank)); rank_means <- colMeans(rank_matrix)
  means <- data.frame(condition=measures,rank=rank_means)
  p<-ggplot2::ggplot(means,ggplot2::aes(x=condition,y=rank,group=1))+ggplot2::geom_line()+ggplot2::geom_point()+ggplot2::theme_minimal();item<-save_plot(p,output_dir,"friedman_profile");item$title<-"Friedman Rank Profile"
  success_result(paste0("friedman.test(as.matrix(df[, c(",paste(vapply(measures,backtick_name,character(1)),collapse=", "),")]))"),tables,list(item))
}
