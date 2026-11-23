safe_scalar <- function(value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) return(NULL)
  value[[1]]
}

broom_table <- function(df, id, title, footnotes = character()) {
  if (!is.data.frame(df) || nrow(df) == 0) {
    rows <- list()
  } else {
    rows <- lapply(seq_len(nrow(df)), function(i) {
      row <- as.list(df[i, , drop = FALSE])
      lapply(row, safe_scalar)
    })
  }
  list(id = id, title = title, columns = names(df), rows = rows,
       footnotes = as.list(footnotes))
}

data_frame_table <- function(df, id, title, footnotes = character()) {
  broom_table(df, id, title, footnotes)
}

warning_text <- function(condition) {
  trimws(conditionMessage(condition))
}
