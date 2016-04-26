dir = "/nfsmb/koll/probst/Random_Forest/RFSplitbias"
#dir = "/home/philipp/Promotion/RandomForest/RFSplitbias"
setwd(paste0(dir,"/results"))
load(paste0(dir,"/results/clas.RData"))
load(paste0(dir,"/results/reg.RData"))

tasks = rbind(clas_small, reg_small)

datasetsinfo = matrix(NA, nrow = nrow(tasks), ncol = 5)
nfactor = vector("list", nrow(tasks))
colnames(datasetsinfo) = c("idi", "nclass", "ncol", "num_feat", "factor_feat")

for (i in 1:nrow(tasks)) {
  print(i)
  task = getOMLTask(task.id = tasks$task_id[i], verbosity=0)$input$data.set
  datasetsinfo[i,1] = tasks$task_id[i]
  if(tasks$task_type[i] == "Supervised Classification"){
    lvl = table(task$data[, task$target])
    task$data = task$data[task$data[, task$target] %in% names(lvl[lvl >= 5]), ] 
    datasetsinfo[i,2] = length(levels(droplevels(as.factor(task$data[, task$target]))))
  }
  data = task$data[, !(colnames(task$data) %in% task$target)]
  datasetsinfo[i,3] = ncol(data)
  datasetsinfo[i,4] = sum(sapply(data, class) == "numeric")
  datasetsinfo[i,5] = sum(sapply(data, class) == "factor")
  if (datasetsinfo[i,5] != 0)
  nfactor[[i]] = table(sapply(as.data.frame(data[,sapply(data, class) == "factor"]), nlevels))
}

save(datasetsinfo, nfactor, file="/home/probst/Random_Forest/RFSplitbias/results/datasetsinfo.RData")
  