run_module <- function(df, variables, options, output_dir) {
  dep <- variables$dependent[[1]]; preds <- as.character(variables$predictors); df[[dep]] <- factor(df[[dep]])
  model_type <- as.character(option_value(options,"model","multinomial"))
  model_df <- df[stats::complete.cases(df[,c(dep,preds),drop=FALSE]),c(dep,preds),drop=FALSE]
  model_df[[dep]] <- factor(model_df[[dep]])
  formula <- stats::as.formula(paste0("`",dep,"` ~ ",paste(paste0("`",preds,"`"),collapse=" + ")))
  if(model_type=="ordinal") { if(!requireNamespace("MASS",quietly=TRUE)) return(module_error("MASS","Ordinal logistic regression")); fit <- MASS::polr(formula,data=model_df,Hess=TRUE); sum <- summary(fit); coef <- sum$coefficients; ci <- stats::confint(fit); rows <- data.frame(term=rownames(coef),estimate=coef[,1],std_error=coef[,2],statistic=coef[,3],p.value=2*stats::pnorm(abs(coef[,3]),lower.tail=FALSE)); tables<-list(simple_table("ordinal_logistic","Ordinal Logistic Regression",rows)); syntax<-paste0("MASS::polr(",deparse(formula),", data = df, Hess = TRUE)") }
  else { if(!requireNamespace("nnet",quietly=TRUE)) return(module_error("nnet","Multinomial logistic regression")); fit <- nnet::multinom(formula,data=model_df,trace=FALSE); rows <- as.data.frame(stats::coef(fit)); rows$class <- rownames(rows); tables<-list(simple_table("multinomial_logistic","Multinomial Logistic Regression",rows)); syntax<-paste0("nnet::multinom(",deparse(formula),", data = df, trace = FALSE)") }
  success_result(syntax,tables)
}
