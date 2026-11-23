run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("ppcor",quietly=TRUE)) return(module_error("ppcor","Partial correlation"))
  x <- variables$x[[1]]; y <- variables$y[[1]]; covs <- as.character(variables$covariates)
  cols <- c(x,y,covs); complete <- stats::complete.cases(df[,cols,drop=FALSE]); fit <- ppcor::pcor(df[complete,cols,drop=FALSE])
  ix <- match(x,cols); iy <- match(y,cols)
  row <- data.frame(variable_x=x,variable_y=y,estimate=fit$estimate[ix,iy],statistic=fit$statistic[ix,iy],p.value=fit$p.value[ix,iy])
  tables <- list(simple_table("partial_correlation","Partial Correlation",row))
  syntax <- paste0("ppcor::pcor(df[, c(",paste(vapply(cols,backtick_name,character(1)),collapse=", "),")])")
  success_result(syntax,tables)
}
