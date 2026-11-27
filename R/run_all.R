# run_all.R -- runs the whole analysis from raw data to figures and tables.
# Open toll-accidents-catalonia.Rproj first (sets the working directory).
# Total run time: about 5 minutes (the random forests in 04 take most of it).
#
# Packages: tidyverse, rpart, randomForest, pROC
#   install.packages(c("tidyverse", "rpart", "randomForest", "pROC"))

# delete old results first, so old and new files are never mixed
unlink(list.files("output", full.names = TRUE))
unlink(list.files("figures", pattern = "\\.png$", full.names = TRUE))

source("R/02_clean_features.R", echo = FALSE)
source("R/03_eda.R",            echo = FALSE)
source("R/04_models.R",         echo = FALSE)
source("R/05_toll_effect.R",    echo = FALSE)
cat("\nAll done. Figures in figures/, tables in output/\n")
