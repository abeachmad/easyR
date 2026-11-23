run_module <- function(df, variables, options, output_dir) {
  names <- as.character(variables$variables); method <- as.character(option_value(options,"method","pearson")); subset <- df[,names,drop=FALSE]
  cor_matrix <- stats::cor(subset,use="pairwise.complete.obs",method=method)
  p_matrix <- outer(names,names,function(a,b) vapply(seq_along(a),function(i) stats::cor.test(subset[[a[i]]],subset[[b[i]]],method=method)$p.value,numeric(1)))
  # Use pairwise cor.test to build the p-value matrix reliably.
  p_matrix <- matrix(NA_real_,nrow=length(names),ncol=length(names),dimnames=list(names,names))
  for(i in seq_along(names)) for(j in seq_along(names)) p_matrix[i,j] <- stats::cor.test(subset[[i]],subset[[j]],method=method)$p.value
  cor_df <- as.data.frame(cor_matrix,check.names=FALSE); cor_df$variable <- rownames(cor_df); tables <- list(simple_table("correlation_matrix",paste(toupper(method),"Correlation Matrix"),cor_df),simple_table("correlation_pvalues","Correlation P-Values",as.data.frame(p_matrix)))
  plots <- list(); if(isTRUE(option_value(options,"plotHeatmap",TRUE))) { long <- as.data.frame(as.table(cor_matrix)); names(long)<-c("Variable1","Variable2","Correlation"); p<-ggplot2::ggplot(long,ggplot2::aes(Variable1,Variable2,fill=Correlation))+ggplot2::geom_tile()+ggplot2::scale_fill_gradient2(low="#B2182B",mid="white",high="#2166AC",midpoint=0)+ggplot2::theme_minimal(); item<-save_plot(p,output_dir,"correlation_heatmap");item$title<-"Correlation Heatmap";plots[[1]]<-item }
  success_result(paste0("cor(df[, c(",paste(vapply(names,backtick_name,character(1)),collapse=", "),")], use = 'pairwise.complete.obs', method = '",method,"')"),tables,plots)
}
