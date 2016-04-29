# Subset-Analyse
library("BatchExperiments")
dir = "/home/probst/Random_Forest/RFSplitbias"

load(paste0(dir, "/results/datasetsinfo.RData"))

regis = loadRegistry(paste0(dir, "/results/Splitbias-files"))

res = loadResults(regis)

res_oob = res[which(sapply(res, "[[", 2)[2,] == "oob")]

res_oob_new = list()
for(i in 1:nrow(datasetsinfo)){
  print(i)
  res_oob_new[[i]] = list(datasetsinfo[i,1], rowMeans(sapply(res_oob[sapply(res_oob, "[[", 1) == datasetsinfo[i,1]], "[[", 3)))
}

res = res[which(sapply(res, "[[", 2)[2,] != "oob")]
res = res[which(sapply(res, "[[", 2)[1,] == "randomForest")]
# Vergleich randomForest-CV5 mit randomForest-OOB

res_compr = list()
for(i in 1:length(res))
  res_compr[[i]] = colMeans(res[[i]][[3]])

head(res_oob_new)

#
ids = list()
ids[[1]] = datasetsinfo[which(datasetsinfo[,2] == 2), 1]
ids[[2]] = datasetsinfo[which(datasetsinfo[,2] != 2), 1]
ids[[3]] = datasetsinfo[which(is.na(datasetsinfo[,2])), 1]

for(i in which(datasetsinfo[,2] != 2))
print(res_oob_new[[i]][[2]][1:4] - res_compr[[i]][2:5])
# BER, brier und mmce werden meistens unterschätzt durch OOB
# werden tendenziell immer unterschätzt bei der OOB-Schätzung -> klar, da mehr Daten verwendet werden 
# (mehr Bäume machen den Braten dann auch nicht mehr fett)

for(i in which(datasetsinfo[,2] == 2))
  print(res_oob_new[[i]][[2]][1:5] - res_compr[[i]][c(2,4,5,7,3)])
# acc, ber, mmce unterscheiden sich kaum, brier und auc schon stark
# BRIER WIRD ANDERS BERECHNET ALS EIGENTLICH GEDACHT!, ebenso vermutlich AUC -> nicht zu retten, da unklar was positive und negative 
# Beobachtungen sind

for(i in which(is.na(datasetsinfo[,2])))
  print((res_oob_new[[i]][[2]][1:4] - res_compr[[i]][2:5])/res_compr[[i]][2:5])
# werden tendenziell immer unterschätzt bei der OOB-Schätzung -> klar, da mehr Daten verwendet werden 
# (mehr Bäume machen den Braten dann auch nicht mehr fett) (analog zu Klassifikation)

# Fazit: OOB-Fehler sind optimistischer als CV-5 Fehler (mehr Daten wichtiger als mehr Bäume)



