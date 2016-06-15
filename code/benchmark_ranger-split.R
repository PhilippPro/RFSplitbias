library(mlr)
library(batchtools)
library(plyr)

dir = "/home/probst/Random_Forest/RFSplitbias"
setwd(paste0(dir,"/results"))
source(paste0(dir,"/code/benchmark-ranger-split-defs.R"))

#unlink("benchmark-ranger-split", recursive = TRUE)
regis = makeExperimentRegistry("benchmark-ranger-split", 
                               packages = c("mlr", "OpenML", "methods"),
                               source = "/nfsmb/koll/probst/Random_Forest/RFSplitbias/code/benchmark-ranger-split-defs.R",
                               work.dir = "/nfsmb/koll/probst/Random_Forest/RFSplitbias/results",
                               conf.file = "/nfsmb/koll/probst/Random_Forest/RFSplitbias/code/.batchtools.conf.R"
)
regis$cluster.functions = makeClusterFunctionsMulticore() 

# add our selected OML dsets as problems
for (did in OMLDATASETS) {
  data = list(did = did)
  addProblem(name = as.character(did), data = data)
}

# add one generic 'algo' that evals the RF in hyperpar space
addAlgorithm("eval", fun = function(job, data, instance, lrn.id, ...) {
  par.vals = list(...)
  oml.dset = getOMLDataSet(data$did)             
  task = convertOMLDataSetToMlr(oml.dset)
  type = getTaskType(task)
  par.vals = par.vals[!(is.na(par.vals))]
  par.vals = CONVERTPARVAL(par.vals, task, lrn.id)
  lrn.id = paste0(type, ".", lrn.id)
  lrn = switch(type, "classif" = makeLearner(lrn.id, predict.type = "prob"), "regr" = makeLearner(lrn.id))
  lrn = setHyperPars(lrn, par.vals = par.vals)
  measures = MEASURES(type)
  mod = train(lrn, task)
  oob = getOutOfBag(mod, task)
  performance(oob, measures = measures, model = mod)
})

set.seed(124)
ades = data.frame()
for (lid in LEARNERIDS) {
  ps = makeMyParamSet(lid, task = NULL)
  des.size = DESSIZE(ps)
  d = generateDesign(des.size, ps)
  d = cbind(lrn.id = lid, d, stringsAsFactors = FALSE)
  ades = rbind.fill(ades, d)
}
addExperiments(algo.designs = list(eval = ades))

summarizeExperiments()
ids = chunkIds(findNotDone(), chunk.size = 1000)
submitJobs(ids)
submitJobs(1)
#submitJobs(ids, resources = list(chunk.ncpus = 9))
getStatus()
getErrorMessages()



lrn = switch(type, "classif" = makeLearner(lrn.id, predict.type = "prob"), "regr" = makeLearner(lrn.id))
lrn = setHyperPars(lrn, par.vals = par.vals)

par.vals$splitrule = "maxstat"
# zu Debugzwecken
#lrn.id = "ranger"
#par.vals = as.list(ades[1,-1])
#data$did = 457
