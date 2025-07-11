#' Parameters for a one compartment (empirical) toxicokinetic model
#' 
#' This function initializes the parameters needed in the function solve_1comp.
#' Volume of distribution is estimated by using a modified Schmitt (2008) method
#' to predict tissue particition coefficients (Pearce et al., 2017) and then
#' lumping the compartments weighted by tissue volume:
#'
#' \if{latex}{
#' \eqn{V_{d,steady-state} = \Sigma_{i\in tissues}K_{i}V_{i} + V_{plasma}}
#' }
#' \if{html}{
#' V_d,steady-state = Sum over all tissues (K_i * V_i) + V_plasma
#' }
#'
#' where K_i is the tissue:unbound plasma concentration partition coefficient
#' for tissue i.
#' 
#' Because this model does not simulate exhalation, inhalation, and other 
#' processes relevant to volatile chemicals, this model is by default 
#' restricted to chemicals with a logHenry's Law Constant less than that of 
#' Acetone, a known volatile chemical. That is, chemicals with logHLC > -4.5 
#' (Log10 atm-m3/mole) are excluded. Volatility is not purely determined by the 
#' Henry's Law Constant, therefore this chemical exclusion may be turned off 
#' with the argument "physchem.exclude = FALSE". Similarly, per- and 
#' polyfluoroalkyl substances (PFAS) are excluded by default because the 
#' transporters that often drive PFAS toxicokinetics are not included in this 
#' model. However, PFAS chemicals can be included with the argument 
#' "class.exclude = FALSE".
#'
#' @param chem.cas Chemical Abstract Services Registry Number (CAS-RN) -- the 
#' chemical must be identified by either CAS, name, or DTXISD
#' 
#' @param chem.name Chemical name (spaces and capitalization ignored) --  the 
#' chemical must be identified by either CAS, name, or DTXISD
#' 
#' @param dtxsid EPA's DSSTox Structure ID (\url{https://comptox.epa.gov/dashboard})  
#' -- the chemical must be identified by either CAS, name, or DTXSIDs
#' 
#' @param species Species desired (either "Rat", "Rabbit", "Dog", "Mouse", or
#' default "Human").
#' 
#' @param default.to.human Substitutes missing rat values with human values if
#' true.
#' 
#' @param class.exclude Exclude chemical classes identified as outside of 
#' domain of applicability by relevant modelinfo_[MODEL] file (default TRUE).
#' 
#' @param physchem.exclude Exclude chemicals on the basis of physico-chemical
#' properties (currently only Henry's law constant) as specified by 
#' the relevant modelinfo_[MODEL] file (default TRUE).
#'
#' @param adjusted.Funbound.plasma Uses Pearce et al. (2017) lipid binding adjustment
#' for Funbound.plasma (which impacts volume of distribution) when set to TRUE (Default).
#' 
#' @param adjusted.Clint Uses Kilford et al. (2008) hepatocyte incubation
#' binding adjustment for Clint when set to TRUE (Default).
#' 
#' @param regression Whether or not to use the regressions in calculating
#' partition coefficients in volume of distribution calculation.
#' 
#' @param restrictive.clearance In calculating elimination rate and hepatic
#' bioavailability, protein binding is not taken into account (set to 1) in
#' liver clearance if FALSE.
#' 
#' @param well.stirred.correction Uses correction in calculation of hepatic
#' clearance for well-stirred model if TRUE.  This assumes clearance relative
#' to amount unbound in whole blood instead of plasma, but converted to use
#' with plasma concentration.
#' 
#' @param suppress.messages Whether or not to suppress messages.
#' 
#' @param clint.pvalue.threshold Hepatic clearance for chemicals where the in
#' vitro clearance assay result has a p-value greater than the threshold are
#' set to zero.
#' 
#' @param minimum.Funbound.plasma Monte Carlo draws less than this value are set 
#' equal to this value (default is 0.0001 -- half the lowest measured Fup in our
#' dataset).
#' 
#' @param Caco2.options A list of options to use when working with Caco2 apical 
#' to basolateral data \code{Caco2.Pab}, default is Caco2.options = 
#' list(Caco2.Pab.default = 1.6, Caco2.Fabs = TRUE, Caco2.Fgut = TRUE, 
#' overwrite.invivo = FALSE, keepit100 = FALSE). Caco2.Pab.default sets the 
#' default value for Caco2.Pab if Caco2.Pab is unavailable. Caco2.Fabs = TRUE 
#' uses Caco2.Pab to calculate fabs.oral, otherwise fabs.oral = \code{Fabs}. 
#' Caco2.Fgut = TRUE uses Caco2.Pab to calculate 
#' fgut.oral, otherwise fgut.oral = \code{Fgut}. overwrite.invivo = TRUE 
#' overwrites Fabs and Fgut in vivo values from literature with 
#' Caco2 derived values if available. keepit100 = TRUE overwrites Fabs and Fgut 
#' with 1 (i.e. 100 percent) regardless of other settings.
#' See \code{\link{get_fbio}} for further details.
#' 
#' @param ... Additional arguments, not currently used.
#' 
#' @return \item{Vdist}{Volume of distribution, units of L/kg BW.}
#' \item{Fabsgut}{Fraction of the oral dose absorbed and surviving gut metabolism, i.e. the 
#' fraction of the dose that enters the gutlumen.} \item{kelim}{Elimination rate, units of
#' 1/h.} \item{hematocrit}{Percent volume of red blood cells in the blood.}
#' \item{Fabsgut}{Fraction of the oral dose absorbed, i.e. the fraction of the
#' dose that enters the gutlumen.} 
#' \item{Fhep.assay.correction}{The fraction of chemical unbound in hepatocyte 
#' assay using the method of Kilford et al. (2008)} 
#' \item{kelim}{Elimination rate, units of 1/h.} 
#' \item{hematocrit}{Percent volume of red blood cells in the blood.}
#' \item{kgutabs}{Rate chemical is absorbed, 1/h.}
#' \item{million.cells.per.gliver}{Millions cells per gram of liver tissue.}
#' \item{MW}{Molecular Weight, g/mol.} 
#' \item{Rblood2plasma}{The ratio of the concentration of the chemical in the 
#' blood to the concentration in the plasma. Not used in calculations but 
#' included for the conversion of plasma outputs.} 
#' \item{hepatic.bioavailability}{Fraction of dose remaining after
#' first pass clearance, calculated from the corrected well-stirred model.}
#' \item{BW}{Body Weight, kg.} 
#'
#' @author John Wambaugh and Robert Pearce
#'
#' @references 
#'
#' \insertRef{pearce2017httk}{httk}
#'
#' \insertRef{schmitt2008general}{httk}
#'
#' \insertRef{pearce2017evaluation}{httk}
#'
#' \insertRef{kilford2008hepatocellular}{httk} 
#'
#' @keywords Parameter 1compartment
#'
#' @seealso \code{\link{solve_1comp}}
#'
#' @seealso \code{\link{calc_analytic_css_1comp}}
#'
#' @seealso \code{\link{calc_vdist}}
#'
#' @seealso \code{\link{parameterize_steadystate}}
#'
#' @seealso \code{\link{apply_clint_adjustment}}
#'
#' @seealso \code{\link{tissue.data}}
#'
#' @seealso \code{\link{physiology.data}}
#'
#' @examples
#' 
#' \donttest{
#'  parameters1 <- parameterize_1comp(chem.name='Bisphenol-A',species='Rat')
#'  parameters2 <- parameterize_1comp(chem.cas='80-05-7',
#'                                   restrictive.clearance=FALSE,
#'                                   species='rabbit',
#'                                   default.to.human=TRUE)
#' # The following will not work because Diquat dibromide monohydrate's 
#' # Henry's Law Constant (-3.912) is higher than that of Acetone (~-4.5):
#' try(parameters3 <- parameterize_1comp(chem.cas = "6385-62-2"))
#' # However, we can turn off checking for phys-chem properties, since we know
#' # that  Diquat dibromide monohydrate is not too volatile:
#' parameters3 <- parameterize_1comp(chem.cas = "6385-62-2",
#'                                   physchem.exclude = FALSE)
#' out <- solve_1comp(parameters=parameters1, days=1)
#' }
#'
#' @export parameterize_1comp
parameterize_1comp <- function(
                        chem.cas=NULL,
                        chem.name=NULL,
                        dtxsid = NULL,
                        species='Human',
                        default.to.human=FALSE,
                        adjusted.Funbound.plasma=TRUE,
                        adjusted.Clint=TRUE,
                        regression=TRUE,
                        restrictive.clearance=TRUE,
                        well.stirred.correction=TRUE,
                        suppress.messages=FALSE,
                        clint.pvalue.threshold=0.05,
                        minimum.Funbound.plasma=0.0001,
                        class.exclude=TRUE,
                        physchem.exclude = TRUE,
                        Caco2.options = list(),
                        chemdata=chem.physical_and_invitro.data
                        ...
                        )
{
#R CMD CHECK throws notes about "no visible binding for global variable", for
#each time a data.table column name is used without quotes. To appease R CMD
#CHECK, a variable has to be created for each of these column names and set to
#NULL. Note that within the data.table, these variables will not be NULL! Yes,
#this is pointless and annoying.
  physiology.data <- physiology.data
#End R CMD CHECK appeasement.  
  
# We need to describe the chemical to be simulated one way or another:
  if (is.null(chem.cas) & 
      is.null(chem.name) & 
      is.null(dtxsid)) 
    stop('chem.name, chem.cas, or dtxsid must be specified.')

# Look up the chemical name/CAS, depending on what was provide:
    out <- get_chem_id(
            chem.cas=chem.cas,
            chem.name=chem.name,
            dtxsid=dtxsid)
    chem.cas <- out$chem.cas
    chem.name <- out$chem.name                                
    dtxsid <- out$dtxsid
    
    # Make sure we have all the parameters we need:
    check_model(chem.cas=chem.cas, 
                chem.name=chem.name,
                dtxsid=dtxsid,
                model="1compartment",
                species=species,
                class.exclude=class.exclude,
                physchem.exclude=physchem.exclude,
                default.to.human=default.to.human)
    
    #Check also to make sure we can use steady-state model,
    #since we need to be able to call parameterize_steadystate
    
    check_model(chem.cas=chem.cas, 
                chem.name=chem.name,
                dtxsid=dtxsid,
                model="3compartmentss",
                species=species,
                class.exclude=class.exclude,
                physchem.exclude=physchem.exclude,
                default.to.human=default.to.human)
     
  params <- list()
  params[['Vdist']] <- calc_vdist(
                         chem.cas=chem.cas,
                         chem.name=chem.name,
                         dtxsid=dtxsid,
                         species=species,
                         default.to.human=default.to.human,
                         class.exclude=class.exclude,
                         adjusted.Funbound.plasma=adjusted.Funbound.plasma,
                         regression=regression,
                         suppress.messages=suppress.messages,
                         minimum.Funbound.plasma = minimum.Funbound.plasma)
  
  ss.params <- suppressWarnings(parameterize_steadystate(
                                  chem.name=chem.name,
                                  chem.cas=chem.cas,
                                  dtxsid=dtxsid,
                                  species=species,
                                  default.to.human=default.to.human,
                                  adjusted.Funbound.plasma=
                                    adjusted.Funbound.plasma,
                                  adjusted.Clint=adjusted.Clint,
                                  restrictive.clearance=restrictive.clearance,
                                  clint.pvalue.threshold=clint.pvalue.threshold,
                                  minimum.Funbound.plasma=
                                    minimum.Funbound.plasma,
                                  class.exclude = class.exclude,
                                  physchem.exclude = physchem.exclude,
                                  Caco2.options = Caco2.options))
  ss.params <- c(ss.params, params['Vdist'])
  
  params[['kelim']] <- calc_elimination_rate(parameters=ss.params,
                         chem.cas=chem.cas,
                         chem.name=chem.name,
                         dtxsid=dtxsid,
                         species=species,
                         suppress.messages=TRUE,
                         default.to.human=default.to.human,
                         adjusted.Funbound.plasma=adjusted.Funbound.plasma,
                         adjusted.Clint=adjusted.Clint,
                         regression=regression,
                         restrictive.clearance=restrictive.clearance,
                         well.stirred.correction=well.stirred.correction,
                         clint.pvalue.threshold=clint.pvalue.threshold,
                         minimum.Funbound.plasma=minimum.Funbound.plasma)
  
  params[["Clint"]] <- ss.params[["Clint"]]
  params[["Clint.dist"]] <- ss.params[["Clint.dist"]]
  params[["Funbound.plasma"]] <- ss.params[["Funbound.plasma"]] 
  params[["Funbound.plasma.dist"]] <- ss.params[["Funbound.plasma.dist"]] 
  params[["Funbound.plasma.adjustment"]] <- 
    ss.params[["Funbound.plasma.adjustment"]] 
  params[["Fhep.assay.correction"]] <- ss.params[["Fhep.assay.correction"]]
  params[["Funbound.plasma.dist"]] <- ss.params[["Funbound.plasma.dist"]] 
  phys.params <-  suppressWarnings(parameterize_schmitt(chem.name=chem.name,
                    chem.cas=chem.cas,
                    species=species,
                    default.to.human=default.to.human,
                    minimum.Funbound.plasma=minimum.Funbound.plasma)) 
  params[["Pow"]] <- phys.params[["Pow"]]
  params[["pKa_Donor"]] <- phys.params[["pKa_Donor"]] 
  params[["pKa_Accept"]] <- phys.params[["pKa_Accept"]]
  params[["MA"]] <- phys.params[["MA"]]

  params[['kgutabs']] <- 2.18
  
  params[['Rblood2plasma']] <- 
    available_rblood2plasma(chem.cas=chem.cas,
                            chem.name=chem.name,
                            species=species,
                            adjusted.Funbound.plasma=adjusted.Funbound.plasma,
                            chemdata=chemdata)
  
  params[['million.cells.per.gliver']] <- 110
  params[["liver.density"]] <- 1.05 # g/mL
   
# Check the species argument for capitalization problems and whether or not 
# it is in the table:  
  if (!(species %in% colnames(physiology.data)))
  {
    if (toupper(species) %in% toupper(colnames(physiology.data)))
    {
      phys.species <- colnames(physiology.data)[
                        toupper(colnames(physiology.data))==toupper(species)]
    } else stop(paste("Physiological PK data for",species,"not found."))
  } else phys.species <- species

# Load the physiological parameters for this species
  this.phys.data <- physiology.data[,phys.species]
  names(this.phys.data) <- physiology.data[,1]
  
    
  params[['hematocrit']] <- this.phys.data[["Hematocrit"]]
  params[['plasma.vol']] <- this.phys.data[["Plasma Volume"]]/1000 # L/kg BW

  params[['MW']] <- get_physchem_param("MW",chem.cas=chem.cas)

  params[['Fabsgut']] <- ss.params[['Fabsgut']]
  params[['Fabs']] <- ss.params[['Fabs']]
  params[['Fgut']] <- ss.params[['Fgut']]
  params[["Caco2.Pab"]] <- ss.params[['Caco2.Pab']]
  params[["Caco2.Pab.dist"]] <- ss.params[['Caco2.Pab.dist']]
  
  params[['hepatic.bioavailability']] <- 
    ss.params[['hepatic.bioavailability']]  
  params[['BW']] <- this.phys.data[["Average BW"]]
  
  return(lapply(params[model.list[["1compartment"]]$param.names],
                set_httk_precision))
}
