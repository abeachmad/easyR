run_module <- function(df, variables, options, output_dir) {
  names <- as.character(variables$variables); center <- isTRUE(option_value(options,"center",TRUE)); scale_it <- isTRUE(option_value(options,"scale",TRUE))
  complete <- stats::complete.cases(df[,names,drop=FALSE]); sample_df <- df[complete,names,drop=FALSE]
  if(nrow(sample_df)<2) stop("PCA needs at least 2 complete rows")
  fit <- stats::prcomp(sample_df,center=center,scale.=scale_it)
  eigen <- fit$sdev^2; max_n <- min(as.integer(option_value(options,"components",5)),length(names)); variance <- eigen/sum(eigen)*100
  eigen_df <- data.frame(component=paste0("PC",seq_along(eigen)),eigenvalue=eigen,variance_percent=variance,cumulative_percent=cumsum(variance))
  tables <- list(simple_table("pca_eigen","PCA Eigenvalues",eigen_df[seq_len(min(nrow(eigen_df),max_n)),,drop=FALSE]),simple_table("pca_loadings","Factor Loadings",as.data.frame(unclass(fit$rotation[,seq_len(min(ncol(fit$rotation),max_n)),drop=FALSE]))))
  p<-ggplot2::qplot(seq_along(eigen),eigen,geom=c("line","point"))+ggplot2::labs(x="Component",y="Eigenvalue")+ggplot2::theme_minimal(); item<-save_plot(p,output_dir,"pca_scree");item$title<-"Scree Plot"
  scores <- as.data.frame(fit$x[,1:2,drop=FALSE]);p<-ggplot2::ggplot(scores,ggplot2::aes(.data[[names(scores)[1]]],.data[[names(scores)[2]]]))+ggplot2::geom_point()+ggplot2::theme_minimal();item2<-save_plot(p,output_dir,"pca_biplot");item2$title<-"PCA Biplot"
  success_result(paste0("prcomp(df[, c(",paste(vapply(names,backtick_name,character(1)),collapse=", "),")], complete.cases = TRUE)"),tables,list(item,item2))
}
