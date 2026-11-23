module_error <- function(package_name, function_name = NULL) {
  instruction <- paste0("install.packages('", package_name, "')")
  detail <- if (is.null(function_name)) instruction else paste(function_name, "requires", instruction)
  list(status = "error", rSyntax = "", tables = list(), plots = list(),
       warnings = list(), error = paste("Missing optional R package:", detail))
}

required_vars <- function(df, variables, names = c("dependent")) {
  values <- unlist(lapply(names, function(name) {
    value <- variables[[name]]
    if (is.null(value)) character() else as.character(value)
  }), use.names = FALSE)
  missing <- values[!values %in% names(df)]
  if (length(missing) > 0) stop("Selected variable not found: ", paste(missing, collapse = ", "))
  values
}

option_value <- function(options, id, default) {
  value <- options[[id]]
  if (is.null(value)) default else value
}

backtick_name <- function(name) paste0("`", gsub("`", "\\`", name, fixed = TRUE), "`")

simple_table <- function(id, title, df, footnotes = character()) {
  data_frame_table(df, id, title, footnotes)
}

save_plot <- function(plot, output_dir, id) {
  path <- file.path(output_dir, paste0(id, ".png"))
  ggplot2::ggsave(path, plot, width = 7, height = 5, dpi = 300)
  list(id = id, title = id, path = path)
}

success_result <- function(r_syntax, tables = list(), plots = list(), warnings = character()) {
  list(status = "success", rSyntax = r_syntax, tables = tables, plots = plots,
       warnings = as.list(warnings), error = NULL)
}
