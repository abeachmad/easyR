run_module <- function(df, variables, options, output_dir) {
  name <- variables$dependent[[1]]; x <- df[[name]]; mu <- as.numeric(option_value(options,"mu",0)); conf <- as.numeric(option_value(options,"confLevel",.95))
  test <- stats::t.test(x,mu=mu,conf.level=conf); d <- (mean(x)-mu)/stats::sd(x)
  main <- data.frame(variable=name,mean=mean(x),mean_difference=mean(x)-mu,t=unname(test$statistic),df=unname(test$parameter),p.value=test$p.value,conf.low=test$conf.int[1],conf.high=test$conf.int[2],cohens_d=d)
  tables <- list(simple_table("onesample_main","One-Sample T-Test",main))
  if (isTRUE(option_value(options,"wilcoxon",FALSE))) {
    w <- stats::wilcox.test(x,mu=mu,conf.int=TRUE); tables[[2]] <- simple_table("onesample_wilcoxon","Wilcoxon Signed-Rank",data.frame(statistic=unname(w$statistic),p.value=w$p.value))
  }
  success_result(paste0("t.test(df[[",backtick_name(name),"]], mu = ",mu,", conf.level = ",conf,")"),tables)
}
