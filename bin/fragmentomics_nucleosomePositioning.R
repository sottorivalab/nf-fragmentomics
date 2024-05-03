#!/usr/bin/env Rscript

ideo <- loadIdeogram("hg38", chrom=c("chr12"))
dataList <- trim(ideo)
dataList$score <- as.numeric(as.factor(dataList$gieStain))
dataList <- dataList[dataList$gieStain!="gneg"]
dataList <- GRangesList(dataList)
ideogramPlot(ideo, dataList, layout=list("chr12"))
