run_module <- function(df, variables, options, output_dir) {
  a <- variables$pair1[[1]]; b <- variables$pair2[[1]]; conf <- as.numeric(option_value(options,"confLevel",.95)); complete <- !is.na(df[[a]]) & !is.na(df[[b]])
  test <- stats::t.test(df[[a]][complete],df[[b]][complete],paired=TRUE,conf.level=conf); diff <- df[[a]][complete]-df[[b]][complete]
  main <- data.frame(pair=paste(a,b,sep=" - "),mean_difference=mean(diff),t=unname(test$statistic),df=unname(test$parameter),p.value=test$p.value,conf.low=test$conf.int[1],conf.high=test$conf.int[2],cohens_d=mean(diff)/stats::sd(diff)); tables <- list(simple_table("paired_main","Paired Samples T-Test",main))
  corr <- stats::cor.test(df[[a]][complete],df[[b]][complete]); tables[[2]] <- simple_table("paired_correlation","Paired Correlation",data.frame(correlation=unname(corr$estimate),p.value=corr$p.value))
  if (isTRUE(option_value(options,"wilcoxon",FALSE))) { w <- stats::wilcox.test(diff); tables[[3]] <- simple_table("paired_wilcoxon","Wilcoxon Matched-Pairs",data.frame(statistic=unname(w$statistic),p.value=w$p.value)) }
  plots <- list(); if (isTRUE(option_value(options,"plotDifference",TRUE))) { p <- ggplot2::qplot(diff,bins=20,fill=I("#55A7D9"))+ggplot2::theme_minimal()+ggplot2::labs(x="Paired Difference"); item <- save_plot(p,output_dir,"paired_difference"); item$title <- "Paired Difference Plot"; plots[[1]] <- item }
  syntax <- paste0("t.test(df[[",backtick_name(a),"]], df[[",backtick_name(b),"]], paired = TRUE, conf.level = ",conf,")")
  success_result(syntax,tables,plots)
}
