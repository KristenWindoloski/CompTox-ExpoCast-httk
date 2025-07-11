#' Get literature Css
#' 
#' This function retrieves a steady-state plasma concentration as a result of
#' infusion dosing from the Wetmore et al. (2012) and (2013) publications and
#' other literature. 
#' 
#' @param chem.name Either the chemical name or the CAS number must be
#' specified. 
#' @param chem.cas Either the cas number or the chemical name must be
#' specified. 
#' @param which.quantile Which quantile from the SimCYP Monte Carlo simulation
#' is requested. Can be a vector. 
#' @param species Species desired (either "Rat" or default "Human").
#' @param clearance.assay.conc Concentration of chemical used in measureing
#' intrinsic clearance data, 1 or 10 uM.
#' @param daily.dose Total daily dose infused in units of mg/kg BW/day.
#' Defaults to 1 mg/kg/day.  
#' @param output.units Returned units for function, defaults to mg/L but can
#' also be uM (specify units = "uM"). 
#' @param suppress.messages Whether or not the output message is suppressed.
#'
#' @return A numeric vector with the literature steady-state plasma 
#' concentration (1 mg/kg/day) for the requested quantiles
#'
#' @author John Wambaugh
#'
#' @references
#' \insertRef{wetmore2012integration}{httk}
#' 
#' \insertRef{wetmore2013relative}{httk}
#' 
#' \insertRef{wetmore2015incorporating}{httk}
#'
#' @keywords Literature Monte-Carlo
#'
#' @examples
#' get_lit_css(chem.cas="34256-82-1")
#' 
#' get_lit_css(chem.cas="34256-82-1",species="Rat",which.quantile=0.5)
#' 
#' get_lit_css(chem.cas="80-05-7", daily.dose = 1,which.quantile = 0.5, output.units = "uM")
#' 
#' @export get_lit_css
get_lit_css <- function(
                        chem.cas=NULL,
                        chem.name=NULL,
                        daily.dose=1,
                        which.quantile=0.95,
                        species="Human",
                        clearance.assay.conc=NULL,
                        output.units="mg/L",
                        suppress.messages=FALSE,
                        chemdata=chem.physical_and_invitro.data)
{
  Wetmore.data <- Wetmore.data
  if (species == "Human") available.quantiles <- c(0.05,0.5, 0.95)
  else available.quantiles <- 0.5
  if (!all(which.quantile %in% available.quantiles)) stop(
      "Literature only includes 5%, 50%, and 95% quantiles for human and 50% for rat.")
      
  if (!(tolower(output.units) %in% c("mg/l","um"))) stop(
      "Literature only includes mg/L and uM values for Css")
  out <- get_chem_id(chem.cas=chem.cas,chem.name=chem.name,chemdata=chemdata)
  chem.cas <- out$chem.cas
  chem.name <- out$chem.name
    
  this.data <- subset(Wetmore.data,Wetmore.data[,"CAS"] == chem.cas &
                      toupper(Wetmore.data[,"Species"])==toupper(species))
   
    if (!is.null(clearance.assay.conc)) 
    {
      this.data <- subset(this.data,this.data[,"Concentration..uM."] ==
                          clearance.assay.conc)[1,]
      if (dim(this.data)[1]!=1) stop(
          paste("No",
                clearance.assay.conc,
                "uM clearance assay data for",
                chem.name,
                "in",
                species))
    }else{
      if (1 %in% this.data[,"Concentration..uM."]) {
        this.data <- subset(this.data,this.data[,"Concentration..uM."]== 1)[1,] 
        clearance.assay.conc <- 1
      } else {
        this.data <- this.data[1,]
        clearance.assay.conc <- this.data[,"Concentration..uM."][[1]]
      }
    }
    out <- NULL
    if (tolower(output.units)=="mg/l")
    {
      if (0.05 %in% which.quantile) out <- 
        c(out,daily.dose*this.data[,"Css_lower_5th_perc.mg.L."])
      if (0.5 %in% which.quantile) out <- 
        c(out,daily.dose*this.data[,"Css_median_perc.mg.L."])
      if (0.95 %in% which.quantile) out <- 
        c(out,daily.dose*this.data[,"Css_upper_95th_perc.mg.L."])
    } else if(tolower(output.units) == 'um') {
      if (0.05 %in% which.quantile) out <- 
        c(out,daily.dose*this.data[,"Css_lower_5th_perc.uM."])
      if (0.5 %in% which.quantile) out <- 
        c(out,daily.dose*this.data[,"Css_median_perc.uM."])
      if (0.95 %in% which.quantile) out <- 
        c(out,daily.dose*this.data[,"Css_upper_95th_perc.uM."])
    } else{
     stop('Output.units can only be uM or mg/L.')
    }
  
  if (!suppress.messages) {
    cat(paste(
              toupper(substr(species,1,1)),
              substr(species,2,nchar(species)),
              " plasma concentrations returned in ",
              output.units,
              " units.\n",
              sep=""))
    cat(paste(
              "Retrieving Css from literature based on ",
              clearance.assay.conc,
              " uM intrinsic clearance data for the ",
              which.quantile,
              " quantile in ",
              species,
              ".\n",
              sep=""))
  }
  return(set_httk_precision(out))
}


#' Get literature Css (deprecated).
#' 
#' This function is included for backward compatibility. It calls
#' \code{\link{get_lit_css}} which
#' retrieves a steady-state plasma concentration as a result of
#' infusion dosing from the Wetmore et al. (2012) and (2013) publications and
#' other literature.
#' 
#' @param chem.name Either the chemical name or the CAS number must be
#' specified. 
#' @param chem.cas Either the cas number or the chemical name must be
#' specified. 
#' @param which.quantile Which quantile from the SimCYP Monte Carlo simulation
#' is requested. Can be a vector. 
#' @param species Species desired (either "Rat" or default "Human").
#' @param clearance.assay.conc Concentration of chemical used in measureing
#' intrinsic clearance data, 1 or 10 uM.
#' @param daily.dose Total daily dose infused in units of mg/kg BW/day.
#' Defaults to 1 mg/kg/day.  
#' @param output.units Returned units for function, defaults to mg/L but can
#' also be uM (specify units = "uM"). 
#' @param suppress.messages Whether or not the output message is suppressed.
#'
#' @return A numeric vector with the literature steady-state plasma 
#' concentration (1 mg/kg/day) for the requested quantiles
#'
#' @author John Wambaugh
#'
#' @references
#' \insertRef{wetmore2012integration}{httk}
#' 
#' \insertRef{wetmore2013relative}{httk}
#' 
#' \insertRef{wetmore2015incorporating}{httk}
#'
#' @keywords Literature Monte-Carlo
#'
#' @examples
#' get_lit_css(chem.cas="34256-82-1")
#' 
#' get_lit_css(chem.cas="34256-82-1",species="Rat",which.quantile=0.5)
#' 
#' get_lit_css(chem.cas="80-05-7", daily.dose = 1,which.quantile = 0.5, output.units = "uM")
#
#' @export get_wetmore_css
get_wetmore_css <- function(
                        chem.cas=NULL,
                        chem.name=NULL,
                        daily.dose=1,
                        which.quantile=0.95,
                        species="Human",
                        clearance.assay.conc=NULL,
                        output.units="mg/L",
                        suppress.messages=FALSE)
{
  if (!suppress.messages)
    warning("Function \"get_wetmore_css\" has been renamed to \"get_lit_cheminfo\".")
  
  return(do.call(get_lit_css, args=purrr::compact(list(                        
                        chem.cas=chem.cas,
                        chem.name=chem.name,
                        daily.dose=daily.dose,
                        which.quantile=which.quantile,
                        species=species,
                        clearance.assay.conc=clearance.assay.conc,
                        output.units=output.units,
                        suppress.messages=suppress.messages))))
}