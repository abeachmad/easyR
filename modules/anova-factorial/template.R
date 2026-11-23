run_module <- function(df, variables, options, output_dir) {
  if (!requireNamespace("car",quietly=TRUE)) return(module_error("car","Factorial ANOVA"))
  dep <- variables$dependent[[1]]; f1 <- variables$factor1[[1]]; f2 <- variables$factor2[[1]]
  needed <- c(dep,f1,f2); analysis <- df[stats::complete.cases(df[,needed,drop=FALSE]),needed,drop=FALSE]
  analysis[[f1]] <- factor(analysis[[f1]]); analysis[[f2]] <- factor(analysis[[f2]])
  if(nlevels(analysis[[f1]])<2 || nlevels(analysis[[f2]])<2) stop("Factorial ANOVA requires at least 2 levels per factor")
  formula <- stats::as.formula(paste0("`",dep,"` ~ `",f1,"` * `",f2,"`"))
  model <- stats::lm(formula,data=analysis)
  type <- as.numeric(option_value(options,"type",3)); anova <- stats::anova(model)
  rows <- as.data.frame(anova); rows$term <- rownames(rows)
  tables <- list(simple_table("factorial_anova","Factorial ANOVA",rows))
  plots <- list()
  if(isTRUE(option_value(options,"plotInteraction",TRUE))) {
    p <- ggplot2::ggplot(analysis,ggplot2::aes(x=.data[[f1]],y=.data[[dep]],color=.data[[f2]],group=.data[[f2]]))+ggplot2::stat_summary(fun="mean",geom="line")+ggplot2::stat_summary(fun="mean",geom="point")+ggplot2::theme_minimal()
    plots[[1]] <- save_plot(p,output_dir,"factorial_interaction")
  }
  success_result(paste0("car::Anova(lm(`",dep,"` ~ `",f1,"` * `",f2,"`, data = df), type = ",type,")"),tables,plots)
}
