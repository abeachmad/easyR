run_module <- function(df, variables, options, output_dir) {
  dep <- variables$dependent[[1]]; horizon <- as.integer(option_value(options,"horizon",12)); frequency <- as.integer(option_value(options,"frequency",1)); values <- df[[dep]][!is.na(df[[dep]])]; if(length(values)<3) stop("ARIMA needs at least 3 non-missing observations"); series <- stats::ts(values,frequency=frequency)
  tables <- list(); if(isTRUE(option_value(options,"adf",TRUE))) { if(!requireNamespace("tseries",quietly=TRUE)) return(module_error("tseries","ADF test")); adf <- tseries::adf.test(series); tables[[1]] <- simple_table("adf_test","ADF Stationarity Test",data.frame(statistic=unname(adf$statistic),p.value=adf$p.value)) }
  if(!requireNamespace("forecast",quietly=TRUE)) return(module_error("forecast","ARIMA forecasting")); fit <- forecast::auto.arima(series); fc <- forecast::forecast(fit,h=horizon)
  rows <- data.frame(point=as.numeric(fit$fitted),residual=as.numeric(stats::residuals(fit))); tables[[length(tables)+1]] <- simple_table("arima_model","ARIMA Model Residual Summary",data.frame(arima=as.character(fit),aic=fit$aic,bic=fit$bic,mean_residual=mean(rows$residual,na.rm=TRUE)))
  plot_df <- data.frame(index=seq_along(fc$mean),forecast=as.numeric(fc$mean),low=as.numeric(fc$lower[,2]),high=as.numeric(fc$upper[,2]))
  p<-ggplot2::ggplot(plot_df,ggplot2::aes(index,forecast,ymin=low,ymax=high))+ggplot2::geom_ribbon(alpha=.2)+ggplot2::geom_line()+ggplot2::theme_minimal();item<-save_plot(p,output_dir,"arima_forecast");item$title<-paste("ARIMA Forecast:",horizon,"Periods")
  success_result(paste0("forecast::forecast(forecast::auto.arima(ts(df[[",backtick_name(dep),"]], frequency = ",frequency,")), h = ",horizon,")"),tables,list(item))
}
