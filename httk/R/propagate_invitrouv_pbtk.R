#' Propagates uncertainty and variability in in vitro HTTK data into PBPK
#' model parameters
#'
#' @param parameters.dt The data table of parameters being used by the Monte
#' Carlo sampler
#' @param chemdata A data frame with physicochemical data following the exact
#' structure of httk's chem.physical_and_invitro.data data frame; the data frame 
#' must be either the original chem.physical_and_invitro.data data frame or the 
#' original chem.physical_and_invitro.data data frame with additional
#' rows of chemicals (if the user wanted to add chemicals to the list). All 
#' columns must remain and be in the same order as the original data frame.
#' @param ... Additional arguments passed to \code{\link{calc_hep_clearance}}
#'
#'@return A data.table whose columns are the parameters of the HTTK model
#'  specified in \code{model}.
#'
#' @author John Wambaugh
#'
#' @keywords monte-carlo pbtk
propagate_invitrouv_pbtk <- function(
                             parameters.dt,
                             chemdata,
                             ...)
{
  warning(paste("Inside propogate ", tail(chemdata[,1:3])))
  
  #R CMD CHECK throws notes about "no visible binding for global variable", for
  #each time a data.table column name is used without quotes. To appease R CMD
  #CHECK, a variable has to be created for each of these column names and set to
  #NULL. Note that within the data.table, these variables will not be NULL! Yes,
  #this is pointless and annoying.
  
  Clmetabolismc<-Clint<-Funbound.plasma<-Fhep.assay.correction<-Qgutf<-NULL
  liver.density<-million.cells.per.gliver<-BW<-Vliverc<-Qliverf<-NULL
  Qcardiacc<- NULL
  
  #End R CMD CHECK appeasement.
  
  extra.args <- list(...)
  calc.hep.clear.args <- extra.args[names(extra.args) %in% names(formals(calc_hep_clearance))]
  
  parameters.dt[, Clmetabolismc := as.numeric(
    do.call(calc_hep_clearance,
            args=purrr::compact(c(list(hepatic.model="unscaled",
                                       parameters=list(Clint=Clint, #uL/min/10^6 cells
                                                       Funbound.plasma=Funbound.plasma, # unitless fraction
                                                       Fhep.assay.correction=Fhep.assay.correction, 
                                                       million.cells.per.gliver= million.cells.per.gliver, # 10^6 cells/g-liver
                                                       liver.density= liver.density, # g/mL
                                                       Dn=0.17,
                                                       BW=BW,
                                                       Vliverc=Vliverc, #L/kg
                                                       Qtotal.liverc=((Qgutf+Qliverf)*as.numeric(Qcardiacc))), # L/h/kgBW^(3/4)
                                       suppress.messages=TRUE,
                                       chemdata=chemdata),
                                  calc.hep.clear.args))))]

  return(parameters.dt)
}