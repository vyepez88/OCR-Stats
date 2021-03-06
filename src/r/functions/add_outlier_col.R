### Adds 2 outliers columns:
# is.outw = T/F depending if the sample is an outlier at the well level (and NAs)
# is.out = T/F depending if the sample is an outlier at the single point level (and well level)
## Input:
# DT: table with OCR measurements. Needs the following columns: OCR, time, well, group1, group2
# Out_co: number of median absolute deviations from the median a well point is allowed to be in order not to be outlier
# Out_cop: number of median absolute deviations from the median a single point is allowed to be in order not to be outlier

# author: vyepez

add_outlier_col = function(DT, Out_co = 5, Out_cop = 7, group1 = "cell_culture", group2 = "Fibroblast_id", y = 'OCR'){
  
  DP = copy(DT)
  # Add outlier info if not present
  if(!"is.outw" %in% colnames(DP)) DP[, is.outw := F]
  if(!"is.out" %in% colnames(DP)) DP[, is.out := F]
    
  ### Detect outliers at well level
  DP[, aux := paste(get(group1), well)]
  n_outw = numeric()
  iter = 1
  keep = T
  while(keep){   
    x_lr_ao = fit_function(Method = "LR_ao", DT = DP[is.outw == F], Out_co = Out_co, Out_cop = Out_cop,
                           group1 = group1, group2 = group2, y = y)
    x_lr_ao_fitted = x_lr_ao$fitted
    x_out = unique(x_lr_ao_fitted[is.outw == T, c(group1, "well", "is.outw"), with = F])
    n_outw[iter] = nrow(x_out)   # Number of outliers found
    if(n_outw[iter] == 0) keep = F    # Stop when no more outliers are found
    print(paste(n_outw[iter], " well outliers found on the", iter, "iteration"))
    
    x_out[, aux := paste(get(group1), well)]
    DP[aux %in% x_out$aux, is.outw := T]
    
    iter = iter + 1
  }
  DP[, aux := NULL]
  
  p = sum(n_outw) / (sum(x_lr_ao_fitted[time == 1, .N, by = get(group1)]$N)+sum(n_outw))
  print(paste0(round(p*100, 2), "% well outliers found in total."))
  
  ### Detect outliers at single point level
  DP[, is.out := is.outw]
  DP[, aux := paste(get(group1), well, time)]
  
  n_out = numeric()
  iter = 1
  keep = T
  while(keep){
    x_lr_ao = fit_function(Method = "LR_ao", DT = DP[is.out == F], Out_co = Out_co, Out_cop = Out_cop,
                           group1 = group1, group2 = group2, y = y)
    x_lr_ao_fitted = x_lr_ao$fitted
    x_out = unique(x_lr_ao_fitted[is.out == T, c(group1, "time", "well", "is.out"), with = F])
    n_out[iter] = nrow(x_out)   # Number of outliers found
    if(n_out[iter] == 0) keep = F    # Stop when no more outliers are found
    print(paste(n_out[iter], "single point outliers found on the", iter, "iteration"))
    
    x_out[, aux := paste(get(group1), well, time)]
    DP[aux %in% x_out$aux, is.out := T]
    
    iter = iter + 1
  }
  DP[, aux := NULL]
  
  p = sum(n_out) / (nrow(x_lr_ao_fitted) + sum(n_out))
  print(paste0(round(p*100, 2), "% single point outliers found in total."))
  
  return(DP)
}

