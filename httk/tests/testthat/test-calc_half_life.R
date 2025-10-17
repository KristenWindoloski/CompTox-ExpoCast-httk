test_that("calc_half_life() produces a solution for a built-in chemical", {
  
  # --- CREATE EXPECTED OUTPUT
  output <- calc_half_life(chem.name = "Bisphenol A",
                           suppress.messages = TRUE)
  
  print(output)
  
  # --- TEST
  expect_equal(output,39.74)
})

#-------------------------------------------------------------------------------

test_that("calc_half_life() produces a solution for an added chemical", {
  
  # --- CREATE SAMPLE DATA
  new_data <- read.csv("SampleChemData.csv")
  updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
  
  # --- CREATE EXPECTED OUTPUT
  output <- calc_half_life(chem.name = "Chem3",
                           suppress.messages = TRUE,
                           chemdata=updated_df)
  
  print(output)
  
  # --- TEST
  expect_equal(output,232.1)
})
