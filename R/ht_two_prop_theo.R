#' Hypothesis testing for two proportions, using CLT-based Z-interval
#' 
#' Helper for the `inference()` function
#' 
#' @param y Response variable, can be numerical or categorical
#' @param x Explanatory variable, categorical (optional)
#' @param success which level of the categorical variable to call "success", 
#' i.e. do inference on
#' @param null null value for a hypothesis test
#' @param alternative direction of the alternative hypothesis; "less","greater", 
#' or "twosided"
#' @param y_name Name of response variable as a character string (passed 
#' from inference function)
#' @param x_name Name of explanatory variable as a character string (passed 
#' from inference function)
#' @param show_var_types print variable types, set to verbose by default
#' @param show_summ_stats print summary stats, set to verbose by default
#' @param show_eda_plot print EDA plot, set to verbose by default
#' @param show_inf_plot print inference plot, set to verbose by default
#' @param show_res print results, set to verbose by default

ht_two_prop_theo <- function(y, x, success, null, alternative,
                             y_name, x_name, 
                             show_var_types, show_summ_stats, show_res,
                             show_eda_plot, show_inf_plot){
  
  # calculate n1 and n2
  ns <- by(y, x, length)
  n1 <- as.numeric(ns[1])
  n2 <- as.numeric(ns[2])
  
  # calculate p-hat1 and p-hat2
  suc1 <- sum(y[x == levels(x)[1]] == success)
  suc2 <- sum(y[x == levels(x)[2]] == success)
  p_hat1 <- suc1 / n1
  p_hat2 <- suc2 / n2
  
  # calculate difference in p-hats
  p_hat_diff <- p_hat1 - p_hat2
  
  # calculate pooled proportion
  suc_tot <- suc1 + suc2
  n_tot <- n1 + n2
  p_pool <- suc_tot / n_tot

  # calculate SE
  se <- sqrt((p_pool * (1 - p_pool) / n1) + (p_pool * (1 - p_pool) / n2))
  
  # calculate z
  z <- (p_hat_diff - null) / se
  
  # shading cutoffs
  if(alternative == "greater"){ 
    x_min <- p_hat_diff
    x_max <- Inf 
    }
  if(alternative == "less"){ 
    x_min <- -Inf
    x_max <- p_hat_diff
    }
  if(alternative == "twosided"){
    if(p_hat_diff >= null){
      x_min <- c(null - (p_hat_diff - null), p_hat_diff)
      x_max <- c(-Inf, Inf)
    }
    if(p_hat_diff <= null){
      x_min <- c(p_hat_diff, null + (null - p_hat_diff))
      x_max <- c(-Inf, Inf)
    }    
  }
  
  # calculate p-value
  if(alternative == "greater"){ p_value <- pnorm(z, lower.tail = FALSE) }
  if(alternative == "less"){ p_value <- pnorm(z, lower.tail = TRUE) }
  if(alternative == "twosided"){
    p_value <- 2 * pnorm(abs(z), lower.tail = FALSE)
  }
  
  # print variable types
  if(show_var_types == TRUE){
    n_x_levels <- length(levels(x))
    n_y_levels <- length(levels(y))
    cat(paste0("Response variable: categorical (", n_x_levels, " levels, success: ", success, ")\n"))
    cat(paste0("Explanatory variable: categorical (", n_y_levels, " levels) \n"))
  }
  
  # print summary statistics
  if(show_summ_stats == TRUE){
    gr1 <- levels(x)[1]
    gr2 <- levels(x)[2]
    cat(paste0("n_", gr1, " = ", n1, ", p_hat_", gr1, " = ", round(p_hat1, 4), "\n"))
    cat(paste0("n_", gr2, " = ", n2, ", p_hat_", gr2, " = ", round(p_hat2, 4), "\n"))
  }
  
  # print results
  if(show_res == TRUE){
    if(alternative == "greater"){
      alt_sign <- ">"
    } else if(alternative == "less"){
      alt_sign <- "<"
    } else {
      alt_sign <- "!="
    }
    cat(paste0("H0: p_", gr1, " =  p_", gr2, "\n"))
    cat(paste0("HA: p_", gr1, " ", alt_sign, " p_", gr2, "\n"))
    cat(paste0("z = ", round(z, 4), "\n"))
    p_val_to_print <- ifelse(round(p_value, 4) == 0, "< 0.0001", round(p_value, 4))
    cat(paste0("p_value = ", p_val_to_print))
  }

  # eda_plot
  d_eda <- data.frame(y = y, x = x)
  
  if(which(levels(y) == success) == 1){ 
    fill_values = c("#1FBEC3", "#8FDEE1") 
  } else {
      fill_values = c("#8FDEE1", "#1FBEC3") 
      }
  
  eda_plot <- ggplot2::ggplot(data = d_eda, ggplot2::aes(x = x, fill = y), environment = environment()) +
    ggplot2::geom_bar(position = "fill") +
    ggplot2::scale_fill_manual(values = fill_values) +
    ggplot2::xlab(x_name) +
    ggplot2::ylab("") +
    ggplot2::ggtitle("Sample Distribution") +
    ggplot2::guides(fill = ggplot2::guide_legend(title = y_name))
  
  # inf_plot
  inf_plot <- ggplot2::ggplot(data.frame(x = c(null - 4*se, null + 4*se)), ggplot2::aes(x)) + 
    ggplot2::stat_function(fun = dnorm, args = list(mean = null, sd = se), color = "#999999") +
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = 0, ymax = Inf, 
             alpha = 0.3, fill = "#FABAB8") +
    ggplot2::ggtitle("Null Distribution") +
    ggplot2::xlab("") +
    ggplot2::ylab("") +
    ggplot2::geom_vline(xintercept = p_hat_diff, color = "#F57670", lwd = 1.5)
  
  # print plots
  if(show_eda_plot & !show_inf_plot){ 
    print(eda_plot)
  }
  if(!show_eda_plot & show_inf_plot){ 
    print(inf_plot)
  }
  if(show_eda_plot & show_inf_plot){
    gridExtra::grid.arrange(eda_plot, inf_plot, ncol = 2)
  }
  
  # return
  return(list(SE = se, z = z, p_value = p_value))
}