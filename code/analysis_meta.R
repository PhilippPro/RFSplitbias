library("BatchExperiments")
dir = "/home/probst/Random_Forest/RFSplitbias"

load(paste0(dir, "/results/datasetsinfo.RData"))

regis = loadRegistry(paste0(dir, "/results/Splitbias-files"))
res = loadResults(regis)

res = res[which(sapply(res, "[[", 2)[1,] == "cforest")]

# datasetsinfo bearbeiten, ein paar Features hinzufügen
datasetsinfo = data.frame(datasetsinfo, as.data.frame(matrix(NA, nrow(datasetsinfo), 6)))
for(i in 1:length(nfactor)) {
  datasetsinfo[i, 7] = sum(nfactor[i][[1]][as.numeric(names(nfactor[i][[1]])) >= 4])
  datasetsinfo[i, 8] = sum(nfactor[i][[1]][as.numeric(names(nfactor[i][[1]])) >= 8])
  datasetsinfo[i, 9] = sum(as.numeric(names(nfactor[i][[1]])) * nfactor[i][[1]]) / sum(nfactor[i][[1]])
}
datasetsinfo[, 10] = c(datasetsinfo[, 4] == 0)
datasetsinfo[, 11] = c(datasetsinfo[, 5] == 0)
datasetsinfo[, 12] = c(datasetsinfo[, 4] != 0 & datasetsinfo[, 5] != 0)
colnames(datasetsinfo)[7:12] = c("bigger_4", "bigger_8", "avg_cat", "only_factor", "only_numeric", "numeric_factor")

# globale Ergebnisse
ids = list()
ids[[1]] = datasetsinfo[which(datasetsinfo[,2] == 2), 1]
ids[[2]] = datasetsinfo[which(datasetsinfo[,2] != 2), 1]
ids[[3]] = datasetsinfo[which(is.na(datasetsinfo[,2])), 1]

names = c("bin", "multiclass", "regr")

# keine Fehler bei...
no_error_ids = (names(table(sapply(res, "[[", 1)))[table(sapply(res, "[[", 1)) == 2])
erge = vector("list", 3)

for(j in 1:3){
  print(names[j])
  res_subset = res[which(sapply(res, "[[", 1) %in% ids[[j]])]
  
  # nur Ergebnisse verwenden, bei denen bei allen zwei Methoden keine Fehler auftraten
  res_subset = res_subset[sapply(res_subset, "[[", 1) %in% names(table(sapply(res_subset, "[[", 1)))[table(sapply(res_subset, "[[", 1)) == 2]]
  
  res_compr = list()
  for(i in 1:length(res_subset))
    res_compr[[i]] = colMeans(res_subset[[i]][[3]])
  
  ids_1 = sapply(res_subset[sapply(res_subset, "[[", 2)[2,] == "quad"], "[[", 1)
  
  for(i in 2:length(res_compr[[1]])){
    
    erg = cbind(do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "quad"])[,i],
                do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "max"])[,i])
    
    boxplot(do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "quad"])[,i],
            do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "max"])[,i],
            main = paste(colnames(res_subset[[1]]$result)[i], names[j]), names = c("party_quad", "party_max"))
    
    print(colnames(res_subset[[1]]$result)[i])
    print(colMeans(erg))
    print(rowMeans(apply(erg, 1, rank))) # durchschnittliches Ranking
    colnames(erg) = paste(colnames(res_subset[[1]]$result)[i], c("quad", "max"))
    erge[[j]] = cbind(erge[[j]], erg)
  }
  erge[[j]] = cbind(ids_1, erge[[j]])
}

erge[[1]][, 12] / erge[[1]][, 13]

task_data = rbind(cbind(erge[[1]][,1], erge[[1]][, 12] - erge[[1]][, 13] > 0), 
                  cbind(erge[[2]][,1], erge[[2]][, 8] - erge[[2]][, 9] > 0),
                  cbind(erge[[3]][,1], erge[[3]][, 8] - erge[[3]][, 9] > 0))
colnames(task_data) = c("idi", "bigger")

task_data = merge(task_data, datasetsinfo, all.x = TRUE, all.y = FALSE , by.x = "idi", by.y = "idi")
task_data$idi = NULL

apply(task_data[task_data$bigger == 0,], 2, function(x) mean(x, na.rm = T))
apply(task_data[task_data$bigger == 1,], 2, function(x) mean(x, na.rm = T))

plot(task_data$bigger ~ task_data$nclass)
boxplot(ncol ~ bigger, main = colnames(task_data)[3], data = task_data, outline = FALSE)
boxplot(num_feat ~ bigger, main = colnames(task_data)[4], data = task_data, outline = FALSE)
plot(task_data$bigger ~ task_data$num_feat)
plot(task_data$bigger ~ task_data$factor_feat)
boxplot(n ~ bigger, main = colnames(task_data)[6], data = task_data, outline = TRUE)
plot(task_data$bigger ~ task_data$bigger_4)
plot(task_data$bigger ~ task_data$bigger_8)
boxplot(avg_cat ~ bigger, main = colnames(task_data)[9], data = task_data, outline = FALSE)
# Im "Nullfall" tauchen tendenziell mehr Kategorien auf in den Variablen (und etwas mehr Variablen)
# 0 = FALSE -> max > quad -> quad besser

task_data$only_numeric = as.factor(task_data$only_numeric)
task_data$only_factor = as.factor(task_data$only_factor)
task_data$numeric_factor = as.factor(task_data$numeric_factor)
task_data$bigger = as.factor(task_data$bigger)

plot(task_data$bigger ~ task_data$only_numeric)
plot(task_data$bigger ~ task_data$only_factor) 
# Bei nur kategoriellen Prädiktoren tendenziell 1 besser
plot(task_data$bigger ~ task_data$numeric_factor)

task_data[is.na(task_data)] = - 999

library(partykit)
library(party)
ct = ctree( bigger ~ nclass + ncol + num_feat + factor_feat + n + bigger_4 + bigger_8 + avg_cat + only_numeric + only_factor + numeric_factor, data = task_data, controls = ctree_control(mincriterion = 0.1, minsplit = 1, minbucket = 1))
plot(ct)

randomForest(bigger ~ ., data = task_data, ntree = 10000)

# keine Muster erkennbar
# Konzentriere auf relative Differenz, weil hier Unterschiede noch am deutlichsten?

for(i in 1:3){
  task_data = cbind(erge[[i]][,1], round(erge[[i]][, 8] - erge[[i]][, 9], 4)/erge[[i]][, 9])
  colnames(task_data) = c("idi", "bigger")
  
  task_data = merge(task_data, datasetsinfo, all.x = TRUE, all.y = FALSE , by.x = "idi", by.y = "idi")
  task_data$idi = NULL
  task_data$nclass = NULL
  
  head(task_data)
  for(j in 2:8)
    plot(task_data[, j], task_data$bigger, xlab = colnames(task_data)[j])
  # mehr Kategorien tendenziell kleinere Werte
  
  task_data[is.na(task_data)] = - 999
  task_data$only_numeric = as.factor(task_data$only_numeric)
  task_data$only_factor = as.factor(task_data$only_factor)
  task_data$numeric_factor = as.factor(task_data$numeric_factor)

  ct = ctree( bigger ~ ncol + num_feat + factor_feat + n + bigger_4 + bigger_8 + avg_cat + only_numeric + only_factor + numeric_factor, data = task_data, controls = ctree_control(mincriterion = 0.1, minsplit = 1, minbucket = 1))
  plot(ct)
  randomForest(bigger ~ ., data = task_data, ntree = 10000)
  
  lrn.regr = makeLearner("regr.randomForest", par.vals = list(ntree=10000))
  task = makeRegrTask(id="split", data = task_data, target = "bigger")
  fit.regr = train(lrn.regr, task)
  pd.regr = generatePartialPredictionData(fit.regr, task, "ncol", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "num_feat", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "factor_feat", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "n", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "bigger_4", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "bigger_8", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "avg_cat", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "only_numeric", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "only_factor", fun = mean)
  plotPartialPrediction(pd.regr)
  pd.regr = generatePartialPredictionData(fit.regr, task, "numeric_factor", fun = mean)
  plotPartialPrediction(pd.regr)
  sd(task_data$bigger)
  boxplot(task_data$bigger, outline = FALSE)
}
