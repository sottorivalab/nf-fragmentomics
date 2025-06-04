FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update
RUN apt-get update && apt-get install -y build-essential r-base r-cran-tidyverse

## enable R package install
RUN chmod a+w /usr/local/lib/R/site-library

RUN R -e 'install.packages("optparse")'
RUN R -e 'devtools::install_github("sottorivalab/fragmentomics", dep = FALSE)'