#' Calculate the analytic steady state concentration for the three compartment
#' steady-state model
#'
#' This function calculates the steady state plasma or venous blood 
#' concentrations as a result of constant oral infusion dosing. 
#' The equation, initally used 
#' for high throughput in vitro-in vivo extrapolation in
#' \insertCite{rotroff2010incorporating}{httk} and later given in 
#' \insertCite{wetmore2012integration}{httk}, assumes that the concentration 
#' is the inverse of the total clearance, which is the sum of hepatic metabolism
#' and renal filatrion:
#' \deqn{C^{ss}_{plasma} = \frac{dose}{f_{up}*Q_{GFR}+Cl_{h}}}
#' \deqn{C^{ss}_{blood} = R_{b:p}*C^{ss}_{plasma}}
#'  where Q_GFR is the glomerular filtration
#' rate in the kidney, Cl_h is the chemical-specific whole liver metabolism 
#' clearance (scaled up from intrinsic clearance, which does not depend on flow),
#' f_up is the chemical-specific fraction unbound in plasma, R_b:p is the 
#' chemical specific ratio of concentrations in blood:plasma.
#'
#' This equation is a simplification of the steady-state plasma concentration
#' in the three-comprtment model (see \code{\link{solve_3comp}}), neglecting a
#' higher order term that causes this Css to be higher for very rapidly cleared
#' chemicals.
#'
#'@param chem.name Either the chemical name, CAS number, or the parameters must 
#' be specified.
#'
#'@param chem.cas Either the chemical name, CAS number, or the parameters must 
#' be specified.
#'
#' @param dtxsid EPA's 'DSSTox Structure ID (\url{https://comptox.epa.gov/dashboard})   
#' the chemical must be identified by either CAS, name, or DTXSIDs
#'
#'@param parameters Chemical parameters from parameterize_pbtk (for model = 
#' 'pbtk'), parameterize_3comp (for model = '3compartment), 
#' parameterize_1comp(for model = '1compartment') or parameterize_steadystate 
#' (for model = '3compartmentss'), overrides chem.name and chem.cas.
#'
#'@param hourly.dose Hourly dose rate mg/kg BW/h.
#'
#'@param concentration Desired concentration type, 'blood' or default 'plasma'.
#'
#'@param suppress.messages Whether or not the output message is suppressed.
#'
#'@param recalc.blood2plasma Recalculates the ratio of the amount of chemical 
#' in the blood to plasma using the input parameters. Use this if you have 
#' 'altered hematocrit, Funbound.plasma, or Krbc2pu.
#'
#'@param tissue Desired tissue concentration (defaults to whole body 
#'concentration.)
#'
#'@param restrictive.clearance If TRUE (default), then only the fraction of
#' chemical not bound to protein is available for metabolism in the liver. If 
#' FALSE, then all chemical in the liver is metabolized (faster metabolism due
#' to rapid off-binding). 
#'
#'@param bioactive.free.invivo If FALSE (default), then the total concentration is treated
#' as bioactive in vivo. If TRUE, the the unbound (free) plasma concentration is treated as 
#' bioactive in vivo. Only works with tissue = NULL in current implementation.
#' 
#' @param dosing List of dosing metrics used in simulation, which includes
#' the namesake entries of a model's associated dosing.params. For steady-state
#' calculations this is likely to be either "daily.dose" for oral exposures or
#' "Cinhaled" for inhalation.
#'
#' @param dose.units The units associated with the dose received.
#' 
#' @param Caco2.options A list of options to use when working with Caco2 apical to
#' basolateral data \code{Caco2.Pab}, default is Caco2.options = list(Caco2.Pab.default = 1.6,
#' Caco2.Fabs = TRUE, Caco2.Fgut = TRUE, overwrite.invivo = FALSE, keepit100 = FALSE). Caco2.Pab.default sets the default value for 
#' Caco2.Pab if Caco2.Pab is unavailable. Caco2.Fabs = TRUE uses Caco2.Pab to calculate
#' fabs.oral, otherwise fabs.oral = \code{Fabs}. Caco2.Fgut = TRUE uses Caco2.Pab to calculate 
#' fgut.oral, otherwise fgut.oral = \code{Fgut}. overwrite.invivo = TRUE overwrites Fabs and Fgut in vivo values from literature with 
#' Caco2 derived values if available. keepit100 = TRUE overwrites Fabs and Fgut with 1 (i.e. 100 percent) regardless of other settings.
#' See \code{\link{get_fbio}} for further details.
#' 
#'@param ... Additional parameters passed to parameterize function if 
#'parameters is NULL.
#'  
#' @return Steady state plasma concentration in mg/L units
#'
#' @seealso \code{\link{calc_analytic_css}}
#'
#' @seealso \code{\link{parameterize_steadystate}}
#'
#' @author Robert Pearce and John Wambaugh
#'
#' @references 
#' \insertAllCited{}
#'
#' @keywords 3compss steady-state
calc_analytic_css_3compss <- function(chem.name=NULL,
                                   chem.cas = NULL,
                                   dtxsid = NULL,
                                   parameters=NULL,
                                   dosing=list(daily.dose=1),
                                   hourly.dose = NULL,
                                   dose.units = "mg",
                                   concentration='plasma',
                                   suppress.messages=FALSE,
                                   recalc.blood2plasma=FALSE,
                                   tissue=NULL,
                                   restrictive.clearance=TRUE,
                                   bioactive.free.invivo = FALSE,
                                   Caco2.options = list(),
                                   chemdata=chem.physical_and_invitro.data,
                                   ...)
{
  if (!is.null(hourly.dose))
  {
     warning("calc_analytic_css_3compss deprecated argument hourly.dose replaced with new argument dose, value given assigned to dose")
     dosing <- list(daily.dose = 24*hourly.dose)
  }
  
# Load from modelinfo file:
  THIS.MODEL <- "3compartmentss"
  param.names <- model.list[[THIS.MODEL]]$param.names
  param.names.schmitt <- model.list[["schmitt"]]$param.names
  parameterize_function <- model.list[[THIS.MODEL]]$parameterize.func
    
# We need to describe the chemical to be simulated one way or another:
  if (is.null(chem.cas) & 
      is.null(chem.name) & 
      is.null(dtxsid) &
      is.null(parameters)) 
    stop('parameters, chem.name, chem.cas, or dtxsid must be specified.')

# Expand on any provided chemical identifiers if possible (if any but not
# all chemical descriptors are NULL):
  chem_id_list  = list(chem.cas, chem.name, dtxsid)
  if (any(unlist(lapply(chem_id_list, is.null))) &
      !all(unlist(lapply(chem_id_list, is.null)))){
  out <- get_chem_id(chem.cas=chem.cas,
                     chem.name=chem.name,
                     dtxsid=dtxsid,
                     chemdata=chemdata)
  chem.cas <- out$chem.cas
  chem.name <- out$chem.name                                
  dtxsid <- out$dtxsid  
  }
  
# Fetch some parameters using parameterize_steadstate, if needed:
  if (is.null(parameters))
  {
  # Look up the chemical name/CAS, depending on what was provide:
    out <- get_chem_id(chem.cas=chem.cas,
                       chem.name=chem.name,
                       dtxsid=dtxsid,
                       chemdata=chemdata)
    chem.cas <- out$chem.cas
    chem.name <- out$chem.name                                
    dtxsid <- out$dtxsid

    if (recalc.blood2plasma) 
    {
      warning("Argument recalc.blood2plasma=TRUE ignored because parameters is NULL.")
    }
    
    parameters <- do.call(what=parameterize_function, 
                          args=purrr::compact(c(list(chem.cas=chem.cas,
                                                     chem.name=chem.name,
                                                     suppress.messages=suppress.messages,
                                                     Caco2.options = Caco2.options,
                                                     restrictive.clearance = restrictive.clearance,
                                                     chemdata=chemdata),
                                                ...)))

  } else {
    if (!all(param.names %in% names(parameters)))
    {
      stop(paste("Missing parameters:",
                 paste(param.names[which(!param.names %in% names(parameters))],
                   collapse=', '),
                 ".  Use parameters from parameterize_steadystate."))
    }
  }
  if (any(parameters$Funbound.plasma == 0)) 
  {
    stop('Fraction unbound plasma cannot be zero.')
  }
#  if (is.na(parameters$hepatic.bioavailability)) browser() 
  if (recalc.blood2plasma) 
  {
    parameters$Rblood2plasma <- calc_rblood2plasma(chem.cas=chem.cas,
                                                   parameters=parameters,
                                                   hematocrit=parameters$hematocrit,
                                                   chemdata=chemdata)
  }

  BW <- parameters$BW
  
  # Dose rate:
  hourly.dose <- dosing[["daily.dose"]] /
                   24 /
                   BW *
                   convert_units(MW = parameters[["MW"]],
                                 dose.units,
                                 "mg") # mg/kg/h

  Fup <- parameters$Funbound.plasma
  Rb2p <- parameters$Rblood2plasma 

  # Total blood flow (gut plus arterial) into liver:
  Qtotalliver <- parameters$Qtotal.liverc/BW^0.25 # L / h / kg BW

  # Scale glomerular filtration rate (for kidney elimination) to per kg BW:
  Qgfr <- parameters$Qgfrc/BW^0.25 # L / h / kg BW

  # Scale up from in vitro Clint to a whole liver clearance:
  Clhep <- calc_hep_clearance(parameters=parameters,
                              hepatic.model="well-stirred",
                              restrictive.clearance = restrictive.clearance,
                              suppress.messages=TRUE,
                              chemdata=chemdata) # L / h / kg BW

  # Oral bioavailability:
  Fabsgut <- parameters$Fabsgut
  Fhep <- parameters$hepatic.bioavailability


# Calculate steady-state plasma Css. With the well-stirred calculation (above)
# this is the same equation as Wetmore et al. (2012) page 160 or 
# Pearce et al. (2017) equation section 2.2:

   Css <- hourly.dose * # Oral dose rate mg/kg/h
          Fabsgut * # Fraction of dose absorbed from gut (in vivo or Caco-2)
          Fhep / # Fraction of dose that escapes first-pass hepatic metabolism
          (
            Qgfr * Fup + # Glomerular filtration to proximal tubules (kidney)
            Clhep # Well-stirred hepatic metabolism (liver)
          )

# Css has units of mg / L
    
# Check to see if a specific tissue was asked for:
  if (!is.null(tissue))
  {
    # We need logP, the pKa's, and membrane affinity, which currently isn't one 
    # of the 3compss parameters, so unless the user provides these parameters,
    # they need to give a chemical identifier like chem.name/chem.cas/dtxsid, or
    # we can't find them in the chem.physical_and_invitro.data set and run:
    if (!any(c("Pow", "MA", "pKa_Accept", "pKa_Donor") %in% 
             names(parameters))) {
      #We do a lookup of these needed parameters using a targeted version of 
      #get_physchem_param for the 3 compss model, add_schmitt.param_to_3compss
      #(function definition nested at bottom):
        parameters <- add_schmitt.param_to_3compss(parameters = parameters,
                                                   chem.cas = chem.cas, 
                                                   chem.name = chem.name, 
                                                   dtxsid = dtxsid,
                                                   chemdata=chemdata)
    }

    #The parameters used in predict_partitioning_schmitt may be a compound
    #data.table/data.frame or list object, however, depending on the source 
    #of the parameters. In calc_mc_css, for example, parameters is received 
    #as a "data.table" object. Screen for processing appropriately, and 
    #pass our parameters to predict_partitioning_schmitt so we can get
    #the needed pc's.
    if (any(class(parameters) == "data.table")){
      pcs <- predict_partitioning_schmitt(parameters =
          parameters[, param.names.schmitt[param.names.schmitt %in% 
          names(parameters)], with = F])
    }else if (is(parameters,"list")) {
      pcs <- predict_partitioning_schmitt(parameters =
          parameters[param.names.schmitt[param.names.schmitt %in% 
          names(parameters)]])
    }else stop('httk is only configured to process parameters as objects of 
               class list or class compound data.table/data.frame.')
    
    if (!paste0('K',tolower(tissue)) %in% 
      substr(names(pcs),1,nchar(names(pcs))-3))
    {
      stop(paste("Tissue",tissue,"is not available."))
    }

    Css <- Css * pcs[[names(pcs)[substr(names(pcs),2,nchar(names(pcs))-3)==tissue]]] * Fup   
  }

  if(tolower(concentration) != "tissue"){
    
    if (tolower(concentration)=='blood')
    {
  # Convert from blood to plasma:
        Css <-Css*Rb2p
    }else if(bioactive.free.invivo == TRUE & tolower(concentration) == 'plasma'){
      
      Css <- Css * parameters[['Funbound.plasma']]
      
    } else if (tolower(concentration)!='plasma') stop("Only blood and plasma concentrations are calculated.")      
  }
  return(Css)
}

# Add some parameters to the output from parameterize_steady_state so that
# predict_partitioning_schmitt can run without reparameterizing
add_schmitt.param_to_3compss <- function(parameters = NULL, 
                                         chem.cas = NULL,
                                         chem.name = NULL, 
                                         dtxsid = NULL,
                                         chemdata=chem.physical_and_invitro.data){
  
  if ((is.null(chem.cas) & is.null(chem.name) & is.null(dtxsid)))
    stop("Either chem.cas, chem.name, or dtxsid must be specified to give 
          tissue concs with this model. Try model=\"pbtk\".")
  if (is.null(parameters))
    stop("Must have input parameters to add Schmitt input to.")
  # Need to convert to 3compartmentss parameters:
  temp.params <- get_physchem_param(chem.cas = chem.cas, 
                                    chem.name = chem.name,
                                    dtxsid = dtxsid, 
                                    chemdata=chemdata,
                                    param = c("logP", "logMA", "pKa_Accept","pKa_Donor"))
  if(!"Pow" %in% names(parameters)){
    parameters[["Pow"]] <- 10^temp.params[["logP"]]
  }
  if(!"MA" %in% names(parameters)){
    parameters[["MA"]] <- 10^temp.params[["logMA"]]
  }
  if(!"pKa_Accept" %in% names(parameters)){
    parameters[["pKa_Accept"]] <- temp.params[["pKa_Accept"]]
  }
  if(!"pKa_Donor" %in% names(parameters)){
    parameters[["pKa_Donor"]] <- temp.params[["pKa_Donor"]]
  }
  return(parameters)
}
