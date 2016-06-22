library(mlr)
library(grid)
library(data.table)

setwd("/nfsmb/koll/probst/Random_Forest/RFSplitbias/results/")
load("/home/probst/Random_Forest/RFSplitbias/results/datasetsinfo.RData")
regis = loadRegistry("benchmark-ranger-split")

min(getJobStatus()$started, na.rm = T)
max(getJobStatus()$done, na.rm = T)
# 1 h

res_regr = reduceResultsDataTable( fun = function(r) as.data.frame(as.list(r)), reg = regis, fill = TRUE)

res_regr$did = rep(seq(1,111), each = 400)
res_regr$algo_id = rep(seq(1,400), 111)


Visualize_results = function (res_regr, hyp_par) {
  # Bilde Rankings!
  res_regr_aggr = res_regr[, list(algo_id = algo_id, mse = rank(mse), mae = rank(mae), medae = rank(medae), medse = rank(medse), timetrain = rank(timetrain)), by = did]
  res_regr_aggr = res_regr_aggr[, list(mse = mean(mse), mae = mean(mae), medae = mean(medae), medse = mean(medse), timetrain = mean(timetrain)), by = algo_id]
  #res_regr_aggr[, algo_id := NULL]

  hyp_par = hyp_par[, c("splitrule", "alpha", "minprop"), with = F]
  par(mfcol = c(2,5))
  for(k in colnames(res_regr_aggr)[2:6]) {
    data = cbind(res_regr_aggr[, k, with = F], hyp_par)
    
    #par(mfrow = c(1,1))
    #boxplot(data[, k, with = F], main = k)
    
    data[, "splitrule" := as.factor(data[["splitrule"]]), with = FALSE]
    data[, "alpha" := as.numeric(data[["alpha"]]), with = FALSE]
    data[, "minprop" := as.numeric(data[["minprop"]]), with = FALSE]
    
    #par(mfrow = c(1, 3))
    #for(j in colnames(data)[-1])
    #  plot(data[, k, with = F][[1]] ~ data[, j, with = FALSE][[1]], xlab = j, ylab = colnames(data)[1])
    
    
    plot(unlist(data[data$splitrule == "maxstat", 3, with = F]), unlist(data[data$splitrule == "maxstat",1, with = F]), 
         cex = 0.2, col = "blue", ylim = range(unlist(data[,1, with = F])), xlab = "alpha", ylab = k)
    points(unlist(data[data$splitrule == "variance", 3, with = F]), unlist(data[data$splitrule == "variance",1, with = F]), cex = 0.3, col = "red")
    legend("topright", c("maxstat", "variance"), col = c("blue", "red"), pch = 1, pt.cex = 0.3 )
    plot(unlist(data[data$splitrule == "maxstat", 4, with = F]), unlist(data[data$splitrule == "maxstat",1, with = F]), 
         cex = 0.2, col = "blue", ylim = range(unlist(data[,1, with = F])), xlab = "minprop", ylab = k)
    points(unlist(data[data$splitrule == "variance", 4, with = F]), unlist(data[data$splitrule == "variance",1, with = F]), cex = 0.3, col = "red")
    legend("topright", c("maxstat", "variance"), col = c("blue", "red"), pch = 1, pt.cex = 0.3 )
  }
}

# look only at datasets where ther is at least one categorical variable
index = res_regr$did %in% which(datasetsinfo[191:301, 5] > 0) & res_regr$algo_id %in% 301:400

pdf("benchmark-ranger-split.pdf",width=15,height=8.5)
Visualize_results(res_regr[res_regr$algo_id %in% 1:100], hyp_par = getJobTable()[1:100,])
Visualize_results(res_regr[res_regr$algo_id %in% 101:200], hyp_par = getJobTable()[101:200,])
Visualize_results(res_regr[res_regr$algo_id %in% 201:300], hyp_par = getJobTable()[201:300,])
Visualize_results(res_regr[res_regr$algo_id %in% 301:400], hyp_par = getJobTable()[301:400,])
Visualize_results(res_regr[index], hyp_par = getJobTable()[301:400,])
dev.off()


