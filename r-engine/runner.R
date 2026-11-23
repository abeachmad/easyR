args <- commandArgs(trailingOnly = TRUE)
script_dir <- normalizePath(dirname(sub("--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))), mustWork = FALSE)
source(file.path(script_dir, "io_handler.R"))
source(file.path(script_dir, "formatter.R"))
source(file.path(script_dir, "module_helpers.R"))

warning_messages <- character()
base_result <- function(status, error = NULL) {
  list(status = status, rSyntax = "", tables = list(), plots = list(),
       warnings = warning_messages, error = error)
}

finalize <- function(result) {
  cat(jsonlite::toJSON(result, auto_unbox = TRUE, null = "null", na = "null", digits = 15))
}

if (length(args) < 1) {
  finalize(base_result("error", "Missing request.json path"))
  quit(status = 0)
}

result <- withCallingHandlers(
  tryCatch({
    request <- jsonlite::fromJSON(args[[1]], simplifyVector = FALSE)
    df <- readRDS(request$datasetPath)
    output_dir <- request$outputDir
    if (is.null(output_dir) || !nzchar(output_dir)) output_dir <- dirname(request$datasetPath)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    module_id <- request$moduleId
    modules_dir <- Sys.getenv("OPENSTAT_MODULES_DIR", unset = file.path(dirname(script_dir), "modules"))
    module_dir <- file.path(modules_dir, module_id)
    template_path <- file.path(module_dir, "template.R")
    if (!file.exists(template_path)) stop("Unknown module: ", module_id)

    source(template_path)
    run_module(df, request$variables, request$options, output_dir)
  }, error = function(e) {
    base_result("error", trimws(conditionMessage(e)))
  }),
  warning = function(w) {
    warning_messages <<- c(warning_messages, trimws(conditionMessage(w)))
  }
)

if (!isTRUE(result$status == "success")) {
  if (is.null(result$error)) result$error <- "Analysis failed"
}
finalize(result)
