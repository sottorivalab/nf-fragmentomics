#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(tibble))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(fragmentomics))

#
# Usage: fragmentomics_peakStats.R [options] matrix
#
# Example:
#    fragmentomics_peakStats.R -s "Signal" -t "Target" -S "Source" matrix
#

option_list <- list(
  make_option(
    c("-r", "--random-points"),
    type = "integer",
    default = 10000,
    help = paste(
      "Number of random points to generate [default %default]"
    ),
    metavar = "number",
    dest = "random_points"
  ),

  make_option(
    c("-a", "--average-bp"),
    type = "integer",
    default = 1000,
    help = paste(
      "Average signal over this many base pairs",
      "[default %default]"
    ),
    metavar = "number",
    dest = "average_bp"
  ),

  make_option(
    "--background-left-limit",
    default = 50,
    help = "Background left limit [default %default]",
    dest = "bg_limit_left"
  ),

  make_option(
    "--background-right-limit",
    default = 50,
    help = "Background right limit [default %default]",
    dest = "bg_limit_right"
  ),

  make_option(
    "--central-coverage-bp",
    default = 30,
    help = "Central coverage [default %default]",
    dest = "central_coverage_bp"
  ),

  make_option(
    c("-s", "--signal"),
    type = "character",
    default = NA,
    help = "Signal name [default %default]",
    dest = "signal"
  ),

  make_option(
    c("-t", "--target"),
    type = "character",
    default = NA,
    help = "Target name [default %default]",
    dest = "target"
  ),

  make_option(
    c("-S", "--source"),
    type = "character",
    default = NA,
    help = "Source name [default %default]",
    dest = "source"
  )
)

# MAIN
# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults
if (sys.nframe() == 0L) {

  parser <- OptionParser(
    usage = "%prog [options] matrix", option_list = option_list
  )

  arguments <- parse_args(parser, positional_arguments = 1)
  opt <- arguments$options
  mfile   <- arguments$args

  # check if file exists
  if (file.access(mfile) == -1) {
    stop(sprintf("Specified file ( %s ) does not exist", mfile))
  }

  mdata <- fragmentomics::parse_compute_matrix(mfile)
  peak_data <- fragmentomics::peak_stats(
    mdata,
    signal_label = opt$signal,
    target_label = opt$target,
    source_label = opt$source,
    left         = opt$bg_limit_left,
    right        = opt$bg_limit_right,
    central      = opt$central_coverage_bp,
    rpoints      = opt$random_points,
    average      = opt$average_bp
  )

  write_delim(
    peak_data$average,
    paste(opt$target, "peak_data.tsv", sep = "_"),
    delim = "\t"
  )

  write_delim(
    peak_data$stats,
    paste(opt$target, "peak_stats.tsv", sep = "_"),
    delim = "\t"
  )

  pplot <- fragmentomics::peak_plot(peak_data, normalized = FALSE)
  ggsave(
    paste(opt$target, "RawSignal.pdf", sep = "_"),
    width = 29.7,
    height = 21,
    units = "cm"
  )

  rplot <- fragmentomics::peak_plot(peak_data, normalized = TRUE)
  ggsave(
    paste(opt$target, "RelativeSignal.pdf", sep = "_"),
    width = 29.7,
    height = 21,
    units = "cm"
  )
}
