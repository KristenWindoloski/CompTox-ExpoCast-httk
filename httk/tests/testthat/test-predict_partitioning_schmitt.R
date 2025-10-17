test_that("predit_partitioning_schmitt() produces a solution for a built-in chemical", {
  
  # --- CREATE EXPECTED OUTPUT
  output <- predict_partitioning_schmitt(chem.name = "Bisphenol A",
                                         suppress.messages = TRUE)
  
  # --- TEST
  expect_equal(output$Kgut2pu,521.9)
  expect_equal(output$Kliver2pu,754.6)
  expect_equal(output$Krest2pu,1401)
})

#-------------------------------------------------------------------------------

test_that("predict_partitioning_schmitt() produces a solution for an added chemical", {
  
  # --- CREATE SAMPLE DATA
  new_data <- read.csv("SampleChemData.csv")
  updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)
  
  # --- CREATE EXPECTED OUTPUT
  output <- predict_partitioning_schmitt(chem.name = "Chem3",
                                         suppress.messages = TRUE,
                                         chemdata=updated_df)
  
  # --- TEST
  expect_equal(output$Kgut2pu,53.18)
  expect_equal(output$Kliver2pu,172.3)
  expect_equal(output$Krest2pu,62.79)
})