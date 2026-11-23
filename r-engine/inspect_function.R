args <- commandArgs(trailingOnly=TRUE)
if(length(args)<1) stop("Missing package::function name")
name <- args[[1]]
if(!grepl("^[A-Za-z][A-Za-z0-9.]*::[A-Za-z][A-Za-z0-9._]*$",name)) stop("Use package::function format")
parts <- strsplit(name,"::",fixed=TRUE)[[1]]
if(!requireNamespace(parts[[1]],quietly=TRUE)) {
  cat(jsonlite::toJSON(list(status="error",error=paste("Install package:",parts[[1]]),formals=list()),auto_unbox=TRUE,null="null")); quit(status=0)
}
fn <- getExportedValue(parts[[1]],parts[[2]])
values <- formals(fn)
items <- list()
for (id in names(values)) {
  default <- tryCatch({
    value <- values[[id]]
    if (missing(value) || is.null(value)) NULL
    else if (is.symbol(value) || is.call(value)) paste(deparse(value), collapse = "")
    else paste(as.character(value), collapse = "")
  }, error = function(e) NULL)
  items[[length(items) + 1]] <- list(name = id, default = default)
}
cat(jsonlite::toJSON(list(status="success",functionName=name,formals=items),auto_unbox=TRUE,null="null",na="null"))
