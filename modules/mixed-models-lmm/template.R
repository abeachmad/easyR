run_module <- function(df, variables, options, output_dir) {
  if(!requireNamespace("lme4",quietly=TRUE)) return(module_error("lme4","Linear mixed-effects model"))
  dep <- variables$dependent[[1]]; fixed <- as.character(variables$fixed); group <- variables$grouping[[1]]; random_slope <- variables$randomSlope
  re <- paste0("(1",if(!is.null(random_slope)&&length(random_slope)>0) paste0(" + `",random_slope,"`") else ""," | `",group,"`)"); rhs <- paste(paste0("`",fixed,"`",collapse=" + "),re,sep=" + "); formula <- stats::as.formula(paste0("`",dep,"` ~ ",rhs)); method <- as.character(option_value(options,"method","REML")); fit <- lme4::lmer(formula,data=df,REML=method=="REML")
  fixed_rows <- as.data.frame(summary(fit)$coefficients); fixed_rows$term <- rownames(fixed_rows); names(fixed_rows)[1:4]<-c("estimate","std_error","df","statistic"); tables<-list(simple_table("lmm_fixed","Fixed Effects",fixed_rows)); vc <- as.data.frame(lme4::VarCorr(fit)); tables[[2]]<-simple_table("lmm_variance","Random Effects Variance",vc)
  success_result(paste0("lme4::lmer(",deparse(formula),", data = df, REML = ",method=="REML",")"),tables)
}
