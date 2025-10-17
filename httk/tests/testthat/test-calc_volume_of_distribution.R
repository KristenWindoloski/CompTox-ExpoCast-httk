test_that("calc_vdist() produces a solution for a built-in chemical", {
  
  # --- CREATE EXPECTED OUTPUT
  output <- calc_vdist(chem.name = "Bisphenol A",
                                        suppress.messages = TRUE)
  
  # --- TEST
  expect_equal(output,6.343)
})

#-------------------------------------------------------------------------------

test_that("calc_volume_of_distribution() produces a solution for an added chemical", {
  
  # --- CREATE SAMPLE DATA
  new_data <- read.csv("SampleChemData.csv")
  updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
  
  # --- CREATE EXPECTED OUTPUT
  output <- calc_vdist(chem.name = "Chem3",
                                        suppress.messages = TRUE,
                                        chemdata=updated_df)
  
  # --- TEST
  expect_equal(output,0.4763)
})
