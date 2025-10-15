test_that("calc_analytic_css() produces an analytic SS value for a built-in 
          chemical with pbtk model", {
  
            # --- CREATE EXPECTED OUTPUT
            output <- calc_analytic_css(chem.name = "Bisphenol A",
                                        model = "pbtk",
                                        suppress.messages = TRUE)
  
            # --- TEST
            expect_equal(output,0.9432)
          })

#-------------------------------------------------------------------------------

test_that("calc_analytic_css() produces an analytic SS value for an added 
          chemical pbtk model", {
  
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
  
            # --- CREATE EXPECTED OUTPUT
            output <- calc_analytic_css(chem.name = "Chem1",
                                        model = "pbtk",
                                        suppress.messages = TRUE,
                                        chemdata = updated_df)
  
            # --- TEST
            expect_equal(output,10.19)
          })

#-------------------------------------------------------------------------------

test_that("calc_analytic_css() produces an analytic SS value for a built-in 
          chemical with 3compartment model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_analytic_css(chem.name = "Bisphenol A",
                                        model = "3compartment",
                                        suppress.messages = TRUE)
  
            # --- TEST
            expect_equal(output,0.9432)
          })

#-------------------------------------------------------------------------------

test_that("calc_analytic_css() produces an analytic SS value for an added 
          chemical 3compartment model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
  
            # --- CREATE EXPECTED OUTPUT
            output <- calc_analytic_css(chem.name = "Chem1",
                                        model = "3compartment",
                                        suppress.messages = TRUE,
                                        chemdata = updated_df)
  
            # --- TEST
            expect_equal(output,10.19)
          })

#-------------------------------------------------------------------------------

test_that("calc_analytic_css() produces an analytic SS value for a built-in 
          chemical with 1compartment model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_analytic_css(chem.name = "Bisphenol A",
                                        model = "1compartment",
                                        suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(output,0.9427)
          })

#-------------------------------------------------------------------------------

test_that("calc_analytic_css() produces an analytic SS value for an added 
          chemical 1compartment model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_analytic_css(chem.name = "Chem1",
                                        model = "1compartment",
                                        suppress.messages = TRUE,
                                        chemdata = updated_df)
            
            # --- TEST
            expect_equal(output,15.62)
          })

