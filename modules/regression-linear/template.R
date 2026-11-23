run_module <- function(df, variables, options, output_dir) {
  dep <- variables$dependent[[1]]; preds <- as.character(variables$predictors)
  complete <- stats::complete.cases(df[,c(dep,preds),drop=FALSE]); model_df <- df[complete,c(dep,preds),drop=FALSE]
  formula <- stats::as.formula(paste0("`",dep,"` ~ ",paste(paste0("`",preds,"`"),collapse=" + ")))
  model <- stats::lm(formula,data=model_df); sum_fit <- summary(model)
  coef_rows <- as.data.frame(stats::coef(sum_fit)); coef_rows$term <- rownames(coef_rows); names(coef_rows)[1:4] <- c("estimate","std_error","statistic","p.value")
  tables <- list(simple_table("linear_coefficients","Linear Regression Coefficients",coef_rows))
  fit <- data.frame(r_squared=sum_fit$r.squared,adjusted_r_squared=sum_fit$adj.r.squared,f_statistic=sum_fit$fstatistic[[1]],df1=sum_fit$fstatistic[[2]],df2=sum_fit$fstatistic[[3]],p.value=stats::pf(sum_fit$fstatistic[[1]],sum_fit$fstatistic[[2]],sum_fit$fstatistic[[3]],lower.tail=FALSE));tables[[2]]<-simple_table("linear_fit","Model Fit",fit)
  plots<-list();if(isTRUE(option_value(options,"plotResiduals",TRUE))){p<-ggplot2::ggplot(data.frame(fitted=stats::fitted(model),residual=stats::residuals(model)),ggplot2::aes(fitted,residual))+ggplot2::geom_point()+ggplot2::geom_hline(yintercept=0,linetype="dashed")+ggplot2::theme_minimal();item<-save_plot(p,output_dir,"linear_residual_fitted");item$title<-"Residuals vs Fitted";plots[[1]]<-item}
  success_result(paste0("lm(`",dep,"` ~ `",paste(preds,collapse="` + `"),"`, data = df)"),tables,plots)
}
