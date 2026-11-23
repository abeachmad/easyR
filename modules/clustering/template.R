run_module <- function(df, variables, options, output_dir) {
  names <- as.character(variables$variables); k <- as.integer(option_value(options,"clusters",3)); method <- as.character(option_value(options,"method","kmeans"))
  complete <- stats::complete.cases(df[,names,drop=FALSE]); sample_df <- df[complete,names,drop=FALSE]
  if(nrow(sample_df)<k) stop("Cluster analysis needs at least as many complete rows as clusters")
  scaled <- scale(sample_df); scaled <- scaled[,apply(scaled,2,function(x) all(is.finite(x))),drop=FALSE]
  if(ncol(scaled)<1) stop("Cluster variables contain no finite variation")
  if(method=="kmeans") { fit <- stats::kmeans(scaled,centers=k,nstart=25); cluster <- fit$cluster; rows <- data.frame(cluster=seq_len(k),size=as.numeric(table(cluster)),within_ss=fit$withinss) } else { distance <- stats::dist(scaled); fit <- stats::hclust(distance); cluster <- stats::cutree(fit,k=k); rows <- data.frame(cluster=seq_len(k),size=as.numeric(table(cluster))) }
  tables <- list(simple_table("cluster_summary","Cluster Summary",rows)); scatter <- as.data.frame(scaled); scatter$cluster <- factor(cluster)
  p <- ggplot2::ggplot(scatter,ggplot2::aes(.data[[colnames(scatter)[1]]],.data[[if(ncol(scatter)>2) colnames(scatter)[2] else colnames(scatter)[1]]],color=cluster))+ggplot2::geom_point()+ggplot2::theme_minimal()
  item <- save_plot(p,output_dir,"cluster_scatter"); item$title <- "Cluster Scatter Plot"
  plots <- list(item)
  syntax <- paste0("kmeans(scale(df[, c(",paste(vapply(names,backtick_name,character(1)),collapse=", "),")]), centers = ",k," , nstart = 25)")
  success_result(syntax,tables,plots)
}
