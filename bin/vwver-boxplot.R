#!/usr/bin/Rscript
#
# Runtime distribution by VW version (on multiple simple data-sets)
#
library(ggplot2)
library(data.table)

eprintf <- function(...) cat(sprintf(...), sep='', file=stderr())
ymd     <- function() format(Sys.time(), "%Y-%m-%d")
Args    <- commandArgs(trailingOnly=F)
argv0 <- sub('\\.R$', '', basename(grep('^--file=', Args, value=T)))
argvN   <- Args[length(Args)]
systemf <- function(...) system(sprintf(...))

Viewer = 'nomacs'
ChartFile = sprintf("%s.png", argv0)

usage <- function(...) {
    eprintf(...)
    eprintf("Usage: %s [datafile.log]\n", argv0)
    quit()
}

DataFile = 'timings.log'
if (endsWith(argvN, '.log')) {
    if (file.exists(argvN)) {
        DataFile <- argvN
    } else {
        usage("%s does not exist\n", argvN)
    }
}

# DPI = 96
# Higher res looks much better
DPI = 192
FONTSIZE = 10
MyGray = 'grey50'

title.theme   <- element_text(family='FreeSans', face='bold.italic',
                            size=FONTSIZE-1, hjust=0.5, vjust=-0.2)
x.title.theme <- element_text(family='FreeSans', face='bold.italic',
                            size=FONTSIZE-2, hjust=0.5)
y.title.theme <- element_text(family='FreeSans', face='bold.italic',
                           size=FONTSIZE-2, angle=90)
x.axis.theme  <- element_text(family='FreeSans', face='bold',
                            size=FONTSIZE-2, color='grey40',
                            angle=45, hjust=1, vjust=1)
y.axis.theme  <- element_text(family='FreeSans', face='bold',
                            size=FONTSIZE-2, color=MyGray)
legend.title  <- element_text(family='FreeSans', face='bold.italic',
                            size=FONTSIZE-2, color='black')
legend.text  <- element_text(family='FreeSans', face='bold.italic',
                            size=FONTSIZE-3, color='black')

mytheme <- function() {
        theme(
            plot.title=title.theme,
            axis.title.x=x.title.theme,
            axis.title.y=y.title.theme,
            axis.text.x=x.axis.theme,
            axis.text.y=y.axis.theme,
            legend.text=legend.text,
            legend.title=element_blank()
        )
}

read.cols = c('Time', 'Command')

d = fread(DataFile, select=read.cols, header=TRUE)
# Convert Command column values to only 1st word (vw-version)
d$VwVersion = gsub(' .*$', '', d$Command)

min.time = min(d$Time)
max.time = max(d$Time)

eprintf("min.time=%s max.time=%s\n", min.time, max.time)

d.m <- melt(d, id.vars=c('VwVersion'), measure.vars=c('Time'))
d.m = d.m[, c('VwVersion', 'value')]

names(d.m) <- c('variable', 'value')
head(d.m, 40)

VwVersions = sort(unique(d.m$variable))

g <- ggplot(d.m, aes(x=variable, y=value, fill=variable)) +
    stat_boxplot(geom='errorbar', lwd=0.4, width=0.25,
                  position=position_dodge(2)) +
    geom_boxplot(
                lwd=0.4,
                width=0.6,
                position=position_dodge(2),
                # notch=TRUE,
                outlier.size=0.12, outlier.shape=19,
                outlier.color='#555555') +
    ggtitle("Elapsed run-time distributions by VW version") +
    xlab(NULL) +
    scale_x_discrete(breaks=VwVersions, labels=VwVersions) +
    ylab("Runtime (seconds)") +
    scale_y_continuous(limits=c(min.time, max.time)) +
    mytheme()

ggsave(
    file=ChartFile,
    plot=g,
    device='png',
    dpi=DPI,
    units='cm',
    width=16,
    height=16,
)

systemf("%s %s 2>/dev/null &", Viewer, ChartFile)
