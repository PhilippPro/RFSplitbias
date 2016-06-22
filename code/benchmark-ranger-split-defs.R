load("/home/probst/Random_Forest/RFParset/results/clas.RData")
load("/home/probst/Random_Forest/RFParset/results/reg.RData")
tasks = reg_small # rbind(clas_small, reg_small)

OMLDATASETS = tasks$did[!(tasks$did %in% c(1054, 1071, 1065))] # Cannot guess task.type from data! for these 3
#OMLDATASETS = OMLDATASETS[1:50]

MEASURES = function(x) switch(x, "classif" = list(acc, ber, mmce, multiclass.au1u, multiclass.brier, logloss, timetrain), "regr" = list(mse, mae, medae, medse, timetrain))

LEARNERIDS = c("ranger")

DESSIZE = function(ps) {
  100
}

makeMyParamSet = function(lrn.id, task = NULL) {
  switch(lrn.id,
         ranger = makeParamSet(
           makeDiscreteParam("splitrule", values = c("variance", "maxstat")),
           makeNumericParam("alpha", lower = 0, upper = 1),
           makeNumericParam("minprop", lower = 0, upper = 0.5)
         )
         )
}

makeMyParamSet2 = function(lrn.id, task = NULL) {
  switch(lrn.id,
         ranger = makeParamSet(
           makeDiscreteParam("splitrule", values = c("variance", "maxstat")),
           makeNumericParam("alpha", lower = 0, upper = 1),
           makeNumericParam("minprop", lower = 0.1, upper = 0.1)
         )
  )
}

makeMyParamSet3 = function(lrn.id, task = NULL) {
  switch(lrn.id,
         ranger = makeParamSet(
           makeDiscreteParam("splitrule", values = c("variance", "maxstat")),
           makeNumericParam("alpha", lower = 1, upper = 1),
           makeNumericParam("minprop", lower = 0, upper = 0.5)
         )
  )
}

makeMyParamSet4 = function(lrn.id, task = NULL) {
  switch(lrn.id,
         ranger = makeParamSet(
           makeDiscreteParam("splitrule", values = c("variance", "maxstat")),
           makeNumericParam("alpha", lower = 0.9, upper = 1),
           makeNumericParam("minprop", lower = 0.05, upper = 0.15)
         )
  )
}


CONVERTPARVAL = function(par.vals, task, lrn.id) {
  par.vals$num.trees = 3000 # 3000 trees
  par.vals$splitrule = as.character(par.vals$splitrule)
  return(par.vals)
}

