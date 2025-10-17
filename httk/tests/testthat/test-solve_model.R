test_that("solve_model() produces a solution for a built-in 
          chemical with pbtk model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- solve_model(chem.name = "Bisphenol A",
                                  model = "pbtk",
                                  suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(max(output[,"Cplasma"]),0.3809)
          })

#-------------------------------------------------------------------------------

test_that("solve_model() produces a solution for an added chemical with pbtk 
          model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            output <- solve_model(chem.name = "Chem2",
                                  model = "pbtk",
                                  suppress.messages = TRUE,
                                  chemdata=updated_df)
            
            # --- TEST
            expect_equal(max(output[,"Cplasma"]),4.371)
          })

#-------------------------------------------------------------------------------

test_that("solve_model() produces a solution for a built-in 
          chemical with 3ompartment model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- solve_model(chem.name = "Bisphenol A",
                                  model = "3compartment",
                                  suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(max(output[,"Cplasma"]),0.3689)
          })

#-------------------------------------------------------------------------------

test_that("solve_model() produces a solution for an added chemical with 
          3compartment model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            output <- solve_model(chem.name = "Chem2",
                                  model = "3compartment",
                                  suppress.messages = TRUE,
                                  chemdata=updated_df)
            
            # --- TEST
            expect_equal(max(output[,"Cplasma"]),4.775)
          })

#-------------------------------------------------------------------------------

test_that("solve_model() produces a solution for a built-in chemical with 
          1compartment model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- solve_model(chem.name = "Bisphenol A",
                                  model = "1compartment",
                                  suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(max(output[,"Ccompartment"]),0.3795)
          })

#-------------------------------------------------------------------------------

test_that("solve_model() produces a solution for an added chemical with 
          1compartment model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            output <- solve_model(chem.name = "Chem2",
                                  model = "1compartment",
                                  suppress.messages = TRUE,
                                  chemdata=updated_df)
            
            # --- TEST
            expect_equal(max(output[,"Ccompartment"]),4.446)
          })

#-------------------------------------------------------------------------------