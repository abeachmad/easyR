run_module <- function(df, variables, options, output_dir) {
  if (!requireNamespace("car",quietly=TRUE)) return(module_error("car","ANCOVA"))
  dep <- variables$dependent[[1]]; factor_name <- variables$factor[[1]]; covs <- as.character(variables$covariates)
  needed <- c(dep,factor_name,covs); needed <- needed[needed %in% names(df)]
  analysis <- df[stats::complete.cases(df[,needed,drop=FALSE]),needed,drop=FALSE]
  if(nrow(analysis)<3) stop("ANCOVA needs at least 3 complete rows")
  analysis[[factor_name]] <- factor(analysis[[factor_name]])
  formula <- stats::as.formula(paste0("`",dep,"` ~ `",factor_name,"` + ",paste(paste0("`",covs,"`"),collapse=" + ")))
  model <- stats::lm(formula,data=analysis)
  type <- as.numeric(option_value(options,"type",3)); result <- car::Anova(model,type=type)
  rows <- as.data.frame(result); rows$term <- rownames(rows)
  tables <- list(simple_table("ancova_main","ANCOVA",rows))
  plots <- list()
  if (isTRUE(option_value(options,"plotAdjusted",TRUE))) {
    p <- ggplot2::ggplot(analysis,ggplot2::aes(x=.data[[factor_name]],y=stats::predict(model)))+ggplot2::geom_boxplot()+ggplot2::theme_minimal()
    plots[[1]] <- save_plot(p,output_dir,"ancova_adjusted")
  }
  success_result(paste0("car::Anova(lm(`",dep,"` ~ `",factor_name,"` + ",paste(paste0("`",covs,"`"),collapse=" + "),"`, data = df), type = ",type,")"),tables,plots)
}
