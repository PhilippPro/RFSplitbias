# Evtl Batchexperiments verwenden
library(BatchExperiments)
library(mlr)

#dir = "/home/probst/Random_Forest/RFSplitbias"
#dir = "/home/philipp/Promotion/RandomForest/RFSplitbias"
setwd(paste0(dir,"/results"))
load(paste0(dir,"/results/clas.RData"))

setConfig(conf = list(cluster.functions = makeClusterFunctionsMulticore(9)))

tasks = clas_small
regis = makeExperimentRegistry(id = "Splitbias", packages=c("OpenML", "mlr"), 
                               work.dir = paste(dir,"/results", sep = ""), seed = 1)

gettask = function(static, idi, splitrule = "Bonferroni") {
  task = getOMLTask(task.id = idi, verbosity=0)$input$data.set
  list(idi = idi, data = task$data, formula = as.formula(paste(task$target.features,"~.") ), 
       target = task$target.features, splitrule = splitrule)
}
addProblem(regis, id = "taski", static = tasks, dynamic = gettask, seed = 123, overwrite = TRUE)

forest.splitbias.wr = function(static, dynamic, ...) {
  lrn = makeLearner("classif.cforest", par.vals = list(mtry = ceiling(sqrt(ncol(dynamic$data))),
                                                       testtype = as.character(dynamic$splitrule),
                                                       ntree = 100), 
                    predict.type = "prob")
  task = makeClassifTask(id = "splitbias", data = dynamic$data, target = dynamic$target)
  desc = makeResampleDesc(method = "CV", iters = 5, stratify = FALSE)
  res = resample(lrn, task, resampling = desc, measures = list(auc, brier, f1, mmce))
  res$aggr
}
addAlgorithm(regis, id = "forest.splitbias", fun = forest.splitbias.wr, overwrite = TRUE)
forest.design = makeDesign("forest.splitbias")

ps = makeParamSet(
  makeDiscreteParam("splitrule", values = c("Bonferroni", "MonteCarlo", "Univariate", "Teststatistic"))
)
splitrule.design = generateGridDesign(ps)
splitrule.design = generateGridDesign(ps)
namen = colnames(splitrule.design)
n_exp = nrow(splitrule.design)
splitrule.design = as.data.frame(splitrule.design[rep(1:nrow(splitrule.design), nrow(tasks)) ,])
colnames(splitrule.design) = namen
splitrule.design = data.frame(idi = rep(tasks$task_id, each = n_exp), splitrule.design)
splitrule.design = makeDesign("taski", design = splitrule.design)

addExperiments(regis, repls = 1, prob.designs = splitrule.design, algo.designs = forest.design) 

testJob(regis)
submitJobs(regis)

regis = loadRegistry("/home/philipp/Promotion/RandomForest/RFSplitbias/results/Splitbias-files")

