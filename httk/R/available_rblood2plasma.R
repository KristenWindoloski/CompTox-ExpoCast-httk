#' Find the best available ratio of the blood to plasma concentration constant.
#' 
#' This function finds the best available constant ratio of the blood
#' concentration to the plasma concentration, using 
#' \code{\link{get_rblood2plasma}} and \code{\link{calc_rblood2plasma}}.
#' 
#' Either retrieves a measured blood:plasma concentration ratio from the
#' \code{\link{chem.physical_and_invitro.data}} table or calculates it using the red blood cell
#' partition coefficient predicted with Schmitt's method
#' 
#' If available, in vivo data (from \code{\link{chem.physical_and_invitro.data}}) 
#' for the
#' given species is returned, substituting the human in vivo value when missing
#' for other species.  In the absence of in vivo data, the value is calculated
#' with \code{\link{calc_rblood2plasma}} for the given species. If Funbound.plasma is
#' unvailable for the given species, the human Funbound.plasma is substituted.
#' If none of these are available, the mean human Rblood2plasma from
#' \code{\link{chem.physical_and_invitro.data}} is returned.  %% ~~ If necessary, more
#' details than the description above ~~
#' 
#' @param chem.cas Either the CAS number or the chemical name must be
#' specified. 
#' 
#' @param chem.name Either the chemical name or the CAS number must be
#' specified. 
#' 
#' @param dtxsid EPA's 'DSSTox Structure ID (https://comptox.epa.gov/dashboard)  
#' the chemical must be identified by either CAS, name, or DTXSIDs
#' @param species Species desired (either "Rat", "Rabbit", "Dog", "Mouse", or
#' default "Human"). 
#' 
#' @param adjusted.Funbound.plasma Whether or not to use Funbound.plasma
#' adjustment if calculating Rblood2plasma.
#' 
#' @param suppress.messages Whether or not to display relevant warning messages
#' to user.
#' 
#' @param class.exclude Exclude chemical classes identified as outside of 
#' domain of applicability by relevant modelinfo_[MODEL] file (default TRUE).
#' 
#' @param chemdata Data frame with the chemical data needed to run the simulation;
#' defaults to httk's chem.physical_and_invitro.data but is included if the user
#' wants to add additional data to the default data frame
#' 
#' @return
#' The blood to plasma chemical concentration ratio -- measured if available,
#' calculated if not.
#'
#' @author Robert Pearce
#' 
#' @keywords Parameter
#' 
#' @seealso \code{\link{calc_rblood2plasma}}
#' 
#' @seealso \code{\link{get_rblood2plasma}}
#'
#' @examples
#' 
#' available_rblood2plasma(chem.name="Bisphenol A",adjusted.Funbound.plasma=FALSE)
#' available_rblood2plasma(chem.name="Bisphenol A",species="Rat")
#' 
#' @export available_rblood2plasma
available_rblood2plasma <- function(chem.cas=NULL,
                                    chem.name=NULL,
                                    dtxsid=NULL,
                                    species='Human',
                                    adjusted.Funbound.plasma=TRUE,
                                    class.exclude=TRUE,
                                    suppress.messages=FALSE,
                                    chemdata=chem.physical_and_invitro.data)

{
  if (!is.null(chem.cas) | !is.null(chem.name) | !is.null(dtxsid)){
    
    Rblood2plasma <- get_rblood2plasma(chem.name=chem.name,
                                       chem.cas=chem.cas,
                                       dtxsid=dtxsid,
                                       species=species,
                                       chemdata=chemdata) 
  
    if (tolower(species) != 'human' & is.na(Rblood2plasma)){
      
      Rblood2plasma <- get_rblood2plasma(chem.cas=chem.cas,
                                         chem.name=chem.name,
                                         dtxsid=dtxsid,
                                         species='Human',
                                         chemdata=chemdata)
      
      if (!is.na(Rblood2plasma) & !suppress.messages) 
        warning('Human in vivo measured Rblood2plasma substituted.')
    } 
    else if (!is.na(Rblood2plasma) & !suppress.messages) 
      warning(paste(toupper(substr(species, 1, 1)), substr(species, 2, nchar(species)),' in vivo measured Rblood2plasma used.',sep=""))
    
    if (is.na(Rblood2plasma)){
      
      if (is.null(chem.cas) & is.null(chem.name) & is.null(dtxsid)){
        
        Rblood2plasma.data <- chemdata[,'Human.Rblood2plasma']
        Rblood2plasma <- mean(Rblood2plasma.data[which(!is.na(Rblood2plasma.data))])
        
        if (!suppress.messages) 
          warning(paste('Average in vivo Human Rblood2plasma (',signif(Rblood2plasma,3),') substituted.',sep=""))
      } 
      else {
        if (is.null(chem.cas)) {
          
          out <- get_chem_id(chem.cas=chem.cas,
                             chem.name=chem.name,
                             dtxsid=dtxsid,
                             chemdata=chemdata)
          chem.cas <- out$chem.cas
        }
        
        if (chem.cas %in% get_cheminfo(species=species,
                                       model='schmitt',
                                       class.exclude=class.exclude,
                                       suppress.messages=TRUE,
                                       chemdata=chemdata)){
          
          Rblood2plasma <- calc_rblood2plasma(chem.cas=chem.cas,
                                              species=species,
                                              adjusted.Funbound.plasma=adjusted.Funbound.plasma,
                                              class.exclude=class.exclude,
                                              suppress.messages=suppress.messages,
                                              chemdata=chemdata)
          
          if (!suppress.messages) 
            warning(paste(toupper(substr(species, 1, 1)),substr(species, 2, nchar(species)),' Rblood2plasma calculated with calc_rblood2plasma.',sep="")) 
        } 
        else if (chem.cas %in% get_cheminfo(species='Human',
                                            model='schmitt',
                                            class.exclude=class.exclude,
                                            suppress.messages=TRUE,
                                            chemdata=chemdata)) {
          
          Rblood2plasma <- calc_rblood2plasma(chem.cas=chem.cas,
                                              species="Human",
                                              default.to.human=TRUE,
                                              class.exclude=class.exclude,
                                              adjusted.Funbound.plasma=adjusted.Funbound.plasma,
                                              suppress.messages=suppress.messages,
                                              chemdata=chemdata)
          
          if (!suppress.messages) 
            warning(paste(toupper(substr(species, 1, 1)),substr(species, 2, nchar(species)),' Rblood2plasma calculated with Human Funbound.plasma.',sep=""))
        } 
        else {
          
          Rblood2plasma.data <- chemdata[,'Human.Rblood2plasma']
          Rblood2plasma <- mean(Rblood2plasma.data, na.rm=TRUE)
          
          if (is.nan(Rblood2plasma)) 
            Rblood2plasma <- 1
          
          if (!suppress.messages) 
            warning(paste('Average in vivo Human Rblood2plasma (',signif(Rblood2plasma,3),') substituted.',sep=""))
        }
      }
    }
  } 
  else {
    
    Rblood2plasma.data <- chemdata[,'Human.Rblood2plasma']
    Rblood2plasma <- mean(Rblood2plasma.data[which(!is.na(Rblood2plasma.data))])
    
    if (!suppress.messages) 
      warning(paste('Average in vivo Human Rblood2plasma (',signif(Rblood2plasma,3),') substituted.',sep=""))  
  }
  
  return(set_httk_precision(Rblood2plasma))
}
