#' Squash the global variable notes when building a package. 
#' 
if (getRversion() >= "2.15.1") {
  
  # What variables are causing issues?
  variables <- c(
    ".", "value_predict", "set", "importance", "variable", "value", 
    "partial_dependency", "rowid", "se", "resampled_set", "observations", 
    "model", "predictions", "COE", "MB", "NMB", "RMSE", "default",
    "normalised_root_mean_squared_error", "r", "r_squared", 
    "root_mean_squared_error", "partial_dependencies"
  )
  
  # Squash the notes
  utils::globalVariables(variables)
  
}
