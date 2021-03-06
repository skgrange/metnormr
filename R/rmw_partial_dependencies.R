#' Function to calculate partial dependencies after training with 
#' \strong{rmweather}. 
#' 
#' \code{rmw_plot_partial_dependencies} is rather slow. 
#' 
#' @param model A ranger model object from \code{\link{rmw_train_model}}. 
#' 
#' @param df Input data frame after preparation with 
#' \code{\link{rmw_prepare_data}}.
#' 
#' @param variable Vector of variables to calculate partial dependencies for. 
#' 
#' @param training_only Should only the training set be used for prediction? The
#' default is \code{TRUE}. 
#' 
#' @param n_cores Number of CPU cores to use for the model calculation. The 
#' default is system's total minus one.
#' 
#' @param verbose Should the function give messages? 
#' 
#' @return Tibble. 
#' 
#' @author Stuart K. Grange
#' 
#' @examples 
#' 
#' \donttest{
#' 
#' # Load packages
#' library(dplyr)
#' # Ranger package needs to be loaded
#' library(ranger)
#' 
#' # Prepare example data
#' data_london_prepared <- data_london %>% 
#'   filter(variable == "no2") %>% 
#'   rmw_prepare_data()
#' 
#' # Calculate partial dependencies for wind speed
#' data_partial <- rmw_partial_dependencies(
#'   model = model_london, 
#'   df = data_london_prepared, 
#'   variable = "ws", 
#'   verbose = TRUE
#' )
#' 
#' # Calculate partial dependencies for all independent variables used in model
#' data_partial <- rmw_partial_dependencies(
#'   model = model_london, 
#'   df = data_london_prepared, 
#'   variable = NA, 
#'   verbose = TRUE
#' )
#' 
#' }
#' 
#' @export
rmw_partial_dependencies <- function(model, df, variable, training_only = TRUE, 
                                     n_cores = NA, verbose = FALSE) {
  
  # Check, predict is a generic function and needs to be loaded
  if (!"package:ranger" %in% search()) {
    stop("The ranger package is not loaded.", call. = FALSE)
  }
    
  # Check inputs
  df <- rmw_check_data(df, prepared = TRUE)
  stopifnot(class(model) == "ranger")
  
  # Default logic for cpu cores
  n_cores <- as.integer(n_cores)
  n_cores <- if_else(is.na(n_cores), n_cores_default(), n_cores)
  
  # Predict all variables if not given
  if (is.na(variable[1])) variable <- model$forest$independent.variable.names
  
  # Message to user
  if (verbose) {
    message(
      str_date_formatted(), ": Predicting `", length(variable), "` variable(s)..."
    )
  }
  
  df_predict <- purrr::map_dfr(
    variable, 
    ~rmw_partial_dependencies_worker(
      model = model,
      df = df, 
      variable = .x,
      training_only = training_only,
      n_cores = n_cores
    )
  )
  
  # To tibble
  df_predict <- as_tibble(df_predict)
  
  return(df_predict)
  
}


rmw_partial_dependencies_worker <- function(model, df, variable, training_only, 
                                            n_cores) {
  
  # Filter only to training set
  if (training_only) {
    df <- filter(df, set == "training")
  }
  
  # Predict
  df_predict <- pdp::partial(
    model,
    pred.var = variable,
    train = df,
    num.threads = n_cores
  )
  
  # Alter names and add variable
  df_predict <- df_predict %>% 
    purrr::set_names(c("value", "partial_dependency")) %>% 
    as_tibble() %>% 
    mutate(variable = !!variable) %>% 
    relocate(variable, 
             value, 
             partial_dependency)
  
  # Catch factors, usually weekday
  if ("factor" %in% class(df_predict$value)) {
    df_predict$value <- as.integer(df_predict$value)
  }
  
  return(df_predict)
  
}
