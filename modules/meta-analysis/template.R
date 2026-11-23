run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("metafor",quietly=TRUE)) return(module_error("metafor","Meta-analysis"))
  effect <- variables$effect[[1]]; se <- variables$se[[1]]; model_type <- as.character(option_value(options,"model","random")); fit <- metafor::rma(yi=df[[effect]],sei=df[[se]],method=if(model_type=="fixed") "FE" else "REML")
  heterogeneity <- data.frame(q=as.numeric(fit$QE),q_df=as.numeric(fit$k-1),q_p.value=fit$QEp,i_squared=fit$I2,tau_squared=fit$tau2)
  tables <- list(simple_table("meta_summary","Meta-Analysis Summary",data.frame(estimate=fit$b[[1]],se=fit$se,p.value=fit$pval[[1]],ci.low=fit$ci.lb[[1]],ci.high=fit$ci.ub[[1]])),simple_table("meta_heterogeneity","Heterogeneity",heterogeneity))
  plots <- list(); if(isTRUE(option_value(options,"forest",TRUE))) { grDevices::png(file.path(output_dir,"meta_forest.png"),width=2100,height=1500,res=300); metafor::forest(fit);grDevices::dev.off();plots[[1]]<-list(id="meta_forest",title="Forest Plot",path=file.path(output_dir,"meta_forest.png")) }
  if(isTRUE(option_value(options,"funnel",TRUE))) { grDevices::png(file.path(output_dir,"meta_funnel.png"),width=2100,height=1500,res=300);metafor::funnel(fit);grDevices::dev.off();plots[[2]]<-list(id="meta_funnel",title="Funnel Plot",path=file.path(output_dir,"meta_funnel.png")) }
  success_result(paste0("metafor::rma(yi = df[[",backtick_name(effect),"]], sei = df[[",backtick_name(se),"]], method = '",if(model_type=="fixed") "FE" else "REML","')"),tables,plots)
}
