
#Load previous sysdata.rda from datatables folder
rm(list = ls())
env1 <- new.env()
load("R/sysdata.rda", envir = env1)

# Add previously global variables to the internal data
env1$tissue.data_internal <- httk::tissue.data
env1$physiology.data_internal <- httk::physiology.data
env1$mecdt_internal <- httk::mecdt
env1$mcnally_dt_internal <- httk::mcnally_dt
env1$bmiage_internal <- httk::bmiage
env1$wfl_internal <- httk::wfl
env1$well_param_internal <- httk::well_param
env1$hw_H_internal <- httk::hw_H
env1$scr_h_internal <- httk::scr_h
env1$hct_h_internal <- httk::hct_h

# Save data frame to sysdata file in R folder
save(list = ls(envir = env1), file = "R/sysdata.rda", envir = env1)