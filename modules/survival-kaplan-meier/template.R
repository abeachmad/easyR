run_module <- function(df, variables, options, output_dir) {
  if (!requireNamespace("survival", quietly=TRUE)) return(module_error("survival", "Survival analysis"))
  time_name <- variables$time[[1]]
  status_name <- variables$status[[1]]
  group_name <- variables$group
  if (length(group_name)>0) group_name <- group_name[[1]]
  complete_names <- c(time_name,status_name)
  if (!is.null(group_name) && nzchar(group_name)) complete_names <- c(complete_names, group_name)
  complete <- stats::complete.cases(df[, unique(complete_names), drop=FALSE])
  analysis <- df[complete, , drop=FALSE]
  time <- analysis[[time_name]]
  status <- analysis[[status_name]]
  response <- survival::Surv(time, status)
  fit <- if (!is.null(group_name) && nzchar(group_name)) {
    survival::survfit(response ~ analysis[[group_name]])
  } else {
    survival::survfit(response ~ 1)
  }
  fit_summary <- summary(fit, times=sort(unique(time)))
  km <- data.frame(time=fit_summary$time,n.risk=fit_summary$n.risk,n.event=fit_summary$n.event,
                   survival=fit_summary$surv,conf.low=fit_summary$lower,conf.high=fit_summary$upper)
  tables <- list(simple_table("kaplan_meier", "Kaplan-Meier Estimates", km))
  if (isTRUE(option_value(options,"logrank",TRUE)) && !is.null(group_name) && nzchar(group_name)) {
    lr <- survival::survdiff(response ~ analysis[[group_name]])
    tables[[2]] <- simple_table("logrank", "Log-Rank Test",
      data.frame(statistic=unname(lr$chisq),df=length(lr$n)-1,
                 p.value=stats::pchisq(lr$chisq,length(lr$n)-1,lower.tail=FALSE)))
  }
  p <- ggplot2::qplot(seq_along(fit_summary$surv),fit_summary$surv,geom="line")+
    ggplot2::labs(x="Time",y="Survival")+ggplot2::theme_minimal()
  item <- save_plot(p, output_dir, "kaplan_meier_curve")
  item$title <- "Kaplan-Meier Curve"
  success_result(paste0("survival::survfit(survival::Surv(df[[",backtick_name(time_name),"]], df[[",backtick_name(status_name),"]]) ~ 1)"),tables,list(item))
}
