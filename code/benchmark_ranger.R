library(mlr)
library(batchtools)
library(plyr)

dir = "/home/probst/Random_Forest/RFSplitbias"
setwd(paste0(dir,"/results"))
source(paste0(dir,"/code/probst_defs.R"))

#unlink("probs-muell", recursive = TRUE)
regis = makeExperimentRegistry("probs-muell", 
                               packages = c("mlr", "OpenML", "methods"),
                               source = "/nfsmb/koll/probst/Random_Forest/RFParset/code/probst_defs.R",
                               work.dir = "/nfsmb/koll/probst/Random_Forest/RFParset/results",
                               conf.file = "/nfsmb/koll/probst/Random_Forest/RFParset/code/.batchtools.conf.R"
)