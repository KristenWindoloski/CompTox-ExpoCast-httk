#' solve_gas_pbtk
#' 
#' This function solves for the amounts or concentrations of a chemical
#' in different tissues as functions of time as a result of inhalation 
#' exposure to an ideal gas.
#' In this PBTK formulation. \eqn{C_{tissue}} is the concentration in tissue at 
#' time t. Since the perfusion limited partition coefficients describe 
#' instantaneous equilibrium between the tissue and the free fraction in 
#' plasma, the whole plasma concentration is 
#' \eqn{C_{tissue,plasma} = \frac{1}{f_{up}*K_{tissue2fup}}*C_{tissue}}. 
#' Note that we use a single, 
#' constant value of \eqn{f_{up}} across all tissues. Corespondingly the free 
#' plasma 
#' concentration is modeled as 
#' \eqn{C_{tissue,free plasma} = \frac{1}{K_{tissue2fup}}*C_tissue}. 
#' The amount of blood flowing from tissue x is \eqn{Q_{tissue}} (L/h) at a 
#' concentration 
#' \eqn{C_{x,blood} = \frac{R_{b2p}}{f_{up}*K_{tissue2fup}}*C_{tissue}}, where 
#' we use a 
#' single \eqn{R_{b2p}} value throughout the body.
#' Metabolic clearance is modelled as being from the total plasma 
#' concentration here, though it is restricted to the free fraction in 
#' \code{\link{calc_hep_clearance}} by default. Renal clearance via 
#' glomerulsr filtration is from the free plasma concentration.
#' 
#' The default dosing scheme involves a specification of the start time
#' of exposure (exp.start.time), the concentration of gas inhaled (exp.conc),
#' the period of a cycle of exposure and non-exposure (period), the
#' duration of the exposure during that period (exp.duration), and the total
#' days simulated. Together,these arguments determine the "forcings" passed to
#' the ODE integrator. Forcings can also be specified manually, or effectively
#' turned off by setting exposure concentration to zero, if the user prefers to 
#' simulate dosing by other means. 
#' 
#' The "forcings" object is configured to be passed to the integrator with,
#' at the most, a basic unit conversion among ppmv, mg/L, and uM. No scaling by
#' BW is set to be performed on the forcings series.
#' 
#' Note that the model parameters have units of hours while the model output is
#' in days.
#' 
#' Default NULL value for doses.per.day solves for a single dose.
#' 
#' The compartments used in this model are the gut lumen, gut, liver, kidneys,
#' veins, arteries, lungs, and the rest of the body.
#' 
#' The extra compartments include the amounts or concentrations metabolized by
#' the liver and excreted by the kidneys through the tubules.
#' 
#' AUC is the area under the curve of the plasma concentration.
#' 
#' Model Figure from \insertCite{linakis2020development}{httk}:
#' \if{html}{\figure{gaspbtk.jpg}{options: width="100\%" alt="Figure: Gas PBTK 
#' Model Schematic"}}
#' \if{latex}{\figure{gaspbtk.pdf}{options: width=12cm alt="Figure: Gas PBTK 
#' Model Schematic"}}
#' 
#' Model parameters are named according to the following convention:\tabular{lrrrr}{
#' prefix \tab suffic \tab Meaning \tab units \cr
#' K \tab \tab Partition coefficient for tissue to free plasma \ tab unitless \cr
#' V \tab \tab Volume \tab L \cr
#' Q \tab \tab Flow \tab L/h \cr
#' k \tab \tab Rate \tab 1/h \cr
#' \tab c \tab Parameter is proportional to body weight \tab 1 / kg for volumes
#' and 1/kg^(3/4) for flows \cr}
#'
#' When species is specified but chemical-specific in vitro data are not
#' available, the function uses the appropriate physiological data (volumes and 
#' flows) but default.to.human = TRUE must be used to substitute human
#' fraction unbound, partition coefficients, and intrinsic hepatic clearance.
#'  
#' Per- and 
#' polyfluoroalkyl substances (PFAS) are excluded by default because the 
#' transporters that often drive PFAS toxicokinetics are not included in this 
#' model. However, PFAS chemicals can be included with the argument 
#' "class.exclude = FALSE".
#' 
#' @param chem.name Either the chemical name, CAS number, or the parameters
#' must be specified.
#' 
#' @param chem.cas Either the chemical name, CAS number, or the parameters must
#' be specified.
#' 
#' @param dtxsid EPA's DSSTox Structure ID (\url{https://comptox.epa.gov/dashboard})  
#' the chemical must be identified by either CAS, name, or DTXSIDs
#' 
#' @param parameters Chemical parameters from parameterize_gas_pbtk (or other
#' bespoke) function, overrides chem.name and chem.cas.
#' 
#' @param times Optional time sequence for specified number of days.  Dosing
#' sequence begins at the beginning of times.
#' 
#' @param days Length of the simulation.
#' 
#' @param tsteps The number of time steps per hour.
#' 
#' @param daily.dose Total daily dose
#' 
#' @param doses.per.day Number of doses per day.
#' 
#' @param dose Amount of a single dose
#' 
#' @param dosing.matrix Vector of dosing times or a matrix consisting of two
#' columns or rows named "dose" and "time" containing the time and amount of 
#' each dose. 
#' 
#' @param forcings Manual input of 'forcings' data series argument for ode
#' integrator. If left unspecified, 'forcings' defaults to NULL, and then other 
#' input parameters (see exp.start.time, exp.conc, exp.duration, and period)
#' provide the necessary information to assemble a forcings data series. 
#' 
#' @param exp.start.time Start time in specifying forcing exposure series,
#' default 0. 
#' 
#' @param exp.conc Specified inhalation exposure concentration for use in 
#' assembling "forcings" data series argument for integrator. Defaults to
#' units of ppmv.
#' 
#' @param period For use in assembling forcing function data series 'forcings'
#' argument, specified in hours
#' 
#' @param exp.duration For use in assembling forcing function data 
#' series 'forcings' argument, specified in hours
#' 
#' @param initial.values Vector containing the initial concentrations or
#' amounts of the chemical in specified tissues with units corresponding to
#' those specified for the model outputs. Default values are zero.
#' 
#' @param plots Plots all outputs if true.
#' 
#' @param suppress.messages Whether or not the output message is suppressed.
#' 
#' @param species Species desired (either "Rat", "Rabbit", "Dog", "Mouse", or
#' default "Human").
#' 
#' @param iv.dose Simulates a single i.v. dose if true.
#' 
#' @param input.units Input units of interest assigned to dosing, including 
#' forcings. Defaults to "ppmv" as applied to the default forcings scheme.
#' 
#' @param output.units A named vector of output units expected for the model
#' results. Default, NULL, returns model results in units specified in the
#' 'modelinfo' file. See table below for details.
#' 
#' @param default.to.human Substitutes missing animal values with human values
#' if true (hepatic intrinsic clearance or fraction of unbound plasma).
#' 
#' @param class.exclude Exclude chemical classes identified as outside of 
#' domain of applicability by relevant modelinfo_[MODEL] file (default TRUE).
#' 
#' @param physchem.exclude Exclude chemicals on the basis of physico-chemical
#' properties (currently only Henry's law constant) as specified by 
#' the relevant modelinfo_[MODEL] file (default TRUE).
#' 
#' @param recalc.blood2plasma Recalculates the ratio of the amount of chemical
#' in the blood to plasma using the input parameters, calculated with
#' hematocrit, Funbound.plasma, and Krbc2pu.
#' 
#' @param recalc.clearance Recalculates the hepatic clearance
#' (Clmetabolism) with new million.cells.per.gliver parameter.
#' 
#' @param adjusted.Funbound.plasma Uses adjusted Funbound.plasma when set to
#' TRUE along with partition coefficients calculated with this value.
#' 
#' @param regression Whether or not to use the regressions in calculating
#' partition coefficients.
#' 
#' @param restrictive.clearance Protein binding not taken into account (set to
#' 1) in liver clearance if FALSE. (Default is FALSE.)
#' 
#' @param minimum.Funbound.plasma Monte Carlo draws less than this value are set 
#' equal to this value (default is 0.0001 -- half the lowest measured Fup in our
#' dataset).
#' 
#' @param monitor.vars Which variables are returned as a function of time. 
#' Defaults value of NULL provides "Cgut", "Cliver", "Cven", "Clung", "Cart",
#' "Crest", "Ckidney", "Cplasma", "Calv", "Cendexh", "Cmixexh", "Cmuc", 
#' "Atubules", "Ametabolized", "AUC"
#' 
#' @param vmax Michaelis-Menten vmax value in reactions/min
#' 
#' @param km Michaelis-Menten concentration of half-maximal reaction velocity
#' in desired output concentration units. 
#' 
#' @param exercise Logical indicator of whether to simulate an exercise-induced
#' heightened respiration rate
#' 
#' @param fR Respiratory frequency (breaths/minute), used especially to adjust
#' breathing rate in the case of exercise. This parameter, along with VT and VD
#' (below) gives another option for calculating Qalv (Alveolar ventilation) 
#' in case pulmonary ventilation rate is not known 
#' 
#' @param VT Tidal volume (L), to be modulated especially as part of simulating
#' the state of exercise
#' 
#' @param VD Anatomical dead space (L), to be modulated especially as part of
#' simulating the state of exercise
#' 
#' @param ... Additional arguments passed to the integrator (deSolve).
#' (Note: There are precision differences between M1 Mac and other OS systems
#' for this function due to how long doubles are handled. To replicate results
#' between various OS systems we suggest changing the default method of "lsoda"
#' to "lsode" and also adding the argument mf = 10.
#' See [deSolve::ode()] for further details.)
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
#' @return A matrix of class deSolve with a column for time(in days), each
#' compartment, the area under the curve, and plasma concentration and a row
#' for each time point.
#'
#' @author Matt Linakis, John Wambaugh, Mark Sfeir, Miyuki Breen
#'
#' @references 
#' \insertRef{linakis2020development}{httk}
#'
#' @keywords Solve
#'
#' @seealso \code{\link{solve_model}}
#'
#' @seealso \code{\link{parameterize_gas_pbtk}}
#'
#' @examples
#' \donttest{
#' 
#' solve_gas_pbtk(chem.name = 'pyrene', exp.conc = 1, period = 24, expduration = 24)
#' 
#' out <- solve_gas_pbtk(chem.name='pyrene',
#'                       exp.conc = 0, doses.per.day = 2,
#'                       daily.dose = 3, input.units = "umol",
#'                       days=2.5, 
#'                       plots=TRUE, initial.values=c(Aven=20))
#' 
#' out <- solve_gas_pbtk(chem.name = 'pyrene', exp.conc = 3, 
#'                       period = 24, days=2.5,
#'                       exp.duration = 6, exercise = TRUE)
#'                   
#' params <- parameterize_gas_pbtk(chem.cas="80-05-7")
#' solve_gas_pbtk(parameters=params, days=2.5)
#' 
#' # Oral dose with exhalation as a route of elimination:
#' out <- solve_gas_pbtk(chem.name = 'bisphenol a', exp.conc = 0, dose=100,
#'                       days=2.5, input.units="mg/kg")
#'
#' # Note that different model compartments for this model have different units 
#' # and that the final units can be controlled with the output.units argument:
#' head(solve_gas_pbtk(chem.name="lindane", days=2.5))
#' # Convert all compartment units to mg/L:
#' head(solve_gas_pbtk(chem.name="lindane", days=2.5, output.units="mg/L"))
#' # Convert just the plasma to mg/L:
#' head(solve_gas_pbtk(chem.name="lindane", days=2.5, 
#'                     output.units=list(Cplasma="mg/L")))
#'
#' signif(head(solve_gas_pbtk(chem.cas="129-00-0",times=c(0,0.1,0.05),
#'                     method = "lsode",mf = 10)),2)
#' signif(head(solve_gas_pbtk(
#'   parameters=parameterize_gas_pbtk(chem.cas="129-00-0"),
#'   times=c(0,0.1,0.05),
#'   method = "lsode",mf = 10)),2)
#' }
#' 
#' @export solve_gas_pbtk
#' 
#' @importFrom Rdpack reprompt
solve_gas_pbtk <- function(chem.name = NULL,
                           chem.cas = NULL,
                           dtxsid = NULL,
                           parameters=NULL,
                           times=NULL,
                           days=10,
                           tsteps = 4, #tsteps is number of steps per hour
                           daily.dose = NULL,
                           doses.per.day = NULL,
                           dose = NULL, 
                           dosing.matrix = NULL,
                           forcings = NULL,
                           exp.start.time = 0, #default starting time in specifying forcing exposure
                           exp.conc = 1, #default exposure concentration for forcing data series
                           period = 24, 
                           exp.duration = 12,
                           initial.values=NULL,
                           plots=FALSE,
                           suppress.messages=FALSE,
                           species="Human",
                           iv.dose=FALSE,
                           input.units = "ppmv", # assume input units are ppmv with updated inhalation model
                           # input.units = "uM",
                           output.units=NULL,
                           default.to.human=FALSE,
                           class.exclude=TRUE,
                           physchem.exclude = TRUE,
                           recalc.blood2plasma=FALSE,
                           recalc.clearance=FALSE,
                           adjusted.Funbound.plasma=TRUE,
                           regression=TRUE,
                           restrictive.clearance = FALSE,
                           minimum.Funbound.plasma=0.0001,
                           monitor.vars=NULL,
                           vmax = 0,
                           km = 1,
                           exercise = FALSE,
                           fR = 12,
                           VT = 0.75,
                           VD = 0.15,
                           Caco2.options = list(),
                           chemdata=chem.physical_and_invitro.data,
                           ...)
{
  
  #Screen against error in user's specification of forcing function timing
  if (exp.duration > period){
  stop("Argument 'exp.duration' should be smaller than its subsuming argument,
       'period', which together are set to specify a simple cyclic pattern of 
       inhalation exposure and rest in the default case.")
  }
  
  # Screen whether exposure and dosing are both indicated to occur
  if((exp.conc!=0 | is.null(forcings)==FALSE) & (is.null(dose)==FALSE | is.null(daily.dose)==FALSE)){
    stop("Currently, 'httk' only evaluates the model using the exposure or dose",
         " route but not both simultaneously. If exposure is the goal, then",
         " set dose and/or daily.dose to NULL.  If dose is the goal, then",
         " set exp.conc to 0.")
  }
  
  # Obtain the appropriate route for compound exposure/dosing.
  if(exp.conc!=0 | is.null(forcings)==FALSE){
    route <- "inhalation"
    
    # if(input.units!="ppmv"){
    #   stop("The ",input.units," units are not appropriate for the exposure route. ",
    #        "Review input units for doses and update argument. ",
    #        "Several suggestions 'umol', 'mg', or an alternative input.")
    # }
  }else if(is.null(dose)==FALSE | is.null(daily.dose)==FALSE){
    route <- ifelse(iv.dose,yes = "iv",no = "oral")
    
    if(input.units=="ppmv"){
      stop("The 'ppmv' units are not appropriate for the dosing routes. ",
           "Review input units for doses and update argument. ",
           "Several suggestions 'umol', 'mg', or an alternative input.")
    }
  }
  
  #Look up the chemical name/CAS to get some info about the chemical in
  #question and screen it for relevance of its logHenry value. Should not
  #be necessary if user manually specifies 'parameters'
  if (is.null(parameters)){
  out <- get_chem_id(
    chem.cas=chem.cas,
    chem.name=chem.name,
    dtxsid=dtxsid)
  chem.cas <- out$chem.cas
  chem.name <- out$chem.name                                
  dtxsid <- out$dtxsid
  
  
  #If value of Henry's law constant associated with queried chemical is smaller
  #than that of glycerol, generally considered non-volatile, issue warning
  #message:
 
    #get associated logHenry value and compare against glycerol's value, obtained
    #from EPA dashboard
    logHenry = chemdata[chem.cas,'logHenry']
    if (is.na(logHenry)) stop (
"Henry's constant is not available for this compound")
    glycerol_logHenry = -7.80388
    if (logHenry <= glycerol_logHenry){ 
    warning("Henry's constant, as a measure of volatility, is smaller for the
    queried chemical than for glycerol, a chemical generally considered
    nonvolatile. Please proceed after having considered whether the inhalation
    exposure route is nonetheless relevant.")
    }
  }
  
  #Only generate the forcings if other dosing metrics are null; they're not
  #designed to work together in a very meaningful way
  if (is.null(dosing.matrix) & is.null(doses.per.day) & is.null(forcings))
  {
    if (exp.duration > period){
      stop('If not specifying \'dose.matrix\' data series explicitly, 
      additional arguments are needed to generate a \'dose.matrix\' argument
      with a cyclic exposure pattern across the simulation:
      exp.conc, period, exp.start.time, exp.duration, and days simulated.')
    }
    period <- period/24 #convert time period in hours to days
    exp.duration <- exp.duration/24 #convert exposure duration in hours to days
    
    #Assemble function for initializing 'forcings' argument data series with
    #certain periodicity and exposure concentration in default case, used if 
    #the 'forcings' argument is not otherwise specified.
    forcings_gen <- function(exp.conc, period, exp.start.time, exp.duration, days) {
      #Provide for case in which forcing functionality is effectively turned off
      if (exp.conc == 0) {
        conc.matrix = NULL
      } else if (period == 0) {
        conc.matrix = matrix(c(exp.start.time,exp.conc), nrow=1)
        colnames(conc.matrix <- c("times","forcing_values"))
      } else {
        Nrep <- ceiling((days - exp.start.time)/period) 
        times <- rep(c(exp.start.time, exp.duration), Nrep) + rep(period * (0:(Nrep - 1)), rep(2, Nrep))
        forcing_values  <- rep(c(exp.conc,0), Nrep)
        conc.matrix = cbind(times,forcing_values)
      }
      return(conc.matrix)
    }

    forcings = forcings_gen(exp.conc, period, exp.start.time = 0, exp.duration, days) 
  }
      
  # Describe the dose regimen:
  dosing <- list(
    initial.dose=dose,
    dosing.matrix=dosing.matrix,
    daily.dose=daily.dose,
    doses.per.day=doses.per.day,
    forcings=forcings
    )
  # Limit to only the needed dosing parameters:
  dosing <- dosing[names(dosing) %in%
                     model.list[["gas_pbtk"]]$routes[[route]]$dosing.params]
  
  #Now make call to solve_model with gas model specific arguments configured 
  out <- solve_model(
    chem.name = chem.name,
    chem.cas = chem.cas,
    dtxsid=dtxsid,
    times=times,
    parameters=parameters,
    model="gas_pbtk",
    route=route,
    dosing=dosing,
    days=days,
    tsteps = tsteps, # tsteps is number of steps per hour
    initial.values=initial.values,
    plots=plots,
    monitor.vars=monitor.vars,
    suppress.messages=suppress.messages,
    species=species,
    input.units=input.units,
    output.units=output.units,
    recalc.blood2plasma=recalc.blood2plasma,
    recalc.clearance=recalc.clearance,
    adjusted.Funbound.plasma=adjusted.Funbound.plasma,
    parameterize.args.list = list(
      regression=regression,
      default.to.human=default.to.human,
      class.exclude=class.exclude,
      physchem.exclude = physchem.exclude,
      restrictive.clearance = restrictive.clearance,
      exercise = exercise,
      vmax = vmax,
      km = km,
      fR = fR,
      VT = VT,
      VD = VD,
      Caco2.options = Caco2.options),
    minimum.Funbound.plasma=minimum.Funbound.plasma,
    ...)
  
  return(out)
}

