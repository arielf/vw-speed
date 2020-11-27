#
# Makefile for vw-speed
#
SHELL := /bin/bash
export PATH := ./bin:~/bin:$(PATH)

LOGFILE = timings.log

EXAMPLES = 500000
FEATURES = 10

TRAINSET = trainset.$(EXAMPLES)-$(FEATURES).vw.gz

#
# To ensure apples-to-apples comparisons,
# e.g. make sure these vw binaries are:
#	- Fully optimized (production builds)
#	- Statically linked
# i.e.:
#	cmake .. -DSTATIC_LINK_VW=On -DDEFAULT_BUILD_TYPE=Release
#
VW_BINARIES = vw_binaries/vw-*

TSFORMAT = +%Y-%m-%d %H:%M:%S

VW = ~/bin/vw

#
# Adapt to taste (options you care about)
#
VWOPTS = --loss_function quantile \
	-k -c --passes 2 \
	--holdout_off

VWBASENAME = $$(basename $$(realpath $(VW)))
VWCMD = $(VWBASENAME) $(VWOPTS) -d $(TRAINSET)

.ONESHELL:

all: timeall

trainset $(TRAINSET): bin/train-set
	bin/train-set $(EXAMPLES) $(FEATURES) | gzip -v > $(TRAINSET)

train timeone: $(TRAINSET) bin/elapsed-time
	echo === benchmarking $(VWBASENAME) ...
	TS="$$(date "$(TSFORMAT)")"
	ELAPSED="$$(bin/elapsed-time $(VWCMD) 2>/dev/tty)"
	printf "%s\t%s\t%s\n" "$$TS" "$$ELAPSED" "$(VWCMD)" >> $(LOGFILE)

bench-all timeall:
	for vwexe in $(VW_BINARIES); do
		$(MAKE) VW="$$vwexe" VWOPTS="$(VWOPTS)" timeone
	done

chart:
	bin/vwver-boxplot.R

clean:
	rm *.cache
