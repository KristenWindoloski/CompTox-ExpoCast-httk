test_that("calc_css() produces a solution for a built-in chemical with pbtk 
          model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_css(chem.name = "Bisphenol A",
                               model = "pbtk",
                               suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(output$avg,0.9392)
            expect_equal(output$the.day,20)
          })

#-------------------------------------------------------------------------------

test_that("calc_css() produces a solution for an added chemical with pbtk
          model", {

            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)

            # --- CREATE EXPECTED OUTPUT
            output <- calc_css(chem.name = "Chem3",
                               model = "pbtk",
                               suppress.messages = TRUE,
                               chemdata=updated_df)

            # --- TEST
            expect_equal(output$avg,61.27)
            expect_equal(output$the.day,117)
          })

#-------------------------------------------------------------------------------

test_that("calc_css() produces a solution for a built-in chemical with 
          3compartment model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_css(chem.name = "Bisphenol A",
                               model = "3compartment",
                               suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(output$avg,0.9412)
            expect_equal(output$the.day,19)
          })

#-------------------------------------------------------------------------------

test_that("calc_css() produces a solution for an added chemical with 3compartment
          model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_css(chem.name = "Chem3",
                               model = "3compartment",
                               suppress.messages = TRUE,
                               chemdata=updated_df)
            
            # --- TEST
            expect_equal(output$avg,61.27)
            expect_equal(output$the.day,110)
          })

#-------------------------------------------------------------------------------

test_that("calc_css() produces a solution for a built-in chemical with 
          1compartment model", {
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_css(chem.name = "Bisphenol A",
                               model = "1compartment",
                               suppress.messages = TRUE)
            
            # --- TEST
            expect_equal(output$avg,0.9382)
            expect_equal(output$the.day,19)
          })

#-------------------------------------------------------------------------------

test_that("calc_css() produces a solution for an added chemical with 1compartment
          model", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            output <- calc_css(chem.name = "Chem3",
                               model = "1compartment",
                               suppress.messages = TRUE,
                               chemdata=updated_df)
            
            # --- TEST
            expect_equal(output$avg,61.22)
            expect_equal(output$the.day,123)
          })

#-------------------------------------------------------------------------------