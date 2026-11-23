run_module <- function(df, variables, options, output_dir) {
  dep <- variables$dependent[[1]]; group <- variables$grouping[[1]]
  complete <- stats::complete.cases(df[,c(dep,group),drop=FALSE]); test_df <- df[complete,c(dep,group),drop=FALSE]; test_df[[group]] <- factor(test_df[[group]])
  formula <- stats::as.formula(paste0("`",dep,"` ~ `",group,"`")); fit <- stats::kruskal.test(formula,data=test_df)
  n <- nrow(test_df); k <- nlevels(test_df[[group]]); epsilon <- unname(fit$statistic)/(n^2-1)
  tables <- list(simple_table("kruskal_main","Kruskal-Wallis Test",data.frame(statistic=unname(fit$statistic),df=unname(fit$parameter),p.value=fit$p.value,epsilon_squared=epsilon)))
  if(isTRUE(option_value(options,"pairwise",TRUE))) { pair <- stats::pairwise.wilcox.test(test_df[[dep]],test_df[[group]],p.adjust.method="holm"); pvals <- as.data.frame(pair$p.value); pvals$comparison <- rownames(pvals); tables[[2]]<-simple_table("kruskal_pairwise","Pairwise Wilcoxon Post-Hoc",pvals) }
  p<-ggplot2::ggplot(test_df,ggplot2::aes(x=.data[[group]],y=.data[[dep]]))+ggplot2::geom_boxplot(fill="#78A9C8")+ggplot2::theme_minimal();item<-save_plot(p,output_dir,"kruskal_boxplot");item$title<-"Kruskal-Wallis Boxplot"
  success_result(paste0("kruskal.test(`",dep,"` ~ `",group,"`, data = df)"),tables,list(item))
}
