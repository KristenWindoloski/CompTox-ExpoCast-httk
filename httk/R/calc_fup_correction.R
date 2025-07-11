#' Calculate the correction for lipid binding in plasma binding assay
#' 
#' Poulin and Haddad (2012) observed "...that for
#' a highly lipophilic compound, the calculated 
#' \ifelse{html}{\out{f<sub>up</sub>}}{\eqn{f_{up}}} is by
#' far [less than] the experimental values observed under
#' in vitro conditions." Pearce et al. (2017) hypothesized that there was additional lipid
#' binding in vivo that acted as a sink for lipophilic compounds, reducing the
#' effective \ifelse{html}{\out{f<sub>up</sub>}}{\eqn{f_{up}}} in vivo. It is 
#' possible that this is due to the binding of lipophilic compounds on the non
#' plasma-side of the rapid equilibrium dialysis plates (Waters et al., 2008).
#'  Pearce et al. (2017) compared predicted and observed 
#'  tissue partition coefficients
#' for a range of compounds. They showed that predictions were improved by 
#' adding additional binding proportional to the distribution coefficient 
#' \ifelse{html}{\out{D<sub>ow</sub>}}{\eqn{D_{ow}}} 
#' (\code{\link{calc_dow}})
#' and the fractional volume of lipid in
#' plasma (\ifelse{html}{\out{F<sub>lipid</sub>}}{\eqn{F_{lipid}}}). 
#' We calculate
#' \ifelse{html}{\out{F<sub>lipid</sub>}}{\eqn{F_{lipid}}} as the     
#' sum of the physiological plasma neutral lipid fractional volume and 30 percent of 
#' the plasma neutral phospholipid fractional volume. We use values
#' from Peyret et al. (2010) for rats and Poulin and Haddad (2012)
#' for humans. The estimate of 30 percent of the
#' neutral phospholipid volume as neutral lipid was used for simplictity's sake in
#' place of our membrane affinity predictor. To account for additional binding to lipid, 
#' plasma to water partitioning
#' (\ifelse{html}{\out{K<sub>plasma:water</sub> = 1/f<sub>up</sub>}}{\eqn{K_{plasma:water} = \frac{1}{f_{up}}}})
#' is increased as such:
#' \ifelse{html}{\out{K<sup>corrected</sup><sub>plasma:water</sub> = 1/f<sup>corrected</sup><sub>up</sub> = 1/f<sup>in vitro</sup><sub>up</sub> + D<sub>ow</sub>*F<sub>lipid</sub>}}{\deqn{f^{corrected}_{up} = \frac{1}{f^{corrected}_{up}} = \frac{1}{K_{nL}^{pl}*F_{lipid} + \frac{1}{f^{in vitro}_{up}}}}}
#' 
#' Note that octanal:water partitioning above 1:1,000,000 
#' (\ifelse{html}{\out{LogD<sub>ow</sub> > 6}}{\eqn{LogD_{ow} > 6}})
#' are truncated at 1:1,000,000 because greater partitioning would
#' likely take longer than protein binding assay itself.
#'
#' @param fup Fraction unbound in plasma, if provided this argument overides
#' values from argument parameters and \code{\link{chem.physical_and_invitro.data}} 
#' 
#' @param chem.cas Chemical Abstract Services Registry Number (CAS-RN) -- if
#'  parameters is not specified then the chemical must be identified by either
#'  CAS, name, or DTXISD
#' 
#' @param chem.name Chemical name (spaces and capitalization ignored) --  if
#'  parameters is not specified then the chemical must be identified by either
#'  CAS, name, or DTXISD
#' 
#' @param dtxsid EPA's 'DSSTox Structure ID (\url{https://comptox.epa.gov/dashboard})  
#'  -- if parameters is not specified then the chemical must be identified by 
#' either CAS, name, or DTXSIDs
#' 
#' @param parameters Parameters from the appropriate parameterization function
#' for the model indicated by argument model
#' 
#' @param Flipid The fractional volume of lipid in plasma (from \code{\link{physiology.data}})
#' 
#' @param plasma.pH pH of plasma (default 7.4)
#'
#' @param dow74 The octanol-water distribution ratio (DOW).
#' 
#' @param species Species desired (either "Rat", "Rabbit", "Dog", "Mouse", or
#' default "Human").
#' 
#' @param default.to.human Substitutes missing fraction of unbound plasma with
#' human values if true.
#' 
#' @param force.human.fup Returns human fraction of unbound plasma in
#' calculation for rats if true.
#' When species is specified as rabbit, dog, or mouse, the human unbound
#' fraction is substituted.
#' 
#' @param suppress.messages Whether or not the output message is suppressed.
#' 
#' @return A numeric fraction unpbound in plasma between zero and one
#'
#' @author John Wambaugh 
#'
#' @references 
#'
#' \insertRef{pearce2017evaluation}{httk}
#' 
#' \insertRef{peyret2010unified}{httk}
#' 
#' \insertRef{poulin2012advancing}{httk}
#'
#' \insertRef{schmitt2008general}{httk}
#' 
#' \insertRef{waters2008validation}{httk}
#'
#' @keywords in-vitro
#'
#' @seealso \code{\link{apply_fup_adjustment}}
#'
#' @seealso \code{\link{calc_dow}}
#'
#' @export calc_fup_correction
#'
calc_fup_correction <- function(
                 fup = NULL,
                 chem.cas = NULL,
                 chem.name = NULL,
                 dtxsid = NULL,
                 parameters=NULL,
                 Flipid = NULL,
                 plasma.pH = 7.4,
                 dow74 = NULL,                          
                 species="Human",
                 default.to.human=FALSE,
                 force.human.fup=FALSE,
                 suppress.messages=FALSE,
                 chemdata=chem.physical_and_invitro.data
                 ) 
{
  #R CMD CHECK throws notes about "no visible binding for global variable", for
  #each time a data.table column name is used without quotes. To appease R CMD
  #CHECK, a variable has to be created for each of these column names and set to
  #NULL. Note that within the data.table, these variables will not be NULL! Yes,
  #this is pointless and annoying.
  Parameter <- NULL
  #End R CMD CHECK appeasement.

# We need to describe the chemical to be simulated one way or another:
  if (is.null(chem.cas) & 
      is.null(chem.name) & 
      is.null(dtxsid) &
      is.null(parameters)) 
    stop('Parameters, chem.name, chem.cas, or dtxsid must be specified.')

  if (is.null(parameters))
  {
    # Look up the chemical name/CAS, depending on what was provided:
    if (any(is.null(chem.cas),is.null(chem.name),is.null(dtxsid)))
    {
      out <- get_chem_id(chem.cas=chem.cas,
                         chem.name=chem.name,
                         dtxsid=dtxsid,
                         chemdata=chemdata)
      chem.cas <- out$chem.cas
      chem.name <- out$chem.name                                
      dtxsid <- out$dtxsid
    }
    # acid dissociation constants
    pKa_Donor <- suppressWarnings(get_physchem_param("pKa_Donor",
                                                     dtxsid=dtxsid,
                                                     chem.name=chem.name,
                                                     chem.cas=chem.cas,
                                                     chemdata=chemdata)) 
    # basic association cosntants
    pKa_Accept <- suppressWarnings(get_physchem_param("pKa_Accept",
                                                      dtxsid=dtxsid,
                                                      chem.name=chem.name,
                                                      chem.cas=chem.cas,
                                                      chemdata=chemdata)) 
    # Octanol:water partition coefficient
    Pow <- 10^get_physchem_param("logP",
                                 dtxsid=dtxsid,
                                 chem.name=chem.name,
                                 chem.cas=chem.cas,
                                 chemdata=chemdata)
    # Fraction unbound in plasma measured in vitro:
    if (is.null(fup)) fup <- get_fup(dtxsid=dtxsid,
                                     chem.name=chem.name,
                                     chem.cas=chem.cas,
                                     species=species,
                                     default.to.human=default.to.human,
                                     force.human.fup=force.human.fup,
                                     suppress.messages=suppress.messages,
                                     chemdata=chemdata)$Funbound.plasma.point 
  } else {
    if ("Funbound.plasma" %in% names(parameters))
    {
      if (is.null(fup)) fup <- parameters$Funbound.plasma 
    }
    if (all(c("Pow","pKa_Donor","pKa_Accept") 
      %in% names(parameters)))
    {
      Pow <- parameters$Pow
      pKa_Donor <- parameters$pKa_Donor
      pKa_Accept <- parameters$pKa_Accept
    } else if ("Dow74" %in% names(parameters)) {
      if (is.null(dow74)) dow74 <- parameters$Dow74
      if ("Pow" %in% names(parameters)) Pow <- parameters$Pow
      else Pow <- NA
    } else stop("Missing parameters needed in calc_fup_correction.")  
  }
  
  Pow <- min(Pow,1e6) # Octanal:water partitioning above 1:1000000 would likely take longer than hepatocyte assay
  
  # Grab the fraction of in vivo plasma that is lipid:
  if (!is.null(parameters))
    if ("Flipid" %in% names(parameters))
      Flipid <- parameters$Flipid

  if (is.null(Flipid))
  {
    if (force.human.fup) 
      Flipid <- subset(
                  physiology.data,
                  Parameter == 'Plasma Effective Neutral Lipid Volume Fraction')[,
                    which(colnames(physiology.data) == 'Human')]
    else Flipid <- subset(
                     physiology.data,
                     Parameter=='Plasma Effective Neutral Lipid Volume Fraction')[,
                       which(tolower(colnames(physiology.data)) == tolower(species))]
  }
        
 # Calculate Pearce (2017) in vitro plasma binding correction: 
  if (is.null(dow74))
  {  
    dow <- calc_dow(Pow=Pow,
                    pH=plasma.pH,
                    pKa_Donor=pKa_Donor,
                    pKa_Accept=pKa_Accept,
                    chemdata=chemdata
                  ) 
  } else dow <- dow74
  
  dow <- min(dow,1e6) # Octanal:water partitioning above 1:1000000 would likely take longer than hepatocyte assay
  
  fup.corrected <- 1 / ((dow) * Flipid + 1 / fup)
  fup.correction <- fup.corrected/fup
  
  return(set_httk_precision(fup.correction))
}
