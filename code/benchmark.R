# Evtl Batchexperiments verwenden
library(BatchExperiments)
library(mlr)

dir = "/nfsmb/koll/probst/Random_Forest/RFSplitbias"
#dir = "/home/philipp/Promotion/RandomForest/RFSplitbias"
setwd(paste0(dir,"/results"))
load(paste0(dir,"/results/clas.RData"))
load(paste0(dir,"/results/reg.RData"))

setConfig(conf = list(cluster.functions = makeClusterFunctionsMulticore(4)))

tasks = rbind(clas_small, reg_small)
regis = makeExperimentRegistry(id = "Splitbias", packages=c("OpenML", "mlr", "randomForest"), 
                               work.dir = paste(dir,"/results", sep = ""), src.dirs = paste(dir,"/functions", sep = ""), seed = 1)

gettask = function(static, idi, learner, teststat, testtype) {
  task = getOMLTask(task.id = idi, verbosity=0)$input$data.set
  list(idi = idi, data = task$data, formula = as.formula(paste(task$target.features,"~.")), 
       target = task$target.features, learner = learner, teststat = teststat, testtype = testtype)
}
addProblem(regis, id = "taski", static = tasks, dynamic = gettask, seed = 123, overwrite = TRUE)

forest.splitbias.wr = function(static, dynamic, ...) {
  if(static[static$task_id == dynamic$idi, 2] == "Supervised Classification") {
    lvl = table(dynamic$data[, dynamic$target])
    dynamic$data = dynamic$data[dynamic$data[, dynamic$target] %in% names(lvl[lvl >= 5]), ] 
    dynamic$data[,dynamic$target] = droplevels(as.factor(dynamic$data[,dynamic$target]))
    if(length(levels(as.factor(dynamic$data[,dynamic$target]))) == 2){
      measures =  list(acc, auc, ber, brier, f1, mmce)
    } else {
      measures = list(acc, ber, multiclass.brier, mmce)
    }
    if (as.character(dynamic$learner) == "cforest") {
      lrn = makeLearner("classif.cforest", par.vals = list(mtry = floor(sqrt(ncol(dynamic$data)-1)),
                                                           minbucket = 1,
                                                           minsplit = 1, 
                                                           teststat = as.character(dynamic$teststat),
                                                           testtype = as.character(dynamic$testtype),
                                                           ntree = 1000), 
                        predict.type = "prob")
    } 
    if (as.character(dynamic$learner) == "randomForest") {
      lrn = makeLearner("classif.randomForest", par.vals = list(ntree = 1000, replace = FALSE), predict.type = "prob")
    }
    task = makeClassifTask(id = "splitbias", data = dynamic$data, target = dynamic$target)
    desc = makeResampleDesc(method = "RepCV", folds = 5, reps = 2, stratify = TRUE)
  } else {
    measures = list(mae, medae, medse, mse)
    if (as.character(dynamic$learner) == "cforest") {
      lrn = makeLearner("regr.cforest", par.vals = list(mtry = max(floor((ncol(dynamic$data)-1)/3),1),
                                                        minbucket = 5, 
                                                        minsplit = 1, 
                                                        teststat = as.character(dynamic$teststat),
                                                        testtype = as.character(dynamic$testtype),
                                                        ntree = 1000))
    }
    if (as.character(dynamic$learner) == "randomForest") {
      lrn = makeLearner("regr.randomForest", par.vals = list(ntree = 1000, replace = FALSE))
    }
    task = makeRegrTask(id = "splitbias", data = dynamic$data, target = dynamic$target)
    desc = makeResampleDesc(method = "RepCV", folds = 5, reps = 2)
  }
  res = resample(lrn, task, resampling = desc, measures = measures)
  list(idi = dynamic$idi, lrn = c(as.character(dynamic$learner), as.character(dynamic$teststat), as.character(dynamic$testtype)), result = res$measures.test)
}
addAlgorithm(regis, id = "forest.splitbias", fun = forest.splitbias.wr, overwrite = TRUE)
forest.design = makeDesign("forest.splitbias")

splitrule.design = data.frame(learner = c("cforest", "cforest", "randomForest"), 
                                          teststat = c("quad", "max", ""), testtype = c("Univariate", "Teststatistic", "") )
n_exp = nrow(splitrule.design)
splitrule.design = as.data.frame(splitrule.design[rep(1:nrow(splitrule.design), nrow(tasks)) ,])
splitrule.design = data.frame(idi = rep(tasks$task_id, each = n_exp), splitrule.design)
splitrule.design = makeDesign("taski", design = splitrule.design)

addExperiments(regis, repls = 1, prob.designs = splitrule.design, algo.designs = forest.design) 

testJob(regis)

chunks = chunk(findNotSubmitted(regis), chunk.size = 100)

submitJobs(regis, ids = chunks)
submitJobs(regis, findNotDone(regis))
showStatus(regis)

res = loadResults(regis)
res
