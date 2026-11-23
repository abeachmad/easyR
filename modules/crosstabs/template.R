run_module <- function(df, variables, options, output_dir) {
  row <- variables$row; column <- variables$column
  tab <- table(df[[row]],df[[column]],useNA="ifany")
  chi <- stats::chisq.test(tab)
  percent <- prop.table(tab,1)*100
  main <- data.frame(row=rownames(tab),round(as.data.frame.matrix(tab),0),check.names=FALSE)
  tables <- list(simple_table("crosstab_counts","Crosstab Counts",main),
    simple_table("crosstab_test","Chi-Square Test",data.frame(statistic=unname(chi$statistic),df=unname(chi$parameter),p.value=chi$p.value)))
  n <- sum(tab); v <- sqrt(unname(chi$statistic)/(n* (min(dim(tab))-1)))
  tables[[length(tables)+1]] <- simple_table("crosstab_effect","Effect Size",data.frame(cramers_v=v))
  if (isTRUE(option_value(options,"fisher",FALSE)) && all(dim(tab)==2)) {
    fisher <- stats::fisher.test(tab); tables[[length(tables)+1]] <- simple_table("crosstab_fisher","Fisher Exact Test",data.frame(p.value=fisher$p.value,odds_ratio=unname(fisher$estimate)))
  }
  plots <- list()
  if (isTRUE(option_value(options,"plotGrouped",TRUE))) {
    long <- as.data.frame(tab); names(long) <- c("row","column","frequency")
    p <- ggplot2::ggplot(long,ggplot2::aes(x=row,y=frequency,fill=column))+ggplot2::geom_col(position="dodge")+ggplot2::theme_minimal()
    item <- save_plot(p,output_dir,"crosstab_grouped_bar"); item$title <- "Grouped Bar Chart"; plots[[1]] <- item
  }
  syntax <- paste0("chisq.test(table(df[[",backtick_name(row),"]], df[[",backtick_name(column),"]]))")
  success_result(syntax,tables,plots)
}
