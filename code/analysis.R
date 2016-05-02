# Subset-Analyse
library("BatchExperiments")
dir = "/home/probst/Random_Forest/RFSplitbias"

load(paste0(dir, "/results/datasetsinfo.RData"))

regis = loadRegistry(paste0(dir, "/results/Splitbias-files"))
res = loadResults(regis)
res = res[which(sapply(res, "[[", 2)[2,] != "oob")]

# globale Ergebnisse
ids = list()
ids[[1]] = datasetsinfo[which(datasetsinfo[,2] == 2), 1]
ids[[2]] = datasetsinfo[which(datasetsinfo[,2] != 2), 1]
ids[[3]] = datasetsinfo[which(is.na(datasetsinfo[,2])), 1]

sum(datasetsinfo[,2] == 2, na.rm=T) # 111 binary
sum(datasetsinfo[,2] != 2, na.rm=T) # 39 multiclass
sum(is.na(datasetsinfo[,2])) # 111 regression

names = c("bin", "multiclass", "regr")

for(j in 1:3){
  print(names[j])
  res_subset = res[which(sapply(res, "[[", 1) %in% ids[[j]])]
  
  # nur Ergebnisse verwenden, bei denen bei allen drei Methoden keine Fehler auftraten
  res_subset = res_subset[sapply(res_subset, "[[", 1) %in% names(table(sapply(res_subset, "[[", 1)))[table(sapply(res_subset, "[[", 1)) == 3]]
  
  res_compr = list()
  for(i in 1:length(res_subset))
    res_compr[[i]] = colMeans(res_subset[[i]][[3]])
  
  for(i in 2:length(res_compr[[1]])){
    
    erg = cbind(do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "quad"])[,i],
    do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "max"])[,i],
    do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == ""])[,i])
    
    boxplot(do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "quad"])[,i],
            do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == "max"])[,i],
            do.call(rbind, res_compr[sapply(res_subset, "[[", 2)[2,] == ""])[,i], 
            main = paste(colnames(res_subset[[1]]$result)[i], names[j]), names = c("party_quad", "party_max", "rf"))
    
    print(colnames(res_subset[[1]]$result)[i])
    print(colMeans(erg))
    print(rowMeans(apply(erg, 1, rank))) # durchschnittliches Ranking
    }
}
# AUC passt nicht manchmal!

