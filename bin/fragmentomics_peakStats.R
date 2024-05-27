2#!/usr/bin/env Rscript
library(stringr)
library(tibble)
library(dplyr)
library(ggplot2)
library(readr)

random.points = 10000
background.limit.left = 50
background.limit.right = 750

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).", call.=FALSE)
}

# extract sample and target name
mfilename <- sub(".*\\/","",args[1])
mymeta <- str_match(mfilename,"([^_]*_[^_]*_[^_]*)_(.*)_matrix.gz")
mysignal <- mymeta[2]
mytarget <- mymeta[3]

mdata <- as_tibble(read.delim(args[1], header=F, skip=1))

peakData <- mdata %>% 
  select(c(-V1,-V2,-V3,-V4,-V5,-V6)) %>%
  mutate_all(function(x) ifelse(is.nan(x), NA, x)) %>%
  summarise(across(everything(), .f = list(mean), na.rm = TRUE)) %>%
  unlist()
peakData <- fortify(as.data.frame(peakData)) %>% 
  rename(raw="peakData") %>%
  mutate(bin=1:length(peakData))
rownames(peakData) <- NULL

# write peak means to build the profile plot
write_delim(peakData, paste(mysignal,mytarget,"peak_data.tsv",sep="_"), delim="\t")

# create random points
x1 = runif(random.points, min=1, max=(ncol(mdata)-6))
y1 = runif(random.points, min=min(peakData$raw) , max=max(peakData$raw))
mpoints = tibble(x=x1,y=y1)

# left join, this expand the peakData to N=random.points
mIntegrationData <- mpoints |> left_join(peakData,join_by(closest(x >= bin)))
# background using limits
mBackgroundData <- mIntegrationData |> filter(bin <= background.limit.left | bin >= background.limit.right)
upper.limit <- median(mBackgroundData$raw)
# annotate the points above and below
mIntegrationData <- mIntegrationData |> mutate(above=(y >= raw & y <= upper.limit))

# monte carlo integration
mintegration <- length(which(mIntegrationData$above)) / random.points

# min peak value
min.peak.position <- nrow(peakData) / 2
min.peak.value <- (mIntegrationData %>% filter(bin == min.peak.position))[1,]$raw

mpeak.length <- upper.limit - min.peak.value
mpeak.limits <- tibble(
  y=c(min(mIntegrationData$raw), upper.limit),
  x=c(min.peak.position,min.peak.position)
)
mpeak.ratio <- mintegration/mpeak.length

peakStats <- tibble(
  integration=mintegration,
  length=mpeak.length,
  ymin=min(mIntegrationData$raw),
  ymax=upper.limit,
  x=min.peak.position,
  ratio=mpeak.ratio
)

# write peak stats
write_delim(peakStats,paste(mysignal,mytarget,"peak_stats.tsv",sep="_"), delim="\t")

peak.limits <- tibble(
  y=c(peakStats$ymin, peakStats$ymax),
  x=c(min.peak.position,min.peak.position)
)

# plot
ggplot() +
  geom_line(data=mIntegrationData,aes(y=raw, x=bin)) +
  geom_point(data=mIntegrationData,aes(x = x, y = y, colour=above), size = .2) +
  geom_hline(yintercept = upper.limit, color="blue") +
  geom_vline(xintercept = background.limit.left, color="blue") +
  geom_vline(xintercept = background.limit.right, color="blue") +
  geom_point(data=peak.limits, aes(x=x, y=y), color="green", size=1) +
  geom_line(data=peak.limits, aes(x=x, y=y), color="green", linetype="dashed") +
  geom_point(data=peak.limits, aes(x=x, y=y), color="green", size=1) +
  xlab(paste("Target:",mytarget)) +
  ylab(paste("Signal:",mysignal)) +
  ggtitle(
    paste(
      "Peak integration: I=",
      round(mintegration,5),
      " L=", 
      round(mpeak.length,2), 
      " I/L=", 
      round(mpeak.ratio,2),
      " N=",
      nrow(mIntegrationData)
    )
  ) + theme(legend.position = "none")


mpeakplot_filename <- paste(mysignal,mytarget,"PeakIntegration.pdf",sep = "_")

ggsave(mpeakplot_filename)