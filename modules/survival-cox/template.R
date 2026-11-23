run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("survival",quietly=TRUE)) return(module_error("survival","Cox regression"))
  time <- variables$time[[1]]; status <- variables$status[[1]]; preds <- as.character(variables$predictors)
  formula_text <- paste0("survival::Surv(`",time,"`, `",status,"`) ~ ",paste(paste0("`",preds,"`"),collapse=" + ")); fit <- survival::coxph(stats::as.formula(formula_text),data=df)
  sum <- summary(fit); ci <- sum$conf.int; rows <- data.frame(term=rownames(ci),hazard_ratio=ci[,1],conf.low=ci[,3],conf.high=ci[,4],p.value=sum$coefficients[,5]); tables<-list(simple_table("cox_coefficients","Cox Regression Hazard Ratios",rows))
  if(isTRUE(option_value(options,"zph",TRUE))) { zph <- survival::cox.zph(fit); zrows <- as.data.frame(zph$table); zrows$term <- rownames(zrows); tables[[2]]<-simple_table("cox_zph","Schoenfeld Residual Test",zrows) }
  success_result(paste0("survival::coxph(",formula_text," , data = df)"),tables)
}
