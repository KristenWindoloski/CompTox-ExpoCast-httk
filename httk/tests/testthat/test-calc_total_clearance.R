test_that("calc_total_clearance() produces a solution for a built-in chemical", {
  
  # --- CREATE EXPECTED OUTPUT
  output <- calc_total_clearance(chem.name = "Bisphenol A",
                                 suppress.messages = TRUE)
  
  print(output)
  
  # --- TEST
  expect_equal(output,0.1106)
})

#-------------------------------------------------------------------------------

test_that("calc_total_clearance() produces a solution for an added chemical", {
  
  # --- CREATE SAMPLE DATA
  new_data <- read.csv("SampleChemData.csv")
  updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
  
  # --- CREATE EXPECTED OUTPUT
  output <- calc_total_clearance(chem.name = "Chem3",
                                 suppress.messages = TRUE,
                                 chemdata=updated_df)
  
  print(output)
  
  # --- TEST
  expect_equal(output,0.001422)
})
