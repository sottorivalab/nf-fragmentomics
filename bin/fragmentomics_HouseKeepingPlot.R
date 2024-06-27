#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(forcats))
suppressPackageStartupMessages(library(gridExtra))

# specify our desired options in a list
option_list <- list(
    make_option(
        c("-s","--sample"),
        type="character",
        help="sample name",
        dest="sample"
    )
)

parser <- OptionParser(usage = "%prog [options] matrix", option_list=option_list)
arguments <- parse_args(parser, positional_arguments = TRUE)
opt <- arguments$options
mfiles <- arguments$args
sample <- opt$sample


hk.list <- lapply(mfiles, function(file) {
   mname <- str_replace(str_replace(str_replace(file, ".*/",""),"_GENEHANCER_peak_data\\.tsv",""),paste(sample,"_",sep=""),"")
   tdata <- read_tsv(file, col_types = "didd") |> mutate(dataset=mname)
   return(tdata)
})

hk.data <- bind_rows(hk.list) |>
    mutate(type=if_else(dataset == "HouseKeeping","HouseKeeping","Random")) |>
    mutate(type=ordered(type, levels = c("Random","HouseKeeping"))) |>
    arrange(desc(dataset)) |>
    mutate(dataset=fct_rev(factor(dataset)))

random.data <- hk.data |> filter(type == "Random")
housekeeping.data <- hk.data |> filter(type == "HouseKeeping")

random.ci <- random.data |>
  group_by(bin) |>
  dplyr::summarise(
    mean = mean(raw), 
    sd  = sd(raw),
    n   = n()
  ) |>
  mutate(
    se = sd/sqrt(n),
    lower.ci = mean - qt(1 - (0.05 / 2), n - 1) * se,
    upper.ci = mean + qt(1 - (0.05 / 2), n - 1) * se
  )

relative.ci <- random.data |>
  group_by(bin) |>
  dplyr::summarise(
    mean = mean(relative), 
    sd  = sd(relative),
    n   = n()
  ) |>
  mutate(
    se = sd/sqrt(n),
    lower.ci = mean - qt(1 - (0.05 / 2), n - 1) * se,
    upper.ci = mean + qt(1 - (0.05 / 2), n - 1) * se
  )

random.sets.count <- length(unique(random.data$dataset))
plot.title <- paste(sample, ":HouseKeeping vs ",random.sets.count, " random sets", sep="")

raw.plt <- ggplot() +
  geom_line(data = hk.data, aes(x = bin, y = raw, group = dataset, color=type)) +
  geom_line(data = random.ci, aes(x = bin, y = mean), color="black", show.legend = FALSE) +
  scale_x_continuous(
    "Position relative to TSS (bp)", 
    breaks = c(0,200,400,600,800), 
    labels = c("-4000","-2000","0","2000","4000")
  ) +
  ylab("Raw coverage") +
  ggtitle(plot.title) +
  scale_color_manual(values=c("grey","red")) +
  theme(legend.position = "bottom") 

relative.plt <- ggplot() +
  geom_line(data = hk.data, aes(x = bin, y = relative, group = dataset, color=type)) +
  geom_line(data = relative.ci, aes(x = bin, y = mean), color="black", show.legend = FALSE) +
  scale_x_continuous(
    "Position relative to TSS (bp)", 
    breaks = c(0,200,400,600,800), 
    labels = c("-4000","-2000","0","2000","4000")
  ) +
  ylab("Raw coverage") +
  ggtitle(plot.title) +
  scale_color_manual(values=c("grey","red")) +
  theme(legend.position = "bottom") 

raw.outfile <- paste(sample, "HouseKeeping_raw_signal.pdf",sep="_")
ggsave(raw.outfile, plot=raw.plt)

relative.outfile <- paste(sample, "HouseKeeping_relative_signal.pdf",sep="_")
ggsave(relative.outfile, plot=relative.plt)

