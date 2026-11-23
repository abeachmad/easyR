run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("dplyr",quietly=TRUE)) return(module_error("dplyr","Data wrangling"))
  operation <- as.character(option_value(options,"operation","filter")); expression <- as.character(option_value(options,"expression","value > 0")); new_name <- as.character(option_value(options,"newName","new_variable"))
  original <- df
  if(operation=="filter") { syntax <- paste0("df <- dplyr::filter(df, ",expression,")"); df <- dplyr::filter(df,eval(parse(text=expression))) }
  else if(operation=="compute") { syntax <- paste0("df <- dplyr::mutate(df, `",gsub("`","",new_name),"` = ",expression,")"); df <- dplyr::mutate(df,!!rlang::sym(new_name) := eval(parse(text=expression))) }
  else if(operation=="recode") { names <- as.character(variables$variables); if(length(names)==0) stop("Select a variable to recode"); name <- names[1]; syntax <- paste0("df <- dplyr::mutate(df, `",name,"` = factor(`",name,"`)"); df <- dplyr::mutate(df,!!rlang::sym(name) := factor(!!rlang::sym(name))) }
  else { names <- as.character(variables$variables); if(length(names)==0) stop("Select a variable to change"); name <- names[1]; syntax <- paste0("df <- dplyr::mutate(df, `",name,"` = as.character(`",name,"`)"); df <- dplyr::mutate(df,!!rlang::sym(name) := as.character(!!rlang::sym(name))) }
  saveRDS(df,file.path(output_dir,"active_dataset.rds"))
  summary_rows <- data.frame(operation=operation,rows_before=nrow(original),rows_after=nrow(df),columns=ncol(df),syntax=syntax)
  success_result(syntax,list(simple_table("wrangling_summary","Data Wrangling Summary",summary_rows)))
}
