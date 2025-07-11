#' Calculate the constant ratio of the blood concentration to the plasma
#' concentration.
#' 
#' This function calculates the constant ratio of the blood concentration to
#' the plasma concentration.
#' 
#' The red blood cell (RBC) parition coefficient as predicted by the Schmitt
#' (2008) method is used in the calculation. The value is calculated with the
#' equation: 1 - hematocrit + hematocrit * Krbc2pu * Funbound.plasma, summing
#' the red blood cell to plasma and plasma:plasma (equal to 1) partition
#' coefficients multiplied by their respective fractional volumes. When
#' species is specified as rabbit, dog, or mouse, the function uses the
#' appropriate physiological data (hematocrit and temperature), but substitutes
#' human fraction unbound and tissue volumes. 
#' 
#' @param chem.name Either the chemical name or the CAS number must be
#' specified.
#' 
#' @param chem.cas Either the CAS number or the chemical name must be
#' specified.
#' 
#' @param dtxsid EPA's DSSTox Structure ID (\url{https://comptox.epa.gov/dashboard})  
#' the chemical must be identified by either CAS, name, or DTXSIDs
#' 
#' @param parameters Parameters from \code{\link{parameterize_schmitt}}
#' 
#' @param hematocrit Overwrites default hematocrit value in calculating
#' Rblood2plasma.
#' 
#' @param Krbc2pu The red blood cell to unbound plasma chemical partition
#' coefficient, typically from \code{\link{predict_partitioning_schmitt}}
#' 
#' @param Funbound.plasma The fraction of chemical unbound (free) in the
#' presence of plasma protein
#' 
#' @param default.to.human Substitutes missing animal values with human values
#' if true.
#' 
#' @param species Species desired (either "Rat", "Rabbit", "Dog", "Mouse", or
#' default "Human").
#' 
#' @param adjusted.Funbound.plasma Whether or not to use Funbound.plasma
#' adjustment.
#' 
#' @param suppress.messages Determine whether to display certain usage
#' feedback.
#' 
#' @param class.exclude Exclude chemical classes identified as outside of 
#' domain of applicability by relevant modelinfo_[MODEL] file (default TRUE).
#'
#' @return
#' The blood to plasma chemical concentration ratio
#'
#' @author John Wambaugh and Robert Pearce
#'
#' @references 
#' \insertRef{schmitt2008general}{httk}
#'
#' \insertRef{pearce2017evaluation}{httk}
#'
#' \insertRef{ruark2014predicting}{httk}
#'
#' @keywords Parameter
#'
#' @examples
#' 
#' calc_rblood2plasma(chem.name="Bisphenol A")
#' calc_rblood2plasma(chem.name="Bisphenol A",species="Rat")
#' 
#' @export calc_rblood2plasma
calc_rblood2plasma <- function(
                        chem.cas=NULL,
                        chem.name=NULL,
                        dtxsid=NULL,
                        parameters=NULL,
                        hematocrit=NULL,
                        Krbc2pu=NULL,
                        Funbound.plasma=NULL,
                        default.to.human=FALSE,
                        species="Human",
                        adjusted.Funbound.plasma=TRUE,
                        class.exclude=TRUE,
                        suppress.messages=TRUE,
                        chemdata=chem.physical_and_invitro.data)
{
  physiology.data <- physiology.data

  # We need to describe the chemical to be simulated one way or another:
  if (is.null(chem.cas) & is.null(chem.name) & is.null(dtxsid) & is.null(parameters) & (is.null(Krbc2pu) | is.null(hematocrit) | is.null(Funbound.plasma))) 
    stop('Parameters, chem.name, chem.cas, or dtxsid must be specified.')

# Look up the chemical name/CAS, depending on what was provide:
  if (any(!is.null(chem.cas),!is.null(chem.name),!is.null(dtxsid))) {
    
    out <- get_chem_id(chem.cas=chem.cas,
                       chem.name=chem.name,
                       dtxsid=dtxsid,
                       chemdata=chemdata)
    
    chem.cas <- out$chem.cas
    chem.name <- out$chem.name                                
    dtxsid <- out$dtxsid
  }

  if (is.null(parameters) & (is.null(Krbc2pu) | is.null(hematocrit) | is.null(Funbound.plasma))) {
    
    parameters <- parameterize_schmitt(chem.cas=chem.cas,
                                       chem.name=chem.name,
                                       dtxsid=dtxsid,
                                       default.to.human=default.to.human,
                                       species=species,
                                       class.exclude=class.exclude,
                                       suppress.messages=suppress.messages,
                                       chemdata=chemdata)
  } 
  else if (is.null(parameters)){
    
    parameters <- list(hematocrit=hematocrit,
                       Krbc2pu=Krbc2pu,
                       Funbound.plasma=Funbound.plasma)
  } 
  else {
    
    # Work with local copy of parameters in function(scoping):
    if (is.data.table(parameters)) 
      parameters <- copy(parameters) 
  }
  
  if (!(species %in% colnames(physiology.data))){
    
    if (toupper(species) %in% toupper(colnames(physiology.data))){
      
      phys.species <- colnames(physiology.data)[toupper(colnames(physiology.data))==toupper(species)]
    } 
    else 
      stop(paste("Physiological PK data for",species,"not found."))
  } 
  else 
    phys.species <- species

  if (is.null(hematocrit)) {
    if (is.null(parameters$hematocrit)){
      hematocrit <- physiology.data[physiology.data$Parameter=="Hematocrit",phys.species]
    } 
    else {
      hematocrit <- parameters$hematocrit
    }
  }
  
# Predict the PCs for all tissues in the tissue.data table:

  if (is.null(parameters$Krbc2pu)&is.null(Krbc2pu)){
    
    PCs <- predict_partitioning_schmitt(parameters=parameters,
                                        species=species,
                                        adjusted.Funbound.plasma=adjusted.Funbound.plasma,
                                        tissues='red blood cells',
                                        suppress.messages=TRUE,
                                        chemdata=chemdata)  
    parameters$Krbc2pu <- PCs$Krbc2pu
  } 
  else if (!is.null(Krbc2pu)){
    parameters$Krbc2pu <- Krbc2pu
  } 
  
  
  
  if (adjusted.Funbound.plasma) {
    Rblood2plasma <- 1 - hematocrit + hematocrit * parameters$Krbc2pu * parameters$Funbound.plasma
  } 
  else { 
    Rblood2plasma <- 1 - hematocrit + hematocrit * parameters$Krbc2pu * parameters$unadjusted.Funbound.plasma
  }
  
  if (!suppress.messages)
    warning("Rblood2plasma has been recalculated.")
    
  return(set_httk_precision(as.numeric(Rblood2plasma)))
}
