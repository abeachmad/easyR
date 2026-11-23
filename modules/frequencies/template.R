run_module <- function(df, variables, options, output_dir) {
  deps <- as.character(variables$categorical)
  tables <- list(); plots <- list(); syntax <- character()
  for (name in deps) {
    tab <- table(df[[name]], useNA="ifany")
    freq <- data.frame(category=names(tab), frequency=as.numeric(tab), stringsAsFactors=FALSE)
    freq$percent <- 100*freq$frequency/sum(freq$frequency)
    freq$cumulative_percent <- cumsum(freq$percent)
    tables[[length(tables)+1]] <- simple_table(paste0("freq_",name),paste("Frequency:",name),freq)
    if (isTRUE(option_value(options,"plotBar",TRUE))) {
      p <- ggplot2::ggplot(freq,ggplot2::aes(x=category,y=frequency))+ggplot2::geom_col(fill="#55A7D9")+ggplot2::theme_minimal()+ggplot2::labs(x=name,y="Frequency")
      item <- save_plot(p,output_dir,paste0("bar_",gsub("[^A-Za-z0-9_]","_",name))); item$title <- paste("Frequency:",name); plots[[length(plots)+1]] <- item
    }
    syntax <- c(syntax,paste0("table(df[[",backtick_name(name),"]], useNA = 'ifany')"))
  }
  success_result(paste(syntax,collapse="\n"),tables,plots)
}
