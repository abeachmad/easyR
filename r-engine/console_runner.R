args <- commandArgs(trailingOnly=TRUE)
script_dir <- normalizePath(dirname(sub("--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE))), mustWork=FALSE)
source(file.path(script_dir, "formatter.R"))

if(length(args)<2) {
  cat(jsonlite::toJSON(list(status="error",text="",tables=list(),plots=list(),error="Missing dataset and script arguments"),auto_unbox=TRUE,null="null")); quit(status=0)
}
dataset_path <- args[[1]]
script_path <- args[[2]]
result <- tryCatch({
  df <- readRDS(dataset_path)
  code <- paste(readLines(script_path,warn=FALSE),collapse="\n")
  plots_before <- character()
  output <- capture.output(result_value <- eval(parse(text=code),envir=new.env(parent=environment())))
  text_output <- paste(output,collapse="\n")
  if(inherits(result_value,"ggplot") || inherits(result_value,"recordedplot")) {
    plot_dir <- dirname(dataset_path); plot_path <- file.path(plot_dir,"console_plot.png")
    if(inherits(result_value,"ggplot")) ggplot2::ggsave(plot_path,result_value,width=7,height=5,dpi=300)
    plots <- list(list(id="console_plot",title="R Console Plot",path=plot_path))
  } else plots <- list()
  tables <- list()
  if(is.data.frame(result_value)) tables[[1]] <- data_frame_table(result_value,"console_table","R Console Data")
  list(status="success",text=text_output,value=paste(capture.output(print(result_value)),collapse="\n"),tables=tables,plots=plots,rSyntax=code,warnings=list(),error=NULL)
}, error=function(e) list(status="error",text="",tables=list(),plots=list(),rSyntax="",warnings=list(),error=trimws(conditionMessage(e))))
cat(jsonlite::toJSON(result,auto_unbox=TRUE,null="null",na="null",digits=15))
