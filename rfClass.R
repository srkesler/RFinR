#Shelli Kesler 10/20/15 Updated 11/19/16
#Random forest classification using out-of-bag (OOB) prediction
# NOTE: the outcome variable must be in the last column of the dataframe
# NOTE: dataframe must contain complete cases only
# NOTE: if imbalanced groups, edit binomtest
# Example Usage: rfClass(mydata)
# Multtest package install: http://bioconductor.org/packages/release/bioc/html/multtest.html

rfClass <- function(traindata){
  library(doMC);registerDoMC(cores=detectCores())
  library(randomForest)
  library(caret)
  #library(AUC)
  library(pRF)
  library(multtest)
  library(rfUtilities)
  set.seed(100)
  nsubs=nrow(traindata)
  X <- as.matrix(traindata[,-ncol(traindata)]); Y <- as.factor(traindata[,ncol(traindata)])
  mtry <- round(sqrt(X))
  rfFitoob <<- randomForest(X,Y,mtry=mtry,ntree=500,replace=T)
  #save(rfFitoob,file=paste(title,'.RData',sep =""))
  predictions <- predict(rfFitoob,type="response") #if no testing data is specified, the OOB prediction is given
  probs <- predict(rfFitoob,type="prob")[,2]
  CM<-confusionMatrix(predictions,Y)
  myclass<-as.vector(CM$table)
  nsucc<-(myclass[1]+myclass[4]) # true negatives + true positives
  sens<-(myclass[4]/(myclass[4]+myclass[3]))
  spec<-(myclass[1]/(myclass[1]+myclass[2]))
  acc<-nsucc/nsubs
  kap <- accuracy(predictions,Y)
  binomtest <- binom.test(nsucc,nsubs,.5, alternative = "two.sided",conf.level = 0.95)
  p.test <- pRF(response=Y,predictors=X,n.perms=100,mtry=mtry,type="classification",alpha=0.05,ntree=500,seed=100)
  pvals <-cbind(p.test$Res.table,p.test$obs)
  detach("package:rfUtilities")
  library(AUC)
  rfauc <- auc(roc(probs,Y))
  plot(roc(probs,Y),col="red")
  probs.train <<- probs
  labels <- c('Accuracy','pval','AUC','Sens','Spec','Kappa')
  S <-c(acc,binomtest$p.value,rfauc,sens,spec,kap$kappa)
  stats <- data.frame(matrix(ncol = 6, nrow = 0))
  colnames(stats)=labels; stats[1,]=S
  results.train <<- list(stats,pvals)
  #write.csv(results,file=paste(title,'_Results.csv',sep = ""))
  return(results.train)
  #varImpPlot(rfFitoob)
  #mean(rfFitoob$importance)+sd(rfFitoob$importance)
}
