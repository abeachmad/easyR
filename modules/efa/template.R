run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("psych",quietly=TRUE)) return(module_error("psych","Exploratory factor analysis"))
  names <- as.character(variables$variables); nfactor <- as.integer(option_value(options,"factors",2)); rotation <- as.character(option_value(options,"rotation","varimax"))
  corr <- stats::cor(df[,names,drop=FALSE],use="pairwise.complete.obs"); bartlett <- psych::cortest.bartlett(corr,n=nrow(df)); kmo <- psych::KMO(corr)
  fit <- psych::fa(corr,nfactors=nfactor,rotate=rotation,fm="ml",n.obs=nrow(df)); loadings <- as.data.frame(unclass(fit$loadings)); loadings$variable <- rownames(loadings)
  tables <- list(simple_table("efa_loadings","EFA Factor Loadings",loadings),simple_table("efa_bartlett","Bartlett's Test",data.frame(chi_square=bartlett$chisq,df=bartlett$df,p.value=bartlett$p)),simple_table("efa_kmo","KMO Sampling Adequacy",data.frame(overall_MSA=kmo$MSA)))
  eigen <- eigen(corr)$values;p<-ggplot2::qplot(seq_along(eigen),eigen,geom=c("line","point"))+ggplot2::geom_hline(yintercept=1,linetype="dashed")+ggplot2::theme_minimal()+ggplot2::labs(x="Factor",y="Eigenvalue");item<-save_plot(p,output_dir,"efa_scree");item$title<-"EFA Scree Plot"
  success_result(paste0("psych::fa(cor(df[, c(",paste(vapply(names,backtick_name,character(1)),collapse=", "),")], use = 'pairwise.complete.obs'), nfactors = ",nfactor," , rotate = '",rotation,"', fm = 'ml')"),tables,list(item))
}
