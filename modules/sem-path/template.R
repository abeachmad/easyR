run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("lavaan",quietly=TRUE)) return(module_error("lavaan","Structural equation modeling"))
  syntax <- as.character(option_value(options,"lavaanSyntax","latent =~ x1 + x2 + x3"))
  model_type <- as.character(option_value(options,"modelType","cfa")); analysis <- df
  names_df <- names(analysis)
  for (name in names_df) {
    safe <- make.names(name, unique=FALSE)
    names(analysis)[names(analysis)==name] <- safe
    syntax <- gsub(paste0("`",name,"`"),safe,syntax,fixed=TRUE)
    syntax <- gsub(name,safe,syntax,fixed=TRUE)
  }
  if(!grepl("=~|~",syntax,fixed=FALSE)) stop("lavaan model syntax must contain an operator such as =~ or ~")
  fit <- if(model_type=="sem") lavaan::sem(syntax,data=analysis) else lavaan::cfa(syntax,data=analysis)
  indices <- lavaan::fitMeasures(fit,c("cfi","tli","rmsea","srmr","aic","bic"))
  rows <- data.frame(index=names(indices),value=as.numeric(indices)); tables <- list(simple_table("sem_fit","SEM/CFA Fit Indices",rows),simple_table("sem_parameters","Parameter Estimates",as.data.frame(lavaan::parameterEstimates(fit))))
  success_result(paste0("lavaan::",model_type,"('",syntax,"', data = df)"),tables)
}
