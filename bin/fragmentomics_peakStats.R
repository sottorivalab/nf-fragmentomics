#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(tibble))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(readr))

# specify our desired options in a list
option_list <- list(
  make_option(
    c("-r", "--random-points"), 
    type="integer", 
    default=10000,
    help="Number of random points to generate in Monte Carlo integration [default %default]",
    metavar="number",
    dest="random.points"
  ),

  make_option(
    "--background-left-limit", 
    default=50, 
    help="Background left limit [default %default]",
    dest="bg.limit.left"
  ),

  make_option(
    "--background-right-limit", 
    default=750, 
    help="Background left limit [default %default]",
    dest="bg.limit.right"
  ),

  make_option(
    c("-s","--signal"),
    type="character",
    default=NA,
    help="Signal name [default %default]",
    dest="signal"
  ),

  make_option(
    c("-p","--ploidy"),
    type="character",
    default=NA,
    help="Ploidy [default %default]",
    dest="ploidy"
  ),

  make_option(
    c("-t","--target"),
    type="character",
    default=NA,
    help="Target name [default %default]",
    dest="target"
  ),

  make_option(
    c("-S","--source"),
    type="character",
    default=NA,
    help="Source name [default %default]",
    dest="source"
  )
)

# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults
parser <- OptionParser(usage = "%prog [options] matrix", option_list=option_list)
arguments <- parse_args(parser, positional_arguments = 1)
opt <- arguments$options
mfile   <- arguments$args

if (file.access(mfile) == -1) {
  stop(sprintf("Specified file ( %s ) does not exist", mfile))
}

alldata <- as_tibble(read.delim(mfile, header=F, skip=1))

mdata <- alldata %>% 
  select(c(-V1,-V2,-V3,-V4,-V5,-V6)) %>%
  mutate_all(function(x) ifelse(is.nan(x), NA, x)) %>%
  summarise(across(everything(), \(x) mean(x, na.rm = TRUE))) %>%
  unlist()

mdata <- fortify(as.data.frame(mdata)) %>%
  rename(raw="mdata") %>%
  mutate(bin=1:length(mdata))

rownames(mdata) <- NULL

# write summarized datas as peak_data.tsv
output.data.file.name <- paste(opt$signal, opt$ploidy, opt$target, opt$source, "peak_data.tsv", sep="_")
write_delim(mdata, output.data.file.name, delim="\t")

# create random points. 1<x<800 (number of bins of matrix)
x1 = runif(opt$random.points, min=1, max=(ncol(alldata)-6))
y1 = runif(opt$random.points, min=min(mdata$raw) , max=max(mdata$raw))
mpoints = tibble(x=x1,y=y1)

# left join, this expand the mdata to N=random.points
mIntegrationData <- mpoints |> left_join(mdata,join_by(closest(x >= bin)))

# background using limits
mBackgroundData <- mIntegrationData |> filter(bin <= opt$bg.limit.left | bin >= opt$bg.limit.right)
upper.limit <- median(mBackgroundData$raw)

# annotate the points above and below
mIntegrationData <- mIntegrationData |> mutate(above=(y >= raw & y <= upper.limit))

# monte carlo integration
mintegration <- length(which(mIntegrationData$above)) / opt$random.points

# min peak value
min.peak.position <- nrow(mdata) / 2
min.peak.value <- (mIntegrationData %>% filter(bin == min.peak.position))[1,]$raw

mpeak.length <- upper.limit - min.peak.value
mpeak.limits <- tibble(
  y=c(min(mIntegrationData$raw), upper.limit),
  x=c(min.peak.position,min.peak.position)
)
mpeak.ratio <- mintegration/mpeak.length

peak.stats <- tibble(
  signal=opt$signal,
  ploidy=opt$ploidy,
  target=opt$target,
  source=opt$source,
  integration=mintegration,
  length=mpeak.length,
  ymin=min(mIntegrationData$raw),
  ymax=upper.limit,
  x=min.peak.position,
  ratio=mpeak.ratio
)

print(str(peak.stats))

# write peak stats
output.stats.file.name <- paste(opt$signal, opt$ploidy, opt$target, opt$source, "peak_stats.csv", sep="_")
write_csv(peak.stats,output.stats.file.name)

peak.limits <- tibble(
  y=c(peak.stats$ymin, peak.stats$ymax),
  x=c(peak.stats$x,peak.stats$x)
)

# plot
ggplot() +
  geom_line(data=mIntegrationData,aes(y=raw, x=bin)) +
  geom_point(data=mIntegrationData,aes(x = x, y = y, colour=above), size = .2) +
  geom_hline(yintercept = upper.limit, color="blue") +
  geom_vline(xintercept = opt$bg.limit.left, color="blue") +
  geom_vline(xintercept = opt$bg.limit.right, color="blue") +
  geom_point(data=peak.limits, aes(x=x, y=y), color="green", size=1) +
  geom_line(data=peak.limits, aes(x=x, y=y), color="green", linetype="dashed") +
  geom_point(data=peak.limits, aes(x=x, y=y), color="green", size=1) +
  xlab(paste("Target:",opt$target)) +
  ylab(paste("Signal:",opt$signal)) +
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


output.plot.file.name <- paste(opt$signal, opt$ploidy, opt$target, opt$source, "PeakIntegration.pdf", sep="_")
ggsave(output.plot.file.name)