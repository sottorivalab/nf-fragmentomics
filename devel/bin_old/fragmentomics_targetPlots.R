#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(forcats))


# specify our desired options in a list
option_list <- list(
    make_option(
        c("-s","--samples"),
        type="character",
        help="samples names",
        dest="samples"
    ),
    make_option(
        c("-o","--outfile"),
        type="character",
        help="output file",
        dest="outfile"
    )
)

parser <- OptionParser(usage = "%prog [options] matrix", option_list=option_list)
arguments <- parse_args(parser, positional_arguments = TRUE)
opt <- arguments$options
mfiles <- arguments$args
samples <- str_split_1(opt$samples,",")

peak.data <- list()

for (i in 1:length(mfiles)) {
    s <- samples[i]
    m <- mfiles[i]
    d <- read_tsv(m, col_types = "didd") |> mutate(sample=s)
    peak.data[[s]] <- d
}

all.data <- bind_rows(peak.data) |> mutate(sample=as.factor(sample))


m.max <- max(all.data$relative)
m.limit <- m.max + (m.max * 0.25)

plt1 <- ggplot(data = all.data, aes(x = bin, y = relative, group = sample, color=sample)) +
    ylim(0, m.limit) + 
    geom_line() +
    theme(legend.position = "bottom") +
    scale_x_continuous("Position relative to TSS (bp)", breaks = c(0,200,400,600,800), labels = c("-4000","-2000","0","2000","4000")) +
    scale_color_brewer(palette="Dark2")
ggsave(opt$outfile, plot=plt1)