test_that("calc_mc_oral_equiv() produces a solution for a built-in chemical with pbtk
          model", {

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,
                                         chem.name = "Bisphenol A",
                                         model = "pbtk",
                                         suppress.messages = TRUE)

            # --- TEST
            expect_equal(unname(output),0.01179)
          })

#-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for an added chemical with pbtk
          model", {

            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,
                                         chem.name = "Chem3",
                                         model = "pbtk",
                                         suppress.messages = TRUE,
                                         chemdata=updated_df)

            # --- TEST
            expect_equal(unname(output),0.0002465)
          })

#-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for a built-in chemical with
          3compartment model", {

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,
                                         chem.name = "Bisphenol A",
                                         model = "3compartment",
                                         suppress.messages = TRUE)

            # --- TEST
            expect_equal(unname(output),0.01179)
          })

#-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for an added chemical with
          3compartment model", {

            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,
                                         chem.name = "Chem3",
                                         model = "3compartment",
                                         suppress.messages = TRUE,
                                         chemdata=updated_df)

            # --- TEST
            expect_equal(unname(output),0.0002465)
          })

#-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for a built-in chemical with
          1compartment model", {

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,,
                                         chem.name = "Bisphenol A",
                                         model = "1compartment",
                                         suppress.messages = TRUE)

            # --- TEST
            expect_equal(unname(output),0.01175)
          })

#-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for an added chemical with
          1compartment model", {

            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,
                                         chem.name = "Chem3",
                                         model = "1compartment",
                                         suppress.messages = TRUE,
                                         chemdata=updated_df)

            # --- TEST
            expect_equal(unname(output),0.0002465)
          })

#-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for a built-in chemical with
          3compartmentss model", {

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,,
                                         chem.name = "Bisphenol A",
                                         model = "3compartmentss",
                                         suppress.messages = TRUE)

            # --- TEST
            expect_equal(unname(output),0.01179)
          })

-------------------------------------------------------------------------------

test_that("calc_mc_oral_equiv() produces a solution for an added chemical with
          3compartmentss model", {

            # --- CREATE SAMPLE DATA
            new_data <- read.csv("SampleChemData.csv")
            updated_df <- rbind(httk::chem.physical_and_invitro.data,new_data)

            # --- CREATE EXPECTED OUTPUT
            set.seed(1)
            output <- calc_mc_oral_equiv(conc = 0.1,
                                         chem.name = "Chem3",
                                         model = "3compartmentss",
                                         suppress.messages = TRUE,
                                         chemdata=updated_df)

            print(output)

            # --- TEST
            expect_equal(output,0.0002556)
          })

#-------------------------------------------------------------------------------