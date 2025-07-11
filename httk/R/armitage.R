#' Estimate well surface area
#' 
#' Estimate geometry surface area of plastic in well plate based on well plate
#' format suggested values from Corning.  option.plastic == TRUE (default) give
#' nonzero surface area (sarea, m^2) option.bottom == TRUE (default) includes
#' surface area of the bottom of the well in determining sarea.  Optionally
#' include user values for working volume (v_working, m^3) and surface area.
#' 
#' 
#' @param tcdata A data table with well_number corresponding to plate format,
#' optionally include v_working, sarea, option.bottom, and option.plastic
#' 
#' @param this.well_number For single value, plate format default is 384, used
#' if is.na(tcdata)==TRUE
#' 
#' @param this.cell_yield For single value, optionally supply cell_yield,
#' otherwise estimated based on well number
#' 
#' @param this.v_working For single value, optionally supply working volume,
#' otherwise estimated based on well number (m^3)
#' 
#' @return A data table composed of any input data.table \emph{tcdata}
#' with only the following columns either created or altered by this function:  
#' \tabular{ccc}{
#' \strong{Column Name} \tab \strong{Description} \tab \strong{Units} \cr
#' well_number \tab number of wells on plate \tab \cr
#' sarea \tab surface area \tab m^2 \cr
#' cell_yield \tab number of cells \tab cells \cr 
#' v_working \tab working (filled) volume of each well \tab uL \cr
#' v_total \tab total volume of each well \tab uL \cr
#' }
#'
#' @author Greg Honda
#'
#' @references 
#' \insertRef{armitage2014application}{httk} 
#'
#' \insertRef{honda2019using}{httk}
#'
#' @import magrittr
#'
#' @export armitage_estimate_sarea
armitage_estimate_sarea <- function(tcdata = NA, # optionally supply columns v_working,sarea, option.bottom, and option.plastic
                                    this.well_number = 384,
                                    this.cell_yield = NA,
                                    this.v_working = NA){
  #R CMD CHECK throws notes about "no visible binding for global variable", for
  #each time a data.table column name is used without quotes. To appease R CMD
  #CHECK, a variable has to be created for each of these column names and set to
  #NULL. Note that within the data.table, these variables will not be NULL! Yes,
  #this is pointless and annoying.
  well_number<-well_desc<-radius<-diam<-v_working<-NULL
  v_working_est<-sysID<-height<-option.bottom<-sarea_c<-option.plastic<-NULL
  sarea<-cell_yield<-cell_yield_est<-NULL
  #End R CMD CHECK appeasement.
  
  if(all(is.na(tcdata))){
    tcdata <- data.table(well_number = this.well_number, cell_yield = this.cell_yield, v_working = this.v_working)
  }
  
  if(!(all(c("option.bottom","option.plastic") %in% names(tcdata)))){
      tcdata[,c("option.bottom","option.plastic")[!(c("option.bottom","option.plastic")%in%names(tcdata))]] <- as.logical(NA)
  }

  if(!(all(c("sarea","cell_yield","v_working")%in%names(tcdata)))){
      tcdata[,c("sarea","cell_yield","v_working")[!(c("sarea","cell_yield","v_working")%in%names(tcdata))]] <- as.double(NA)
  }

  well.desc.list <- c("flat_bottom","standard","clear_flat_bottom")
  well.number.list <- c(6,12,24,48)
  well.param <- copy(well_param)[well_number %in% well.number.list |
                             well_desc %in% well.desc.list]

  setnames(well.param,c("cell_yield","v_working"),c("cell_yield_est","v_working_est"))


  tcdata <- well.param[tcdata,on=.(well_number)]

  tcdata[,radius:=diam/2] %>%  # mm
    .[is.na(v_working), v_working:=as.numeric(v_working_est)] %>%
    .[sysID %in% c(7,9), height:= v_working/(diam^2)] %>%  #mm for square wells
    .[is.na(option.bottom),option.bottom:=TRUE] %>%
    .[option.bottom==TRUE & (sysID %in% c(7,9)),sarea_c := 4*diam*height+diam^2] %>% #mm2
    .[option.bottom==FALSE & (sysID %in% c(7,9)),sarea_c := 4*diam*height] %>%
    .[!(sysID %in% c(7,9)),height:=v_working/(pi*radius^2)] %>% # for cylindrical wells
    .[option.bottom==TRUE & !(sysID %in% c(7,9)), sarea_c := 2*pi*radius*height+pi*radius^2] %>%  #mm2
    .[option.bottom==FALSE & !(sysID %in% c(7,9)), sarea_c := 2*pi*radius*height] %>%
    .[is.na(option.plastic),option.plastic:=TRUE] %>%
    .[,sarea_c:=sarea_c/1e6] %>% #mm2 to m2
    .[option.plastic==FALSE, sarea_c:=0] %>%
    .[is.na(sarea),sarea:=sarea_c] %>%
    .[is.na(cell_yield),cell_yield:=as.double(cell_yield_est)]

   return(tcdata)
}





#' Evaluate the updated Armitage model
#' 
#' Evaluate the Armitage model for chemical distributon \emph{in vitro}. Takes input
#' as data table or vectors of values. Outputs a data table. Updates over
#' the model published in Armitage et al. (2014) include binding to plastic walls
#' and lipid and protein compartments in cells.
#' 
#' @param chem.name A single or vector of name(s)) of desired chemical(s).
#' @param chem.cas A single or vector of Chemical Abstracts Service Registry 
#' Number(s) (CAS-RN) of desired chemical(s).
#' @param dtxsid A single or vector ofEPA's DSSTox Structure ID(s) 
#' (\url{https://comptox.epa.gov/dashboard})  
#' 
#' @param casrn.vector A deprecated argument specifying a single or vector of 
#' Chemical Abstracts Service Registry 
#' Number(s) (CAS-RN) of desired chemical(s).
#' 
#' @param nomconc.vector For vector or single value, micromolar (uM = umol/L) nominal 
#' concentration (e.g. AC50 value)
#' 
#' @param this.well_number For single value, plate format default is 384, used
#' if is.na(tcdata)==TRUE. This value chooses default surface area settings for
#' \code{\link{armitage_estimate_sarea}} based on the number of plates per well.
#' 
#' @param this.FBSf Fraction fetal bovine serum, must be entered by user.
#' 
#' @param tcdata A data.table with casrn, nomconc, MP, gkow, gkaw, gswat, sarea,
#' v_total, v_working. Otherwise supply single values to this.params (e.g., this.sarea,
#' this.v_total, etc.). Chemical parameters are taken from 
#' \code{\link{chem.physical_and_invitro.data}}.
#' 
#' @param this.sarea Surface area per well (m^2)
#' 
#' @param this.v_total Total volume per well (uL)
#' 
#' @param this.v_working Working volume per well (uL)
#' 
#' @param this.cell_yield Number of cells per well
#' 
#' @param this.Tsys System temperature (degrees C)
#' 
#' @param this.Tref Reference temperature (degrees K)
#' 
#' @param this.option.kbsa2 Use alternative bovine-serum-albumin partitioning
#' model
#' 
#' @param this.option.swat2 Use alternative water solubility correction
#' 
#' @param this.pseudooct Pseudo-octanol cell storage lipid content
#' 
#' @param this.memblip Membrane lipid content of cells
#' 
#' @param this.nlom Structural protein content of cells
#' 
#' @param this.P_nlom Proportionality constant to octanol structural protein
#' 
#' @param this.P_dom Proportionality constant to dissolve organic material
#' 
#' @param this.P_cells Proportionality constant to octanol storage lipid
#' 
#' @param this.csalt Ionic strength of buffer (M = mol/L)
#' 
#' @param this.celldensity Cell density kg/L, g/mL
#' 
#' @param this.cellmass Mass per cell, ng/cell
#'
#' @param this.f_oc Everything assumed to be like proteins
#' 
#' @param this.conc_ser_alb Mass concentration of albumin in serum (g/L)
#' 
#' @param this.conc_ser_lip Mass concentration of lipids in serum (g/L)
#' 
#' @param this.Vdom The volume of dissolved organic matter or DOM (mL)
#' 
#' @param this.pH pH of cell culture
#' 
#' @param this.Vdom 0 ml, the volume of dissolved organic matter (DOM)
#' 
#' @param this.pH 7.0, pH of cell culture
#' 
#' @param restrict.ion.partitioning FALSE, Should we restrict the chemical available to partition to only the neutral fraction?
#'
#' @return
#' \tabular{lll}{
#' \strong{Param} \tab \strong{Description} \tab \strong{Units} \cr
#' casrn \tab Chemical Abstracts Service Registry Number \tab character \cr
#' nomconc \tab Nominal Concentration \tab uM=umol/L \cr       
#' well_number \tab Number of wells in plate (used to set default surface area) \tab unitless \cr   
#' sarea \tab Surface area of well \tab m^2 \cr         
#' v_total \tab Total volume of well \tab uL \cr       
#' v_working \tab Filled volume of well \tab uL \cr     
#' cell_yield \tab Number of cells \tab cells \cr    
#' gkow \tab The log10 octanol to water (PC) (logP)\tab log10 unitless ratio \cr          
#' logHenry \tab The log10 Henry's law constant '\tab log10 unitless ratio \cr      
#' gswat \tab The log10 water solubility (logWSol) \tab log10 mg/L \cr         
#' MP \tab The chemical compound melting point \tab degrees Kelvin \cr           
#' MW \tab The chemical compound molecular weight \tab g/mol \cr            
#' gkaw \tab The air to water PC \tab unitless ratio \cr          
#' dsm \tab \tab \cr           
#' duow \tab \tab \cr          
#' duaw \tab \tab \cr          
#' dumw \tab \tab \cr          
#' gkmw \tab log10 \tab \cr          
#' gkcw \tab The log10 cell/tissue to water PC \tab log10 unitless ratio\cr          
#' gkbsa \tab The log10 bovine serum albumin to water partitiion coefficient \tab unitless \cr         
#' gkpl \tab log10\tab \cr          
#' ksalt \tab Setschenow constant \tab L/mol \cr        
#' Tsys \tab System temperature \tab degrees C \cr          
#' Tref \tab Reference temperature\tab degrees K \cr          
#' option.kbsa2 \tab Use alternative bovine-serum-albumin partitioning model \tab logical \cr  
#' option.swat2 \tab Use alternative water solubility correction \tab logical \cr  
#' FBSf \tab Fraction fetal bovine serum \tab unitless \cr          
#' pseudooct \tab Pseudo-octanol cell storage lipid content \tab \cr     
#' memblip \tab Membrane lipid content of cells \tab  \cr       
#' nlom \tab Structural protein content of cells \tab \cr
#' P_nlom \tab Proportionality constant to octanol structural protein \tab unitless \cr   
#' P_dom \tab Proportionality constant to dissolved organic material (DOM) \tab unitless \cr         
#' P_cells \tab Proportionality constant to octanol storage lipid \tab unitless \cr      
#' csalt \tab Ionic strength of buffer \tab M=mol/L \cr
#' celldensity \tab Cell density \tab kg/L, g/mL \cr   
#' cellmass \tab Mass per cell \tab ng/cell \cr      
#' f_oc \tab \tab \cr
#' cellwat \tab \tab \cr       
#' Tcor \tab \tab \cr          
#' Vm \tab Volume of media \tab L \cr            
#' Vwell \tab Volume of medium (aqueous phase only) \tab L \cr         
#' Vair \tab Volume of head space \tab L \cr          
#' Vcells \tab Volume of cells/tissue\tab L \cr        
#' Valb \tab Volume of serum albumin \tab L \cr         
#' Vslip \tab Volume of serum lipids \tab L \cr         
#' Vdom \tab Volume of dissolved organic matter\tab L \cr          
#' F_ratio \tab \tab \cr       
#' gs1.GSE \tab \tab \cr       
#' s1.GSE \tab \tab \cr        
#' gss.GSE \tab \tab \cr       
#' ss.GSE \tab \tab \cr        
#' kmw \tab \tab \cr           
#' kow \tab The octanol to water PC (i.e., 10^gkow) \tab unitless \cr           
#' kaw \tab The air to water PC (i.e., 10^gkaw) \tab unitless \cr           
#' swat \tab The water solubility (i.e., 10^gswat) \tab mg/L \cr         
#' kpl \tab \tab \cr           
#' kcw \tab The cell/tissue to water PC (i.e., 10^gkcw) \tab unitless \cr           
#' kbsa \tab The bovine serum albumin to water PC \tab unitless \cr          
#' swat_L \tab \tab \cr        
#' soct_L \tab \tab \cr        
#' scell_L \tab \tab \cr       
#' cinit \tab Initial concentration \tab uM=umol/L \cr         
#' mtot \tab Total micromoles \tab umol \cr          
#' cwat \tab Total concentration in water \tab uM=umol/L \cr          
#' cwat_s \tab Dissolved concentration in water \tab uM=umol/L \cr        
#' csat \tab Is the solution saturated (1/0) \tab logical \cr         
#' activity \tab \tab \cr      
#' cair \tab Concentration in head space\tab uM=umol/L \cr          
#' calb \tab Concentration in serum albumin\tab uM=umol/L \cr          
#' cslip \tab Concentration in serum lipids\tab uM=umol/L \cr         
#' cdom \tab Concentration in dissolved organic matter\tab uM=umol/L \cr          
#' ccells \tab Concentration in cells\tab uM=umol/L \cr        
#' cplastic \tab Concentration in plastic\tab uM=umol/m^2 \cr      
#' mwat_s \tab Mass dissolved in water \tab umols \cr        
#' mair \tab Mass in air/head space \tab umols \cr          
#' mbsa \tab Mass bound to bovine serum albumin \tab umols \cr          
#' mslip \tab Mass bound to serum lipids \tab umols \cr        
#' mdom \tab Mass bound to dissolved organic matter \tab umols \cr          
#' mcells \tab Mass in cells \tab umols \cr        
#' mplastic \tab Mass bond to plastic \tab umols \cr      
#' mprecip \tab Mass precipitated out of solution \tab umols\cr       
#' xwat_s \tab Fraction dissolved in water \tab fraction \cr        
#' xair \tab Fraction in the air \tab fraction \cr          
#' xbsa \tab Fraction bound to bovine serum albumin \tab fraction \cr          
#' xslip \tab Fraction bound to serum lipids \tab fraction \cr         
#' xdom \tab Fraction bound to dissolved organic matter \tab fraction \cr          
#' xcells \tab Fraction within cells \tab fraction \cr        
#' xplastic \tab Fraction bound to plastic \tab fraction \cr     
#' xprecip \tab Fraction precipitated out of solution \tab fraction \cr       
#' eta_free \tab Effective availability ratio \tab fraction \cr      
#' \strong{cfree.invitro} \tab \strong{Free concentration in the in vitro media} (use for Honda1 and Honda2) \tab fraction \cr
#' }
#'
#' @author Greg Honda
#'
#' @references 
#' \insertRef{armitage2014application}{httk}
#'
#' \insertRef{honda2019using}{httk} 
#'
#' @import magrittr
#'
#' @examples 
#'
#' library(httk)
#'
#' # Check to see if we have info on the chemical:
#' "80-05-7" %in% get_cheminfo()
#'
#' #We do:
#' temp <- armitage_eval(casrn.vector = c("80-05-7", "81-81-2"), this.FBSf = 0.1,
#' this.well_number = 384, nomconc = 10)
#' print(temp$cfree.invitro)
#'
#' # Check to see if we have info on the chemical:
#' "793-24-8" %in% get_cheminfo()
#' 
#' # Since we don't have any info, let's look up phys-chem from dashboard:
#' cheminfo <- data.frame(
#'   Compound="6-PPD",
#'   CASRN="793-24-8",
#'   DTXSID="DTXSID9025114",
#'   logP=4.27, 
#'   logHenry=log10(7.69e-8),
#'   logWSol=log10(1.58e-4),
#'   MP=	99.4,
#'   MW=268.404
#'   )
#'   
#' # Add the information to HTTK's database:
#' chem.physical_and_invitro.data <- add_chemtable(
#'  cheminfo,
#'  current.table=chem.physical_and_invitro.data,
#'  data.list=list(
#'  Compound="Compound",
#'  CAS="CASRN",
#'   DTXSID="DTXSID",
#'   MW="MW",
#'   logP="logP",
#'   logHenry="logHenry",
#'   logWSol="logWSol",
#'   MP="MP"),
#'   species="Human",
#'   reference="CompTox Dashboard 31921")
#' 
#' # Run the Armitage et al. (2014) model:
#' out <- armitage_eval(
#'   casrn.vector = "793-24-8", 
#'   this.FBSf = 0.1,
#'   this.well_number = 384, 
#'   nomconc = 10)
#'   
#' print(out)
#' 
#' @export armitage_eval
armitage_eval <- function(chem.cas=NULL,
                          chem.name=NULL,
                          dtxsid = NULL,
                          casrn.vector = NA_character_, # vector of CAS numbers
                          nomconc.vector = 1, # nominal concentration vector (e.g. apparent AC50 values) in uM = umol/L
                          this.well_number = 384,
                          this.FBSf = NA_real_, # Must be set if not in tcdata, this is the most senstive parameter in the model.
                          tcdata = NA, # A data.table with casrn, ac50, and well_number or all of sarea, v_total, and v_working
                          this.sarea = NA_real_,
                          this.v_total = NA_real_,
                          this.v_working = NA_real_,
                          this.cell_yield = NA_real_,
                          this.Tsys = 37,
                          this.Tref = 298.15,
                          this.option.kbsa2 = FALSE,
                          this.option.swat2 = FALSE,
                          this.pseudooct = 0.01, # storage lipid content of cells
                          this.memblip = 0.04, # membrane lipid content of cells
                          this.nlom = 0.20, # structural protein content of cells
                          this.P_nlom = 0.035, # proportionality constant to octanol structural protein
                          this.P_dom = 0.05,# proportionality constant to octanol dom
                          this.P_cells = 1,# proportionality constant to octanol storage-liqid
                          this.csalt = 0.15, # ionic strength of buffer, M = mol/L
                          this.celldensity=1, # kg/L g/mL  mg/uL
                          this.cellmass = 3, #ng/cell
                          this.f_oc = 1, # everything assumed to be like proteins
                          this.conc_ser_alb = 24, # g/L mass concentration of albumin in serum
                          this.conc_ser_lip = 1.9, # g/L mass concentration of lipids in serum
                          this.Vdom = 0, # L the volume of dissolved organic matter (DOM)
                          this.pH = 7.0, # pH of cell culture
                          restrict.ion.partitioning = FALSE, # Should we restrict the partitioning concentration to neutral only?
                          chemdata=chem.physical_and_invitro.data
                          )
{
  # this.Tsys <- 37
  # this.Tref <- 298.15
  # this.option.kbsa2 <- F
  # this.option.swat2 <- F
  # this.FBSf <- 0.1
  # this.pseudooct <- 0.01 # storage lipid content of cells
  # this.memblip <- 0.04 # membrane lipid content of cells
  # this.nlom <- 0.20 # structural protein content of cells
  # this.P_nlom <- 0.035 # proportionality constant to octanol structural protein
  # this.P_dom <- 0.05 # proportionality constant to octanol dom
  # this.P_cells <- 1 # proportionality constant to octanol storage-liqid
  # this.csalt <- 0.15 # ionic strength of buffer, mol/L
  # this.celldensity<-1 # kg/L g/mL  mg/uL
  # this.cellmass <- 3 #ng/cell
  # this.f_oc <- 1 # everything assumed to be like proteins
  
  
  #R CMD CHECK throws notes about "no visible binding for global variable", for
  #each time a data.table column name is used without quotes. To appease R CMD
  #CHECK, a variable has to be created for each of these column names and set to
  #NULL. Note that within the data.table, these variables will not be NULL! Yes,
  #this is pointless and annoying.
  casrn<-ac50<-MP<-gkow<-gkaw<-gswat<-sarea<-v_total<-v_working<-NULL
  cell_yield<-cellwat<-pseudooct<-memblip<-nlom<-Tsys<-Tcor<-Tref<-Vm<-NULL
  Vwell<-Vair<-Vcells<-cellmass<-celldensity<-Valb<-FBSf<-Vslip<-Vdom<-dsm<-NULL
  duow<-duaw<-dumw<-F_ratio<-gs1.GSE<-s1.GSE<-gss.GSE<-ss.GSE<-gkmw<-kmw<-NULL
  kow<-kaw<-swat<-gkpl<-kpl<-gkcw<-P_cells<-P_nlom<-kcw<-gkbsa<-kbsa<-NULL
  option.kbsa2<-ksalt<-csalt<-swat_L<-option.swat2<-soct_L<-scell_L<-cinit<-NULL
  mtot<-cwat<-P_dom<-f_oc<-cwat_s<-csat<-activity<-cair<-calb<-cslip<-cdom<-NULL
  ccell<-cplastic<-mwat_s<-mair<-mbsa<-mslip<-mdom<-mcells<-mplastic<-NULL
  mprecip<-xwat_s<-xair<-xbsa<-xslip<-xdom<-xcells<-xplastic<-xprecip<-NULL
  ccells<-eta_free <- cfree.invitro <- nomconc <- well_number <- NULL
  logHenry <- logWSol <- NULL
  conc_ser_alb <- conc_ser_lip <- Vbm <- NULL
  Fneutral <- MW <- NULL
  #End R CMD CHECK appeasement.
  
  if (all(is.na(tcdata)))
  {
    if (length(casrn.vector) > 1) chem.cas <- casrn.vector
    else if (!is.na(casrn.vector)) chem.cas <- casrn.vector
    
    if (is.null(chem.cas) & 
      is.null(chem.name) & 
      is.null(dtxsid)) 
    stop('chem.name, chem.cas, or dtxsid must be specified.')

    out <- get_chem_id(chem.cas=chem.cas,
                     chem.name=chem.name,
                     dtxsid=dtxsid,
                     chemdata=chemdata)
    chem.cas <- out$chem.cas
    chem.name <- out$chem.name
    dtxsid <- out$dtxsid

    tcdata <- data.table(DTXSID = dtxsid,
                         Compound = chem.name,
                         casrn = chem.cas,
                         nomconc = nomconc.vector,
                         well_number = this.well_number,
                         sarea = this.sarea,
                         v_total = this.v_total,
                         v_working = this.v_working,
                         cell_yield = this.cell_yield)
  }
  
  # Check CAS and AC50 supplied
  if(any(is.na(tcdata[,.(casrn,nomconc)]))){
    stop("casrn or nomconc undefined")
  }  
  
  if(any(is.na(this.FBSf)) & !"FBSf" %in% names(tcdata)){
    stop("this.FBSf must be defined or FBSf must be a column in tcdata")
  }
  
  if(!all(names(tcdata) %in% c("sarea", "v_total", "v_working", "cell_yield")) |
     any(is.na(tcdata[,.(sarea, v_total, v_working, cell_yield)]))){
    
    if(all(names(tcdata) %in% c("sarea", "v_total", "v_working", "cell_yield")) &
       any(is.na(tcdata[,.(sarea, v_total, v_working, cell_yield)]))){
      missing.rows <- which(is.na(tcdata[,sarea]))
    }else{
      missing.rows <- 1:length(tcdata[,casrn])
    }
    
    if(any(is.na(tcdata[missing.rows, well_number]))){
      print(paste0("Either well_number or geometry must be defined for rows: ", 
                   paste(which(tcdata[, is.na(sarea) & is.na(well_number)]),
                         collapse = ",")))
      stop()
    }else{
      temp <- armitage_estimate_sarea(tcdata[missing.rows,])
      tcdata[missing.rows,"sarea"] <- temp[,"sarea"]
      if(any(is.na(tcdata[missing.rows,"v_total"]))){
        tcdata[missing.rows,"v_total"] <- temp[,"v_total"]
      }
      tcdata[missing.rows,"v_working"] <- temp[,"v_working"]
      tcdata[missing.rows,"cell_yield"] <- temp[,"cell_yield"]
    }
    
    
    
  }
  
  # Check if required phys-chem parameters are provided:
  if(!all(c("gkow","logHenry","gswat","MP","MW") %in% names(tcdata)))
  {
  # If not, pull them:
    tcdata[, c("gkow","logHenry","logWSol","MP","MW") := 
             as.data.frame(get_physchem_param(param = c("logP",
                                                        "logHenry",
                                                        "logWSol",
                                                        "MP",
                                                        "MW"), 
                                chem.cas = casrn))]
  }

  # Convevert from chem.physical_and_invitro.data units to Armitage model units:
  tcdata[, "gkaw" := logHenry - log10(298.15*8.2057338e-5)] # log10 atm-m3/mol to (mol/m3)/(mol/m3) (unitless)
  tcdata[, "gswat" := logWSol + log10(MW*1000)] # log10 mol/L to log10 mg/L
  
  # Check if we allowed ionized molecules to partition into various in vitro
  # components:
  if (restrict.ion.partitioning)
  {
     if (!all(c("pKa_Donor","pKa_Accept") %in% names(tcdata)))
     {
     # If not, pull them:
       tcdata[, "pKa_Donor" := as.data.frame(get_physchem_param(
                param = "pKa_Donor", chem.cas = casrn), row.names = casrn)]
       tcdata[, "pKa_Accept" := as.data.frame(get_physchem_param(
                param = "pKa_Accept", chem.cas = casrn),row.names = casrn)]
     }
     
    # Calculate the fraction neutral:
    tcdata[, Fneutral := apply(.SD,1,function(x) calc_ionization(
        pH = this.pH,    
        pKa_Donor = x["pKa_Donor"], 
        pKa_Accept = x["pKa_Accept"])[["fraction_neutral"]])]
  # Otherwise allow all of the chemical to partition:
  } else tcdata[, Fneutral := 1]
  
  manual.input.list <- list(Tsys=this.Tsys, Tref=this.Tref,
                            option.kbsa2=this.option.kbsa2, 
                            option.swat2=this.option.swat2,
                            FBSf=this.FBSf, pseudooct=this.pseudooct, 
                            memblip=this.memblip,
                            nlom=this.nlom, P_nlom=this.P_nlom, 
                            P_dom=this.P_dom, P_cells=this.P_cells,
                            csalt=this.csalt, celldensity=this.celldensity, 
                            cellmass=this.cellmass, f_oc=this.f_oc,
                            conc_ser_alb = this.conc_ser_alb, 
                            conc_ser_lip = this.conc_ser_lip, Vdom = this.Vdom)
  
  check.list <- c("dsm","duow","duaw","dumw",
                  "gkmw","gkcw","gkbsa","gkpl","ksalt")
  
  req.list <- c("Tsys","Tref","option.kbsa2","option.swat2",
                "FBSf","pseudooct","memblip","nlom","P_nlom","P_dom","P_cells",
                "csalt","celldensity","cellmass","f_oc","conc_ser_alb",
                "conc_ser_lip","Vdom")
  if(!all(check.list%in%names(tcdata))){
    tcdata[,check.list[!(check.list %in% names(tcdata))]] <- as.double(NA)}
  
  if(!all(req.list%in%names(tcdata))){
    tcdata[,req.list[!(req.list %in% names(tcdata))]] <- 
    manual.input.list[!(names(manual.input.list) %in% names(tcdata))]}
  
  R <- 8.3144621 # J/(mol*K)
  
  tcdata[,cellwat := 1-(pseudooct+memblip+nlom)] %>%
    .[,Tsys:=Tsys+273.15] %>%
    .[,Tcor:=((1/Tsys)-(1/Tref))/(2.303*R)]
  
  
  tcdata[,Vbm:=v_working/1e6] %>% # uL to L; the volume of bulk medium
    .[,Vwell:=v_total/1e6] %>% # uL to L; the volume of well
    #.[,Vair:=Vwell-Vm] %>%
    .[,Vcells:=cell_yield*(cellmass/1e6)/celldensity/1e6] %>% # cell*(ng/cell)*(1mg/1e6ng)/(mg/uL)*(1uL/L); the volume of cells.
    .[,Vair:=Vwell-Vbm-Vcells] %>%  # the volume of head space
    .[,Valb:=Vbm*FBSf*0.733*conc_ser_alb/1000] %>% # the volume of serum albumin
    .[,Vslip:=Vbm*FBSf*conc_ser_lip/1000] %>% # the volume of serum lipids
    #.[,Vdom:=0] %>%
    .[,Vdom:=Vdom/1e6] %>% # uL to L; the volume of Dissolved Organic Matter (DOM)
    .[,Vm:=Vbm-Valb-Vslip-Vdom] # the volume of medium
    
  
  tcdata[is.na(dsm),dsm:=56.5] %>% #J/(mol*K) # Walden's rule
    .[is.na(duow),duow:=-20000] %>% # see SI EQC model - in vitro tox test July 2014.xlsm
    .[is.na(duaw),duaw:=60000] %>% # see SI EQC model - in vitro tox test July 2014.xlsm
    .[is.na(dumw),dumw:=duow] %>%
    .[,MP:= MP+273.15] %>% # Convert to degrees K
    #.[,F_ratio:=exp(-(dsm/R)*(MP/Tsys))] %>% 
    .[,F_ratio:=10^(0.01*(Tsys-MP))] %>% 
    .[MP<=Tsys,F_ratio:=1]
  
  tcdata[,gs1.GSE:=0.5-gkow] %>%
    .[,gs1.GSE:=gs1.GSE-(-1*duow)*Tcor] %>%
    .[,s1.GSE:=10^gs1.GSE] %>%
    .[MP>298.15,gss.GSE:=0.5-0.01*((MP-273.15)-25)-gkow] %>%
    .[MP>298.15,gss.GSE:=gss.GSE-(-1*duow)*Tcor] %>%
    .[MP>298.15,ss.GSE:=10^gss.GSE] %>%
    .[is.na(gkmw),gkmw:=1.01*gkow + 0.12] %>% 
    .[,gkmw:=gkmw-dumw*Tcor] %>%
    .[,kmw:=10^gkmw] %>%
    .[,gkow:=gkow-duow*Tcor] %>%                                                                            
    .[,kow:=10^gkow] %>%
    .[,gkaw:=gkaw-duaw*Tcor] %>%
    .[,kaw := 10^gkaw] %>%
    .[,gswat:=gswat-(-1*duow)*Tcor] %>%
#   .[,swat:=10^gswat*1e6] 
    .[,swat:=10^gswat] 
  
 # log Kplast-W = 0.97 log KOW - 6.94 (Kramer)
  tcdata[is.na(gkpl),gkpl:=0.97*gkow-6.94] %>% 
    .[,kpl:=10^gkpl] %>%
    .[!(is.na(gkcw)),gkcw:=gkcw-duow*Tcor] %>%
    .[is.na(gkcw),gkcw:=log10(P_cells*pseudooct*kow + memblip*kmw +
                                P_nlom*nlom*kow + cellwat)] %>%
    .[,kcw:=10^gkcw]
  
  tcdata[!(is.na(gkbsa)),gkbsa:=gkbsa-duow*Tcor] %>%
    .[!(is.na(gkbsa)),kbsa:=10^gkbsa]

  tcdata[option.kbsa2==TRUE & is.na(gkbsa) & gkow<4.5, kbsa:=10^(1.08*gkow-0.7)] %>%
    .[option.kbsa2==TRUE & is.na(gkbsa) & gkow>=4.5, kbsa:=10^(0.37*gkow+2.56)]

  tcdata[option.kbsa2==FALSE & is.na(gkbsa),kbsa:=10^(0.71*gkow+0.42)]

# Change partition coefficients to account for only "neutral" chemical 
# (could be 100% depending on value of "restrict.ion.partitioning"):
  tcdata[is.na(ksalt),ksalt:=0.04*gkow+0.114] %>%
    .[,swat:=swat*10^(-1*ksalt*csalt)] %>%
    .[,s1.GSE:=s1.GSE*10^(-1*ksalt*csalt)] %>%
    .[MP>298.15,ss.GSE:=ss.GSE*10^(-1*ksalt*csalt)] %>%
    .[,swat_L:=swat/F_ratio] %>%
    .[,kow:=Fneutral*kow/(10^(-1*ksalt*csalt))] %>%
    .[,kaw:=Fneutral*kaw/(10^(-1*ksalt*csalt))] %>%
    .[,kcw:=Fneutral*kcw/(10^(-1*ksalt*csalt))] %>%
    .[,kbsa:=Fneutral*kbsa/(10^(-1*ksalt*csalt))]

  tcdata[option.swat2==TRUE & MP>298.15,swat:=ss.GSE] %>%
    .[option.swat2==TRUE & MP>298.15,swat_L:=s1.GSE] %>%  # double check this
    .[option.swat2==TRUE & MP<=298.15,swat:=s1.GSE] %>%
    .[option.swat2==TRUE & MP<=298.15,swat_L:=s1.GSE]

  tcdata[,soct_L:=kow*swat_L] %>%
    .[,scell_L:=kcw*swat_L]
  
  tcdata[,nomconc := nomconc] %>% # umol/L for all concentrations
    .[,cinit:= nomconc] %>%
    .[,mtot:= nomconc*Vbm] %>%
    .[,cwat:=mtot/(kaw*Vair + Vm + kbsa*Valb +
                     P_cells*kow*Vslip + kow*P_dom*f_oc*Vdom + kcw*Vcells +
                     1000*kpl*sarea)] %>%
    .[cwat>swat,cwat_s:=swat] %>%
    .[cwat>swat,csat:=1] %>%
    .[cwat<=swat,cwat_s:=cwat] %>%
    .[cwat<=swat,csat:=0] %>%
    .[,activity:=cwat_s/swat_L]
  
  tcdata[,c("cair","calb","cslip","cdom","ccells")] <- 0
  
  tcdata[Vair>0,cair:=kaw*cwat_s] %>%
    .[Valb>0,calb:=kbsa*cwat_s] %>%
    .[Vslip>0,cslip:=kow*cwat_s*P_cells] %>%
    .[Vdom>0,cdom:=kow*cwat_s*P_dom*f_oc] %>%
    .[Vcells>0,ccells:=kcw*cwat_s] %>%
    .[,cplastic:=kpl*cwat_s*1000] %>%
    .[,mwat_s:=cwat_s*Vm] %>%
    .[,mair:=cair*Vair] %>%
    .[,mbsa:=calb*Valb] %>%
    .[,mslip:=cslip*Vslip] %>%
    .[,mdom:=cdom*Vdom] %>%
    .[,mcells:=ccells*Vcells] %>%
    .[,mplastic:=cplastic*sarea] %>%
    .[,mprecip:=0] %>%
    .[cwat>swat,mprecip:=mtot-(mwat_s+mair+mbsa+mslip+mdom+mcells+mplastic)] %>%
    .[,xwat_s:=mwat_s/mtot] %>%
    .[,xair:=mair/mtot] %>%
    .[,xbsa:=mbsa/mtot] %>%
    .[,xslip:=mslip/mtot] %>%
    .[,xdom:=mdom/mtot] %>%
    .[,xcells:=mcells/mtot] %>%
    .[,xplastic:=mplastic/mtot] %>%
    .[,xprecip:=mprecip/mtot] %>% 
    .[, eta_free := cwat_s/nomconc] %>%  # effective availability ratio
    .[, cfree.invitro := cwat_s] # free invitro concentration in micromolar
  
  return(tcdata)
  #output concentrations in umol/L
  #output mass (mwat_s etc.) in mols
  #output mol fraction xbsa etc.
}