#' Back-calculates the Red Blood Cell to Unbound Plasma Partition Coefficient
#' 
#' Given an observed ratio of chemical concentration in blood to plasma, this
#' function calculates a Red Blood Cell to unbound plasma (Krbc2pu) partition
#' coefficient that would be consistent with that observation.
#' 
#' @param Rb2p The chemical blood:plasma concentration ratop
#' @param Funbound.plasma The free fraction of chemical in the presence of 
#' plasma protein
#' Rblood2plasma.
#' @param hematocrit Overwrites default hematocrit value in calculating
#' Rblood2plasma.
#' @param default.to.human Substitutes missing animal values with human values
#' if true.
#' @param species Species desired (either "Rat", "Rabbit", "Dog", "Mouse", or
#' default "Human").
#' @param suppress.messages Determine whether to display certain usage
#' feedback.
#' @param chemdata A data frame with physicochemical data following the exact
#' structure of httk's chem.physical_and_invitro.data data frame; the data frame 
#' must be either the original chem.physical_and_invitro.data data frame or the 
#' original chem.physical_and_invitro.data data frame with additional
#' rows of chemicals (if the user wanted to add chemicals to the list). All 
#' columns must remain and be in the same order as the original data frame.
#'
#' @return
#' The red blood cell to unbound chemical in plasma partition coefficient.
#'
#' @author John Wambaugh and Robert Pearce
#'
#' @references 
#' \insertRef{pearce2017evaluation}{httk}
#'
#' \insertRef{ruark2014predicting}{httk}
#'
#' @keywords Parameter
#'
#' @export calc_krbc2pu
calc_krbc2pu <- function(Rb2p,
                         Funbound.plasma,
                         hematocrit=NULL,
                         default.to.human=FALSE,
                         species="Human",
                         suppress.messages=TRUE,
                         chemdata=chem.physical_and_invitro.data)
{

  if (!(species %in% colnames(physiology.data_internal)))
  {
    if (toupper(species) %in% toupper(colnames(physiology.data_internal)))
    {
      phys.species <- colnames(physiology.data_internal)[
        toupper(colnames(physiology.data_internal))==toupper(species)]
    } else stop(paste("Physiological PK data for",species,"not found."))
  } else phys.species <- species

  if (is.null(hematocrit)) 
  {
    hematocrit <- 
      physiology.data_internal[physiology.data_internal$Parameter=="Hematocrit",phys.species]
  }
  
  Krbp2pu <- (Rb2p - 1 + hematocrit)  / Funbound.plasma / hematocrit
    
  return(set_httk_precision(as.numeric(Krbp2pu)))
}
