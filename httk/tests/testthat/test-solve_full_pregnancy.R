test_that("solve_full_pregnancy() produces a solution for a built-in chemicall", 
          {
            
            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- solve_full_pregnancy(chem.name = "Bisphenol A")
            
            # --- TEST
            expect_equal(max(output[,"Cplasma"]),0.5171)
          })

#-------------------------------------------------------------------------------

test_that("solve_full_pregnancy() produces a solution for an added chemical", {
            
            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
            
            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- solve_full_pregnancy(chem.name = "Chem1",
                                           chemdata=updated_df)
            
            # --- TEST
            expect_equal(max(output[,"Cplasma"]),7.174)
          })

#-------------------------------------------------------------------------------