library("BatchExperiments")
dir = "/home/probst/Random_Forest/RFSplitbias"

load(paste0(dir, "/results/datasetsinfo.RData"))

regis = loadRegistry(paste0(dir, "/results/Splitbias-files"))
res = loadResults(regis)

res = res[which(sapply(res, "[[", 2)[1,] == "cforest")]


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
task_data[is.na(task_data)] = - 999

apply(task_data[task_data$bigger == 1,], 2, mean)
apply(task_data[task_data$bigger == 0,], 2, mean)

boxplot(nclass ~ bigger, main = colnames(task_data)[i], data = task_data[task_data$nclass > -995,c(1,2)])
cor(task_data[task_data$nclass > -995,c(1,2)])
task_data$bigger = as.factor(task_data$bigger)
boxplot(ncol ~ bigger, main = colnames(task_data)[i], data = task_data, outline = FALSE)
boxplot(num_feat ~ bigger, main = colnames(task_data)[i], data = task_data, outline = FALSE)
boxplot(factor_feat ~ bigger, main = colnames(task_data)[i], data = task_data, outline = FALSE)


library(partykit)
library(party)
ct = ctree( bigger ~ nclass + ncol + num_feat + factor_feat , data = task_data, controls = ctree_control(mincriterion = 0.1, minsplit = 1, minbucket = 1))
plot(ct)

randomForest(bigger ~ ., data = task_data, ntree = 10000)

# keine Muster erkennbar
# Konzentriere auf Regression, weil hier Unterschiede noch am deutlichsten

task_data = cbind(erge[[3]][,1], round(erge[[3]][, 8] - erge[[3]][, 9])/erge[[3]][, 9])
colnames(task_data) = c("idi", "bigger")

task_data = merge(task_data, datasetsinfo, all.x = TRUE, all.y = FALSE , by.x = "idi", by.y = "idi")
task_data$idi = NULL
task_data$nclass = NULL

head(task_data)
for(i in 2:4)
  plot(task_data[,i], task_data$bigger, ylab = colnames(task_data)[i])

ct = ctree( bigger ~ ncol + num_feat + factor_feat , data = task_data, controls = ctree_control(mincriterion = 0.1, minsplit = 1, minbucket = 1))
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
sd(task_data$bigger)
boxplot(task_data$bigger, outline = FALSE)

