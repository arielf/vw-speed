#!/usr/bin/Rscript
#
# Runtime distribution by VW version (on multiple simple data-sets)
#
library(ggplot2)
library(data.table)

eprintf <- function(...) cat(sprintf(...), sep='', file=stderr())
ymd     <- function() format(Sys.time(), "%Y-%m-%d")
argv0 <- sub('\\.R$', '', basename(
    grep('^--file=', commandArgs(trailingOnly=F), value=T))
)
geomSeries <- function(base, max) { base^(0:floor(log(max, base))) }
systemf <- function(...) system(sprintf(...))

Viewer = 'nomacs'
ChartFile = sprintf("%s.png", argv0)
DataFile = 'timings.log'

# DPI = 96
# Higher res looks much better
DPI = 192
FONTSIZE = 10
MyGray = 'grey50'

title.theme   <- element_text(family="FreeSans", face="bold.italic",
                            size=FONTSIZE-1, hjust=0.5, vjust=-0.2)
x.title.theme <- element_text(family="FreeSans", face="bold.italic",
                            size=FONTSIZE-2, hjust=0.5)
y.title.theme <- element_text(family="FreeSans", face="bold.italic",
                           size=FONTSIZE-2, angle=90)
x.axis.theme  <- element_text(family="FreeSans", face="bold",
                            size=FONTSIZE-2, color='black',
                            angle=45, hjust=1, vjust=1)
y.axis.theme  <- element_text(family="FreeSans", face="bold",
                            size=FONTSIZE-2, color=MyGray)
legend.title  <- element_text(family="FreeSans", face="bold.italic",
                            size=FONTSIZE-2, color="black")
legend.text  <- element_text(family="FreeSans", face="bold.italic",
                            size=FONTSIZE-3, color="black")

mytheme <- function() {
        theme(
            plot.title=title.theme,
            axis.title.y=y.title.theme,
            axis.title.x=x.title.theme,
            axis.text.x=x.axis.theme,
            axis.text.y=y.axis.theme,
            legend.title=element_blank(),
            legend.text=legend.text
        )
}

read.cols = c('Time', 'Command')

d = fread(DataFile, select=read.cols, header=TRUE)
# Convert Command column values to only 1st word (vw-version)
d$VwVersion = gsub(' .*$', '', d$Command)

min.time = min(d$Time, na.rm=TRUE)
max.time = max(d$Time, na.rm=TRUE)

eprintf("min.time=%s max.time=%s\n", min.time, max.time)

d.m <- melt(d, id.vars=c('VwVersion'), measure.vars=c('Time'))
d.m = d.m[, c('VwVersion', 'value')]

names(d.m) <- c('variable', 'value')
head(d.m, 20)

versions = sort(d.m$VwVersion)

g <- ggplot(d.m, aes(y=value, fill=variable)) +
    stat_boxplot(geom='errorbar', lwd=0.4, width=1.8,
                 position=position_dodge(6)) +
    geom_boxplot(
                lwd=0.4,
                width=4,
                position=position_dodge(6),
                # notch=TRUE,
                outlier.size=0.12, outlier.shape=19,
                outlier.color='#555555',
                na.rm=TRUE) +
    ggtitle("Elapsed run-time distributions by VW version") +
    ylab("Runtime (seconds)") +
    scale_x_discrete(labels=versions) +
    scale_y_continuous(limits=c(min.time, max.time),
                       breaks=seq(0, max.time, by=0.25)) +
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
