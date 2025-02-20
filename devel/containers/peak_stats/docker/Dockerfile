FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update
RUN apt-get update && apt-get install -y build-essential r-base
## enable R package install
RUN chmod a+w /usr/local/lib/R/site-library

RUN R -e 'install.packages("optparse")'
RUN R -e 'install.packages("stringr")'
RUN R -e 'install.packages("tibble")'
RUN R -e 'install.packages("dplyr")'
RUN R -e 'install.packages("ggplot2")'
RUN R -e 'install.packages("readr")'
RUN R -e 'install.packages("jsonlite")'