run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("psych",quietly=TRUE)) return(module_error("psych","Reliability analysis"))
  items <- as.character(variables$items)
  complete <- stats::complete.cases(df[,items,drop=FALSE]); sample_df <- df[complete,items,drop=FALSE]
  if(nrow(sample_df)<3) stop("Reliability analysis needs at least 3 complete rows")
  fit <- NULL
  capture.output({ fit <- suppressWarnings(psych::alpha(sample_df,check.keys=TRUE)) }, file=NULL, type="output")
  rows <- data.frame(cronbach_alpha=fit$total[[1]],std_alpha=fit$total[[2]],average_r=fit$total[[3]],omega=if(isTRUE(option_value(options,"omega",TRUE)) && requireNamespace("GPArotation",quietly=TRUE)) unname(suppressWarnings(psych::omega(sample_df,plot=FALSE)$omega.tot)) else NA_real_)
  tables <- list(simple_table("reliability_summary","Scale Reliability",rows))
  if(isTRUE(option_value(options,"alphaIfDeleted",TRUE))) tables[[2]] <- simple_table("item_statistics","Item-Total and Alpha-if-Deleted",as.data.frame(fit$alpha.drop))
  success_result(paste0("psych::alpha(df[, c(",paste(vapply(items,backtick_name,character(1)),collapse=", "),")], check.keys = TRUE)"),tables)
}
