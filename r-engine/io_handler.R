normalize_extension <- function(path) {
  tolower(tools::file_ext(path))
}

read_dataset <- function(path) {
  ext <- normalize_extension(path)
  switch(ext,
    csv = read.csv(path, check.names = FALSE, stringsAsFactors = FALSE),
    xlsx = readxl::read_excel(path),
    xls = readxl::read_excel(path),
    sav = haven::read_sav(path),
    dta = haven::read_dta(path),
    rds = readRDS(path),
    stop("Unsupported dataset format: .", ext)
  )
}

column_metadata <- function(df) {
  data.frame(
    name = names(df),
    label = vapply(names(df), function(n) {
      label <- attr(df[[n]], "label", exact = TRUE)
      if (is.null(label) || !nzchar(as.character(label))) n else as.character(label)
    }, character(1)),
    measureType = vapply(df, infer_measure_type, character(1)),
    rClass = vapply(df, r_class_name, character(1)),
    stringsAsFactors = FALSE
  )
}

infer_measure_type <- function(x) {
  if (is.numeric(x)) return("numeric")
  if (is.ordered(x)) return("ordinal")
  "nominal"
}

r_class_name <- function(x) paste(class(x), collapse = "/")

import_dataset <- function(input_path, output_dir) {
  df <- read_dataset(input_path)
  if (!is.data.frame(df)) stop("Imported data is not tabular")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rds_path <- file.path(output_dir, "active_dataset.rds")
  saveRDS(df, rds_path)
  list(status = "success", datasetPath = rds_path,
       metadata = column_metadata(df), rows = nrow(df), error = NULL)
}

update_dataset_rows <- function(dataset_path, rows_json) {
  df <- jsonlite::fromJSON(rows_json, simplifyVector = TRUE)
  if (!is.data.frame(df)) stop("Invalid row data")
  saveRDS(df, dataset_path)
  df
}

edit_dataset_structure <- function(dataset_path, action, row_index, column_name) {
  df <- readRDS(dataset_path)
  if (action == "addRow") df[nrow(df) + 1L, ] <- NA
  if (action == "deleteRow" && !is.null(row_index)) df <- df[-(as.integer(row_index) + 1L), , drop = FALSE]
  if (action == "addColumn") {
    name <- if (is.null(column_name) || !nzchar(column_name)) paste0("V", ncol(df) + 1L) else column_name
    df[[name]] <- NA_real_
  }
  if (action == "deleteColumn" && !is.null(column_name)) df[[column_name]] <- NULL
  saveRDS(df, dataset_path)
  df
}

export_dataset <- function(dataset_path, output_path) {
  df <- readRDS(dataset_path)
  ext <- normalize_extension(output_path)
  if (ext == "csv") utils::write.csv(df, output_path, row.names = FALSE, na = "")
  else if (ext == "xlsx") {
    if (!requireNamespace("writexl", quietly = TRUE)) stop("Package writexl is not installed")
    writexl::write_xlsx(df, output_path)
  } else if (ext == "sav") haven::write_sav(df, output_path)
  else stop("Unsupported export format")
}

save_project <- function(dataset_path, project_path, history_json) {
  df <- readRDS(dataset_path)
  archive <- list(dataset = df, metadata = column_metadata(df),
    history = jsonlite::fromJSON(history_json, simplifyVector = FALSE))
  saveRDS(archive, project_path)
}

open_project <- function(project_path, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  archive <- readRDS(project_path)
  if (!is.data.frame(archive$dataset)) stop("Invalid .ostat project")
  rds_path <- file.path(output_dir, "active_dataset.rds")
  saveRDS(archive$dataset, rds_path)
  df <- readRDS(rds_path)
  list(status = "success", datasetPath = rds_path, metadata = archive$metadata,
       rows = nrow(df), history = archive$history, error = NULL)
}

update_dataset_cell <- function(dataset_path, row_index, column_name, value) {
  df <- readRDS(dataset_path)
  index <- as.integer(row_index) + 1L
  if (index < 1L || index > nrow(df)) stop("Invalid row index")
  if (!column_name %in% names(df)) stop("Invalid column name")
  df[[column_name]][index] <- value
  saveRDS(df, dataset_path)
  df
}
