#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(tibble))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(jsonlite))

#
# Usage: fragmentomics_peakStats.R [options] matrix
#
# Example: 
#    fragmentomics_peakStats.R -s "Signal" -t "Target" -S "Source" matrix
#    fragmentomics_peakStats.R -s "Signal" -t "Target" -S "Source" --background-left-limit 50 --background-right-limit 50 matrix

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
    default=50, 
    help="Background right limit [default %default]",
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

# MAIN
# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults
parser <- OptionParser(usage = "%prog [options] matrix", option_list=option_list)
arguments <- parse_args(parser, positional_arguments = 1)
opt <- arguments$options
mfile   <- arguments$args

# check if file exists
if (file.access(mfile) == -1) {
  stop(sprintf("Specified file ( %s ) does not exist", mfile))
}

# parameters
central.coverage.bp <- 30

# get headers, read matrix as tibble and rename columns
all.data <- as_tibble(read.delim(mfile, header=F, skip=1))
headers <- fromJSON(str_remove(read_lines(mfile, n_max = 1), "@"))

column.lookup <- c(
  chr = "V1",
  start = "V2",
  end = "V3",
  name = "V4",
  score = "V5",
  strand = "V6"
)

bins <- colnames(all.data)[7:length(colnames(all.data))]
for (i in 1:length(bins)) {
  source = bins[i]
  target = paste("bin_",i, sep="")
  column.lookup[target] = source
}

all.data <- rename(all.data, all_of(column.lookup))

# remove columns 1:6 and remove NaN
to.remove <- names(column.lookup[1:6])
m.data <- all.data |>
  select(-all_of(to.remove)) |>
  mutate_all(function(x) ifelse(is.nan(x), NA, x))

# summarize data
summary.data <- m.data |>
  summarise(across(everything(), \(x) mean(x, na.rm = TRUE)))

summary.table <- tibble(
  bin=1:ncol(summary.data),
  coverage=t(summary.data)[,1]
)

# calculate background median
limits <- list(min = opt$bg.limit.left, max = nrow(summary.table) - opt$bg.limit.right)
background.data <- summary.table |>
  filter(bin <= limits$min | bin >= limits$max)  
background.mean <- mean(background.data$coverage)

# create random points. 1<x<800 (number of bins of matrix)
x1 <- runif(opt$random.points, min=1, max=nrow(summary.table))
y1 <- runif(opt$random.points, min=min(summary.table$coverage) , max=max(summary.table$coverage))
random.points <- tibble(x=x1,y=y1) |> arrange(x)

# left join, this expand the data to N=random.points, annotate the points above and below
integration.data <- random.points |> 
  left_join(summary.table, join_by(closest(x >= bin))) |>
  mutate(
    above=(y >= coverage & y <= background.mean),
    background.mean=background.mean
  )

# monte carlo integration
montecarlo.integration <- length(which(integration.data$above)) / nrow(integration.data)

# relative signal
summary.table <- summary.table |> 
  mutate(
    relative=coverage/background.mean, 
    background.mean=background.mean
  )

# stats
central.bin <- round(max(summary.table$bin)/2, digits=0)

# referencePoint coverage
referencePoint.coverage <- summary.table |> filter(bin == central.bin)

# bin size
bin.size <- as.numeric(headers["bin size"])

central.coverage.bp <- 30
central.coverage.bin.min <- central.bin - central.coverage.bp / bin.size
central.coverage.bin.max <- central.bin + central.coverage.bp / bin.size
central.coverage.data <- summary.table |> 
  filter(bin >= central.coverage.bin.min, bin <= central.coverage.bin.max) |> 
  select(coverage)
central.coverage <- mean(central.coverage.data$coverage)

# average coverage
average.coverage.bp <- 1000
average.coverage.bin.min <- central.bin - (average.coverage.bp / bin.size)
average.coverage.bin.max <- central.bin + (average.coverage.bp / bin.size)
average.coverage.data <- summary.table |> 
  filter(bin >= average.coverage.bin.min, bin <= average.coverage.bin.max) |> 
  select(coverage)
average.coverage <- mean(average.coverage.data$coverage)

# write matrix as tibble RDS with renamed columns
write_rds(all.data, paste(opt$signal, opt$target, opt$source, "matrix.RDS", sep="_"))

# write composite coverage as peak_data.tsv
write_delim(summary.table, paste(opt$signal, opt$target, opt$source, "peak_data.tsv", sep="_"), delim="\t")

# peak stats
central.bin <- round(max(summary.table$bin)/2, digits=0)
referencePoint <- summary.table |> filter(bin == central.bin)
bin.size <- as.numeric(headers["bin size"])

# central coverage
central.coverage.bp <- 30
central.coverage.bin.min <- central.bin - (central.coverage.bp / bin.size)
central.coverage.bin.max <- central.bin + (central.coverage.bp / bin.size)
central.coverage.data <- summary.table |> 
  filter(bin >= central.coverage.bin.min, bin <= central.coverage.bin.max) |> 
  select(coverage)
central.coverage <- mean(central.coverage.data$coverage)

# average coverage
average.coverage.bp <- 1000
average.coverage.bin.min <- central.bin - (average.coverage.bp / bin.size)
average.coverage.bin.max <- central.bin + (average.coverage.bp / bin.size)
average.coverage.data <- summary.table |> 
  filter(bin >= average.coverage.bin.min, bin <= average.coverage.bin.max) |> 
  select(coverage)
average.coverage <- mean(average.coverage.data$coverage)

# peak.stats
peak.stats <- tibble(
  signal=opt$signal,
  target=opt$target,
  source=opt$source,
  integration=montecarlo.integration,
  background.mean=background.mean,
  referencePoint.bin=central.bin,
  referencePoint.coverage=referencePoint$coverage,
  referencePoint.relative=referencePoint$relative,
  central.coverage=central.coverage,
  central.coverage.bin.min=central.coverage.bin.min,
  central.coverage.bin.max=central.coverage.bin.max,
  background.left.limit=limits$min,
  background.right.limit=limits$max,
  average.coverage=average.coverage,
  average.coverage.bin.min=average.coverage.bin.min,
  average.coverage.bin.max=average.coverage.bin.max,
  peak.length=background.mean - as.numeric(referencePoint$coverage),
  peak.relative.length=1-referencePoint$relative
)

# write peak_stats.tsv
write_delim(peak.stats, paste(opt$signal, opt$target, opt$source, "peak_stats.tsv", sep="_"), delim="\t")

# labels
label.pos <- -(max(summary.table$bin) * .1)
peak.length <- tibble(
  x=max(summary.table$bin),
  y=c(
    peak.stats$referencePoint.coverage,
    peak.stats$background.mean
  )
)
peak.relative.length <- tibble(
  x=max(summary.table$bin),
  y=c(
    peak.stats$referencePoint.relative,
    1
  )
)

# plot raw signal
ggplot() +
  # composite coverage
  geom_line(data=summary.table,aes(y=coverage, x=bin)) +
  # integration data
  geom_point(data=integration.data,aes(x = x, y = y, color=above), size = .2, alpha = .5) +
  scale_color_manual(values=c("#D3D3D3", "#56B4E9")) +
  # background mean
  geom_hline(yintercept = peak.stats$background.mean, color="#6082B6", linetype = 'dotted') +
  geom_text(aes(label.pos,peak.stats$background.mean,label = "background"), color="#6082B6", size = 2.5, vjust = -1) +
  geom_rect(aes(xmin = 0,xmax = peak.stats$background.left.limit,  ymin=min(summary.table$coverage),ymax=max(summary.table$coverage)),
    color="#6082B6",
    alpha = .15
  ) +
  geom_rect(
    aes(
      xmin = peak.stats$background.right.limit, 
      xmax = max(summary.table$bin), 
      ymin=min(summary.table$coverage),
      ymax=max(summary.table$coverage)
    ),
    color="#6082B6",
    alpha = .15
  ) +
  # reference coverage
  geom_hline(yintercept = peak.stats$referencePoint.coverage, color="#6082B6", linetype = 'dotted') +
  geom_text(aes(label.pos,peak.stats$referencePoint.coverage,label = "reference"), size = 2.5, vjust = 1, color="#6082B6") +
  # central coverage
  geom_hline(yintercept = peak.stats$central.coverage, color="orange", linetype = 'dotted') +
  geom_text(aes(label.pos,peak.stats$central.coverage,label = "central"), size = 2.5, vjust = -1, color="orange") +
  # central coverage limits
  geom_rect(
    aes(
      xmin = peak.stats$central.coverage.bin.min, 
      xmax = peak.stats$central.coverage.bin.max, 
      ymin=min(summary.table$coverage),
      ymax=max(summary.table$coverage)
    ),
    alpha=.25,
    color="orange",
    fill="orange"
  ) +
  # average coverage
  geom_hline(yintercept = peak.stats$average.coverage, color="red", linetype = 'dotted') +
  geom_text(aes(label.pos,peak.stats$average.coverage,label = "average"), size = 2.5, vjust = -1, color="red") +
  # average coverage limits
  geom_rect(
    aes(
      xmin = peak.stats$average.coverage.bin.min, 
      xmax = peak.stats$average.coverage.bin.max, 
      ymin=min(summary.table$coverage),
      ymax=max(summary.table$coverage)
    ),
    alpha=.15,
    color="red",
    fill="red"
  ) +
  # length
  geom_point(data=peak.length, aes(x=x, y=y), color="green", size=1) +
  geom_line(data=peak.length, aes(x=x, y=y), color="green", linetype="dashed") +
  # labels
  xlab(paste(opt$target)) +
  ylab(paste(opt$signal)) +
  ggtitle(
    paste("Composite coverage: ", opt$target, "on", opt$signal, sep=" "),
    subtitle = paste(
      "reference=",
      round(peak.stats$referencePoint.coverage, digits=4),
      " central=",
      round(peak.stats$central.coverage, digits=4),
      " average=",
      round(peak.stats$average.coverage, digits=4),
      " background=",
      round(peak.stats$background.mean,digits=4),
      " length=",
      round(peak.stats$peak.length,digits=4),
      sep=""
    )
  ) +
  scale_x_continuous(
    "Position relative to TSS (bp)", 
    breaks = c(0,100,200,300,400,500,600,700,800), 
    labels = c("-4kb","-3kb","-2kb","-1kb","0","1kb","2kb","3kb","4kb")
  ) +
  theme(legend.position = "none")

ggsave(paste(opt$signal, opt$target, opt$source, "RawSignal.pdf", sep="_"), width=29.7, height=21, units="cm")

# plot relative signal
ggplot() +
  # composite coverage
  geom_line(data=summary.table,aes(y=relative, x=bin)) +
  geom_hline(yintercept = 1, color="#6082B6", linetype = 'dotted') +
  # length
  geom_point(data=peak.relative.length, aes(x=x, y=y), color="green", size=1) +
  geom_line(data=peak.relative.length, aes(x=x, y=y), color="green", linetype="dashed") +
  # labels
  xlab(paste(opt$target)) +
  ylab(paste(opt$signal)) +
  ggtitle(
    paste("Composite coverage: ", opt$target, "on", opt$signal, sep=" "),
    subtitle = paste(
      "relative=",
      round(peak.stats$referencePoint.relative, digits=4),
      " relative length=",
      round(peak.stats$peak.relative.length,digits=4),
      sep=""
    )
  ) +
  scale_x_continuous(
    "Position relative to TSS (bp)", 
    breaks = c(0,100,200,300,400,500,600,700,800), 
    labels = c("-4kb","-3kb","-2kb","-1kb","0","1kb","2kb","3kb","4kb")
  ) +
  theme(legend.position = "none")

ggsave(paste(opt$signal, opt$target, opt$source, "RelativeSignal.pdf", sep="_"), width=29.7, height=21, units="cm")