args <- commandArgs(trailingOnly = TRUE)
script_dir <- normalizePath(dirname(sub("--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))), mustWork = FALSE)
source(file.path(script_dir, "io_handler.R"))

set_label <- function(x, label) { attr(x, "label") <- label; x }

build_dataset <- function(id) {
  set.seed(2026)
  if (id == "iris-anova") {
    df <- iris
    names(df) <- c("Sepal_Length", "Sepal_Width", "Petal_Length", "Petal_Width", "Species")
    df$Species <- factor(df$Species)
    df$Sepal_Length <- set_label(df$Sepal_Length, "Sepal length (cm)")
    df$Sepal_Width <- set_label(df$Sepal_Width, "Sepal width (cm)")
    df$Petal_Length <- set_label(df$Petal_Length, "Petal length (cm)")
    df$Petal_Width <- set_label(df$Petal_Width, "Petal width (cm)")
    df$Species <- set_label(df$Species, "Iris species")
    title <- "Iris Botanical Study"; recommendations <- c("Descriptives", "One-Way ANOVA", "MANOVA", "PCA", "Clustering")
  } else if (id == "mtcars-regression") {
    df <- mtcars
    labels <- c("Miles per US gallon", "Number of cylinders", "Displacement (cu. in.)", "Gross horsepower",
      "Rear axle ratio", "Weight (1000 lb)", "Quarter-mile time", "V/S engine", "Transmission", "Forward gears", "Carburetors")
    for (i in seq_along(labels)) df[[i]] <- set_label(df[[i]], labels[[i]])
    df$am <- factor(df$am, levels = c(0, 1), labels = c("Automatic", "Manual"))
    df$vs <- factor(df$vs, levels = c(0, 1), labels = c("V-shaped", "Straight") )
    df$cyl <- ordered(df$cyl); df$gear <- ordered(df$gear)
    title <- "Motor Trend Car Road Tests"; recommendations <- c("Independent T-Test", "Correlation", "Linear Regression", "Logistic Regression")
  } else if (id == "clinical-survival") {
    time <- round(rexp(180, rate = 1 / 18), 1)
    age <- round(rnorm(180, 58, 10), 1)
    biomarker <- round(rnorm(180, 50, 12), 1)
    treatment <- factor(rep(c("Control", "New Drug"), each = 90))
    status <- rbinom(180, 1, plogis(-0.8 + 0.015 * age - 0.35 * (treatment == "New Drug") + 0.008 * biomarker))
    df <- data.frame(time = time, status = status, treatment = treatment, age = age, biomarker = biomarker)
    df$time <- set_label(df$time, "Follow-up time (months)"); df$status <- set_label(df$status, "Event status (0=Censored, 1=Event)")
    df$treatment <- set_label(df$treatment, "Treatment arm"); df$age <- set_label(df$age, "Age (years)"); df$biomarker <- set_label(df$biomarker, "Biomarker level")
    title <- "Clinical Trial Survival Data"; recommendations <- c("Kaplan-Meier", "Cox Regression", "Chi-Square")
  } else if (id == "psychometrics-irt-dif") {
    n <- 250; gender <- factor(rep(c("Male", "Female"), length.out = n))
    items <- as.data.frame(matrix(rbinom(n * 10, 1, 0.55), nrow = n, ncol = 10))
    names(items) <- paste0("Item_", 1:10)
    for (j in c(4, 7)) {
      prob <- ifelse(gender == "Male", 0.72, 0.38)
      items[[paste0("Item_", j)]] <- rbinom(n, 1, prob)
    }
    likert <- as.data.frame(matrix(sample(1:5, n * 5, replace = TRUE), nrow = n))
    names(likert) <- paste0("Likert_", 1:5)
    for (j in 1:5) likert[[j]] <- set_label(ordered(likert[[j]], levels = 1:5), paste("Likert scale item", j))
    df <- cbind(gender = set_label(gender, "Respondent gender"), items, likert)
    for (j in 1:10) df[[j + 1]] <- set_label(df[[j + 1]], paste("Dichotomous cognitive item", j))
    title <- "Cognitive & Attitude Scale Assessment"; recommendations <- c("Reliability", "EFA", "Item Response Theory", "DIF", "Wright Map")
  } else if (id == "longitudinal-growth") {
    subject_id <- rep(1:120, each = 3); timepoint <- factor(rep(c("Pre", "Mid", "Post"), times = 120), levels = c("Pre", "Mid", "Post"), ordered = TRUE)
    group <- factor(rep(rep(c("A", "B"), each = 60), each = 3))
    trend <- as.numeric(timepoint == "Mid") * 3 + as.numeric(timepoint == "Post") * 6
    score <- round(50 + trend + ifelse(group == "B", 2, 0) + rnorm(360, 0, 5), 1)
    df <- data.frame(subject_id = subject_id, timepoint = timepoint, group = group, score = score)
    df$subject_id <- set_label(df$subject_id, "Student identifier")
    df$timepoint <- set_label(df$timepoint, "Measurement timepoint")
    df$group <- set_label(df$group, "Intervention group")
    df$score <- set_label(df$score, "Outcome score")
    title <- "Student Intervention Longitudinal Study"; recommendations <- c("Paired T-Test", "Repeated Measures ANOVA", "Linear Mixed Models")
  } else stop("Unknown sample dataset: ", id)
  list(df = df, title = title, recommendations = recommendations)
}

tryCatch({
  if (length(args) < 2) stop("Missing sample ID or output directory")
  generated <- build_dataset(args[[1]])
  dir.create(args[[2]], recursive = TRUE, showWarnings = FALSE)
  rds_path <- file.path(args[[2]], "active_dataset.rds")
  saveRDS(generated$df, rds_path)
  preview <- jsonlite::fromJSON(jsonlite::toJSON(utils::head(generated$df, 100), auto_unbox = TRUE, null = "null", na = "null"), simplifyVector = FALSE)
  result <- list(status = "success", datasetPath = rds_path, title = generated$title,
    recommendations = generated$recommendations, metadata = column_metadata(generated$df),
    rows = nrow(generated$df), columns = ncol(generated$df), preview = preview, error = NULL)
  cat(jsonlite::toJSON(result, auto_unbox = TRUE, null = "null", na = "null", digits = 15))
}, error = function(e) {
  cat(jsonlite::toJSON(list(status = "error", datasetPath = NULL, title = NULL,
    recommendations = list(), metadata = list(), rows = 0, columns = 0, preview = list(),
    error = trimws(conditionMessage(e))), auto_unbox = TRUE, null = "null"))
})
