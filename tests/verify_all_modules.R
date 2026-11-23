set.seed(20261123)
args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
root <- if (length(script_arg)) normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), "..")) else normalizePath(getwd())
runner <- file.path(root, "r-engine", "runner.R")
modules_dir <- file.path(root, "modules")
work_dir <- file.path(tempdir(), "openstat_module_audit")
unlink(work_dir, recursive = TRUE, force = TRUE)
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)

n <- 120
subject_id <- sprintf("Subj-%03d", seq_len(n))
group <- rep(c("Kontrol", "Perlakuan"), length.out = n)
second_factor <- rep(c("Pagi", "Siang"), length.out = n)
pre <- 50 + 0.35 * seq_len(n) + rnorm(n, 0, 4)
post <- pre + rnorm(n, 3, 3)
control <- 40 + rnorm(n, 0, 5)
latent_a <- 2 + 0.7 * pre / 50 + rnorm(n, 0, 0.8)
latent_b <- 1.5 + 0.5 * control / 40 + rnorm(n, 0, 0.8)
survival_time <- round(rexp(n, rate = 1 / 18) + 1, 1)
event <- as.integer(runif(n) < 0.72)
series <- round(100 + 0.18 * seq_len(n) + 5 * sin(seq_len(n) / 6) + rnorm(n, 0, 1.2), 2)
effect <- 0.12 + seq_len(n) * 0.002 + rnorm(n, 0, 0.05)
std_error <- 0.08 + abs(rnorm(n, 0.03, 0.015))
long_subject <- rep(sprintf("Subj-%03d", seq_len(n / 3)), each = 3)
long_time <- rep(c(1, 2, 3), n / 3)
long_y <- 45 + 2 * long_time + rnorm(n, 0, 4)
df <- data.frame(
  `Skor Pre-Test (2026)` = pre,
  `Skor Post-Test [A]` = post,
  `Kontrol (Nilai)` = control,
  `Grup & Kategori` = group,
  `Faktor B / Kondisi` = second_factor,
  `Subject ID` = subject_id,
  `Biner 0/1` = event,
  `Survival Time` = survival_time,
  `Event Status` = event,
  `Waktu (Bulan)` = seq_len(n),
  `Time Series %` = series,
  `Latent A` = latent_a,
  `Latent B` = latent_b,
  `Effect Size` = effect,
  `Std. Error` = std_error,
  `Outcome %` = 20 + 0.02 * seq_len(n) + rnorm(n),
  `Repeated T1` = pre,
  `Repeated T2` = post,
  `Repeated T3` = control,
  `Time` = long_time,
  `Longitudinal Subject` = long_subject,
  `Longitudinal Outcome` = long_y,
  check.names = FALSE
)
for (nm in names(df)[vapply(df, is.numeric, logical(1))]) {
  idx <- sample(seq_len(n), 8)
  df[idx, nm] <- NA
}
idx_cat <- sample(seq_len(n), 10)
df$`Grup & Kategori`[idx_cat] <- NA
df$`Faktor B / Kondisi`[sample(seq_len(n), 8)] <- NA
df$`Biner 0/1`[sample(seq_len(n), 6)] <- NA

# Add a genuinely character-typed categorical variable and keep it raw.
df$`Grup & Kategori` <- as.character(df$`Grup & Kategori`)
# Restore clean advanced-model vectors where missing values would invalidate the analysis.
df$`Survival Time` <- survival_time
df$`Event Status` <- event
df$`Time Series %` <- series
df$`Effect Size` <- effect
df$`Std. Error` <- std_error
dataset_path <- file.path(work_dir, "dirty_dataset.rds")
saveRDS(df, dataset_path)

numeric_by_slot <- list(dependent="Skor Pre-Test (2026)", outcome="Skor Pre-Test (2026)", y="Skor Post-Test [A]",
  pair1="Repeated T1", pair2="Repeated T2", measures=c("Repeated T1","Repeated T2","Repeated T3"),
  variables=c("Skor Pre-Test (2026)","Skor Post-Test [A]","Kontrol (Nilai)","Latent A","Latent B"),
  items=c("Latent A","Latent B","Repeated T1","Repeated T2"), x="Skor Pre-Test (2026)",
  covariates=c("Kontrol (Nilai)","Waktu (Bulan)"), predictors=c("Kontrol (Nilai)","Latent A"),
  time="Waktu (Bulan)", dependent_series="Time Series %", effect="Effect Size", se="Std. Error")
nominal_by_slot <- list(grouping="Grup & Kategori", factor="Grup & Kategori", factor1="Grup & Kategori",
  factor2="Faktor B / Kondisi", row="Grup & Kategori", column="Faktor B / Kondisi", categorical="Grup & Kategori",
  color="Grup & Kategori", fill="Grup & Kategori", facet="Faktor B / Kondisi", blocks="Subject ID",
  id="Subject ID", status="Event Status", group="Grup & Kategori")

module_dirs <- sort(list.dirs(modules_dir, recursive = FALSE, full.names = FALSE))
waves <- c("descriptives","ttest-independent","ttest-onesample","ttest-paired","anova-oneway","anova-factorial","anova-repeated","correlation-matrix","correlation-partial","crosstabs","frequencies","nonparam-binomial","nonparam-kruskal","nonparam-friedman","ttest-independent","regression-linear","regression-logistic","regression-multinomial","pca","efa","clustering","reliability-analysis","cran-universal-wrapper","mixed-models-lmm","sem-path","survival-cox","survival-kaplan-meier","timeseries-arima","meta-analysis","ggplot-builder","data-wrangling","ancova")
results <- list()
cat(sprintf("Auditing %d modules\n", length(module_dirs)))
for (module_id in module_dirs) {
  schema_path <- file.path(modules_dir, module_id, "schema.json")
  schema <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)
  variables <- list()
  for (slot in schema$variableSlots) {
    value <- NULL
    if (!is.null(numeric_by_slot[[slot$id]])) value <- numeric_by_slot[[slot$id]]
    if (!is.null(nominal_by_slot[[slot$id]])) value <- nominal_by_slot[[slot$id]]
    if (slot$id == "fixed") value <- c("Skor Pre-Test (2026)","Kontrol (Nilai)")
    if (slot$id == "grouping") value <- "Grup & Kategori"
    if (slot$id == "randomSlope") value <- "Waktu (Bulan)"
    if (slot$id == "dependent" && module_id == "timeseries-arima") value <- "Time Series %"
    if (slot$id == "dependent" && module_id == "survival-cox") value <- "Survival Time"
    if (slot$id == "dependent" && module_id == "survival-kaplan-meier") value <- "Survival Time"
    if (!is.null(value) && isTRUE(slot$multiple == FALSE)) value <- value[[1]]
    if (!is.null(value)) variables[[slot$id]] <- value
  }
  if (module_id == "regression-logistic") {
    variables$dependent <- "Biner 0/1"
    variables$predictors <- c("Kontrol (Nilai)", "Latent A")
  }
  if (module_id %in% c("survival-cox", "survival-kaplan-meier")) {
    variables$time <- "Survival Time"
    variables$status <- "Event Status"
  }
  options <- list()
  for (opt in schema$options) options[[opt$id]] <- opt$default
  if (module_id == "cran-universal-wrapper") options <- list(`function`="base::mean", arguments="{\"x\":[1,2,3,4]}")
  if (module_id == "sem-path") options$lavaanSyntax <- "latent =~ `Latent A` + `Latent B`"
  if (module_id == "data-wrangling") options <- list(operation="filter", expression="`Skor Pre-Test (2026)` > 0", newName="audit_result")
  if (module_id %in% c("item-response-theory", "psychometrics-dif", "psychometrics-wright-map")) {
    variables$items <- c("Latent A", "Latent B", "Repeated T1", "Repeated T2")
  }
  if (module_id == "psychometrics-dif") variables$grouping <- "Grup & Kategori"
  if (module_id == "ggplot-builder") options <- list(x="Skor Pre-Test (2026)", y="Skor Post-Test [A]", geom="point", theme="theme_minimal", title="Dirty Dataset Audit")
  output_dir <- file.path(work_dir, module_id)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  request <- list(datasetPath=dataset_path,moduleId=module_id,variables=variables,options=options,outputDir=output_dir)
  request_path <- file.path(work_dir, paste0(module_id, "-request.json"))
  jsonlite::write_json(request, request_path, auto_unbox = TRUE, null = "null")
  stdout_text <- tempfile(); stderr_text <- tempfile()
  status_code <- suppressWarnings(system2("Rscript", c("--vanilla", runner, shQuote(request_path)), stdout=stdout_text, stderr=stderr_text, wait=TRUE))
  raw <- paste(readLines(stdout_text, warn=FALSE), collapse="")
  parsed <- tryCatch(jsonlite::fromJSON(raw, simplifyVector=FALSE), error=function(e) NULL)
  label <- if (is.null(parsed)) "INVALID_JSON" else parsed$status
  detail <- if (is.null(parsed)) raw else if (!is.null(parsed$error)) parsed$error else ""
  optional <- !is.null(parsed) && grepl("Missing optional R package", detail, fixed=TRUE)
  pass <- identical(label,"success") || optional
  suffix <- if (nzchar(detail) && !identical(label,"success")) paste0(" - ",detail) else ""
  cat(sprintf("[%s] %s%s\n", if(pass) "PASS" else "FAIL", module_id, suffix))
  results[[module_id]] <- list(status=label, pass=pass, detail=detail)
}
failed <- names(results)[!vapply(results, function(x) isTRUE(x$pass), logical(1))]
optional <- names(results)[vapply(results, function(x) grepl("Missing optional R package", x$detail, fixed=TRUE), logical(1))]
cat(sprintf("\nSUMMARY success=%d optional_error=%d failed=%d total=%d\n", sum(vapply(results,function(x) identical(x$status,"success"),logical(1))),length(optional),length(failed),length(results)))
if(length(failed)) { cat("FAILURES:\n"); cat(paste(failed, collapse="\n"), "\n") }
if(length(optional)) { cat("OPTIONAL PACKAGES:\n"); cat(paste(optional, collapse="\n"), "\n") }
quit(status=if(length(failed)) 1 else 0)
