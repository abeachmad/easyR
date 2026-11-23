run_module <- function(df, variables, options, output_dir) {
  x <- variables$x[[1]]; y <- variables$y; color <- variables$color; fill <- variables$fill; facet <- variables$facet
  geom <- as.character(option_value(options,"geom","point")); title <- as.character(option_value(options,"title","")); theme_name <- as.character(option_value(options,"theme","theme_minimal"))
  mappings <- paste0("ggplot2::aes(x = `",x,"`",if(!is.null(y)&&length(y)>0) paste0(", y = `",y,"`") else "",if(!is.null(color)&&length(color)>0) paste0(", color = `",color,"`") else "",if(!is.null(fill)&&length(fill)>0) paste0(", fill = `",fill,"`") else "")
  geom_call <- switch(geom,point="ggplot2::geom_point()",line="ggplot2::geom_line()",bar="ggplot2::geom_bar()",boxplot="ggplot2::geom_boxplot()",violin="ggplot2::geom_violin()",histogram="ggplot2::geom_histogram(bins = 30)",density="ggplot2::geom_density()","ggplot2::geom_point()")
  p <- ggplot2::ggplot(df,ggplot2::aes(.data[[x]],if(!is.null(y)&&length(y)>0) .data[[y]] else NULL)); p <- p + eval(parse(text=geom_call))
  if(!is.null(color)&&length(color)>0) p <- p + ggplot2::aes(color=.data[[color]])
  if(!is.null(fill)&&length(fill)>0) p <- p + ggplot2::aes(fill=.data[[fill]])
  if(!is.null(facet)&&length(facet)>0) p <- p + ggplot2::facet_wrap(stats::as.formula(paste0("~`",facet,"`")))
  if(nzchar(title)) p <- p + ggplot2::labs(title=title)
  p <- p + switch(theme_name,theme_classic=ggplot2::theme_classic(),theme_bw=ggplot2::theme_bw(),ggplot2::theme_minimal())
  item <- save_plot(p,output_dir,"ggplot_builder");item$title <- if(nzchar(title)) title else "ggplot2 Visualization"
  syntax <- paste0("ggplot2::ggplot(df, ",mappings,") + ",geom_call)
  success_result(syntax,plots=list(item))
}
