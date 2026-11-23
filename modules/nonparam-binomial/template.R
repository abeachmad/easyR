run_module <- function(df, variables, options, output_dir) {
  name <- variables$dependent[[1]]; p0 <- as.numeric(option_value(options,"p",.5)); success_value <- option_value(options,"success",1)
  x <- df[[name]]; if(is.factor(x)) x <- as.character(x)
  successes <- sum(x==success_value,na.rm=TRUE); trials <- sum(!is.na(x)); bin <- stats::binom.test(successes,trials,p=p0); prop <- stats::prop.test(successes,trials,p=p0)
  tables <- list(simple_table("binomial_test","Exact Binomial Test",data.frame(successes=successes,trials=trials,estimated_proportion=successes/trials,hypothesized_proportion=p0,p.value=bin$p.value,conf.low=bin$conf.int[1],conf.high=bin$conf.int[2])),simple_table("proportion_test","One-Sample Proportion Test",data.frame(successes=successes,trials=trials,statistic=unname(prop$statistic),p.value=prop$p.value)))
  success_result(paste0("binom.test(x = ",successes," , n = ",trials," , p = ",p0,")"),tables)
}
