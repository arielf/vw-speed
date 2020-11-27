#
# Makefile for vw-speed
#
SHELL := /bin/bash
export PATH := ./bin:./vw_binaries:$(PATH)

LOGFILE = timings.log

EXAMPLES = 500000
FEATURES = 10

TRAINSET = trainset.$(EXAMPLES)-$(FEATURES).vw

#
# Ensure apples-to-apples comparisons,
# e.g. make sure these vw binaries are:
#	- Run on the same system, under similar load conditions
#	- Binaries are:
#		- Fully optimized (production builds)
#		- Statically linked
# 	  i.e. in the vw source tree build dir:
#		cmake .. -DSTATIC_LINK_VW=On -DCMAKE_BUILD_TYPE=Release
#	  followed by a build at the top level:
#		make vw-bin
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

.PRECIOUS: *.vw *.vw.gz *.log

.ONESHELL:

all: timeall

trainset $(TRAINSET): bin/train-set
	TMP_TRAINSET=trainset.vw
	bin/train-set $(EXAMPLES) $(FEATURES) > $$TMP_TRAINSET
	if [[ "$(TRAINSET)" =~ *.gz ]]; then
		gzip -v  -c $$TMP_TRAINSET > $(TRAINSET)
	else
		mv -f $$TMP_TRAINSET $(TRAINSET)
	fi

train timeone: $(TRAINSET) bin/elapsed-time
	echo === benchmarking $(VWBASENAME) ...
	TS="$$(date "$(TSFORMAT)")"
	ELAPSED="$$(bin/elapsed-time $(VWCMD) 2>/dev/tty)"
	if [[ ! -e $(LOGFILE) ]]; then
	    printf 'DateTime\tUser\tSystem\tTime\tCpuPct\tCommand\n' >$(LOGFILE)
	fi
	printf "%s\t%s\t%s\n" "$$TS" "$$ELAPSED" "$(VWCMD)" >> $(LOGFILE)

bench-all timeall:
	for vwexe in $(VW_BINARIES); do
		$(MAKE) VW="$$vwexe" VWOPTS="$(VWOPTS)" timeone
	done

chart:
	bin/vwver-boxplot.R $(LOGFILE)

clean:
	rm *.cache
