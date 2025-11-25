# R Package "httk"

This R package contains minor modifications to the 'httk' R package 
<https://cran.r-project.org/package=httk>. The purpose of this modified 'httk'
package is for use in an R Shiny app called ToCS 
<https://github.com/KristenWindoloski/ToCS>. However, this package can still 
function independently if a separate use case is desired.

## Description

This package predicts toxicokinetics of chemicals and is a modified version of
the 'httk' R package <https://cran.r-project.org/package=httk>. For a full 
description of the package's capabilities, please see the 'httk' package's 
documentation and vignettes. The only difference between this 'httk' and the original 'httk' are
that this 'httk' contains no global variables. The global variables in 'httk' were
removed and reimplemented differently. The 'chem.physical_and_invitro.data' data
frame is still available to users. However, if a user wants to add a chemical to
the data frame for simulation, they will need to add a row with all relevant
information to that data frame and then pass the entire updated data frame 
through the called function. The remaining global variables that were previously
available to the user are still available to the user. However, these variables
are no longer declared as global. They have been added to the package's internal
data, which is how the data frames are now called from within the package's code.
No changes have been made to the 'httk' algorithms. However, user's can no longer
add tissue or physiology data. This limitation can be easily addressed in future
updates.

## Getting Started

### Installing R (skip if R or RStudio is already installed)

Install the free statistical computing language, R, by following the instructions 
in the following link: <https://www.r-project.org/>. You may also want to install
RStudio for a more user-friendly programming environment. To do so, follow the
instructions on <https://posit.co/download/rstudio-desktop/>. Then, open R or
RStudio.

### Installing this package

From the R command line, type:
```
install.packages("remotes")
```
Install the 'httk' R package by then typing the following into the R command line:
```
remotes::install_github("KristenWindoloski/CompTox-ExpoCast-httk/httk")
```
Then, load the package by typing the following into the R command line:
```
library(httk)
```

### Examples

All functions work exactly the same as in 'httk' unless you want to simulate
additional chemicals not currently in the chem.physical_and_invitro.data data 
frame. To simulate a new chemical, add chemical data to the 
chem.physical_and_invitro.data data frame. Here, we take a CSV with chemical data
for two chemicals, "Chemical1" and "Chemical2", from 
<https://github.com/KristenWindoloski/ToCS/blob/main/vignettes/articles/CSVs/CSV_vignettes.csv>.
Download this file and save it in the same directory as your R working directory
is set to. Then, read the CSV file into R.
```
new.chemdata.rows <- read.csv(file = "CSV_vignettes.csv")
```
Next, install and load the 'dplyr' library if not already done.
```
install.packages("dplyr")
load(dplyr)
```
Then, bind new.chemdata.rows with the original chem.physical_and_invitro.data 
data frame from 'httk'.
```
new.chemdata <- dplyr::rbind (httk::chem.physical_and_invitro.data,new.chemdata.rows)
```
Now, run the httk simulation you desire for 'Chemical1' and pass 'new.chemdata' 
through with the 'chemdata' function argument.
```
httk::calc_analytic_css(chem.name = "Chemical1",
                           species = "Human",
                           model = "pbtk",
                           chemdata = new.chemdata)
```

## Getting Help

Please email any issues to <kawindoloski@gmail.com>.