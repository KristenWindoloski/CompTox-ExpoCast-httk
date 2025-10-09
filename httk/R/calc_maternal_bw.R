#' Calculate maternal body weight
#' 
#' This function initializes the parameters needed in the functions
#' solve_fetal_pbtk by calling solve_pbtk and adding additional parameters.
#' 
#'   BW <- params$pre_pregnant_BW + 
#'    params$BW_cubic_theta1 * tw + 
#'    params$BW_cubic_theta2 * tw^2 + 
#'    params$BW_cubic_theta3 * tw^3
#'
#' @param week Gestational week
#' 
#' @param chemdata A data frame with physicochemical data following the exact
#' structure of httk's chem.physical_and_invitro.data data frame; the data frame 
#' must be either the original chem.physical_and_invitro.data data frame or the 
#' original chem.physical_and_invitro.data data frame with additional
#' rows of chemicals (if the user wanted to add chemicals to the list). All 
#' columns must remain and be in the same order as the original data frame.
#'
#' @return \item{BW}{Maternal Body Weight, kg.}
#'
#' @references 
#' \insertRef{kapraun2019empirical}{httk} 
#'
#' @keywords Parameter
#' 
#' @author John Wambaugh
#' 
#' @export calc_maternal_bw
calc_maternal_bw <- function(
  week = 12,
  chemdata=chem.physical_and_invitro.data)
{
  return(calc_fetal_phys(week,
                         chemdata=chemdata)$BW)
}