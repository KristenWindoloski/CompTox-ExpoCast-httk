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