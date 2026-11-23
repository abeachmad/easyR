run_module <- function(df, variables, options, output_dir) {
  function_name <- as.character(option_value(options,"function","stats::glm")); argument_json <- as.character(option_value(options,"arguments","{}"))
  if(!grepl("^[A-Za-z][A-Za-z0-9.]*::[A-Za-z][A-Za-z0-9._]*$",function_name)) stop("Function must use package::function format")
  pieces <- strsplit(function_name,"::",fixed=TRUE)[[1]]; package <- pieces[1]; fn_name <- pieces[2]
  if(!requireNamespace(package,quietly=TRUE)) return(module_error(package,function_name))
  fn <- getExportedValue(package,fn_name); args <- jsonlite::fromJSON(argument_json,simplifyVector=FALSE)
  if(!is.list(args)) stop("Arguments must be a JSON object")
  result <- do.call(fn,args); output_text <- capture.output(print(result))
  tables <- list(simple_table("cran_output","CRAN Function Output",data.frame(output=output_text)))
  if(inherits(result,"ggplot")) { item <- save_plot(result,output_dir,"cran_plot");item$title<-function_name;plots<-list(item) } else plots<-list()
  syntax <- paste0("do.call(",function_name," , arguments)")
  success_result(syntax,tables,plots)
}
