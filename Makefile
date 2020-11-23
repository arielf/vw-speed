SHELL := /bin/bash
export PATH := ./bin:~/bin:$(PATH)

LOGFILE = timings.log

EXAMPLES = 500000
FEATURES = 10

TRAINSET = trainset.$(EXAMPLES)-$(FEATURES).vw.gz

TSFORMAT = +%Y-%m-%d %H:%M:%S

VW = ~/bin/vw
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
	echo === benchmarking $(VWVER) ...
	TS="$$(date "$(TSFORMAT)")"
	ELAPSED="$$(bin/elapsed-time $(VWCMD) 2>/dev/tty)"
	printf "%s\t%s\t%s\n" "$$TS" "$$ELAPSED" "$(VWCMD)" >> $(LOGFILE)

bench-all timeall:
	for vwexe in $$(echo ~/bin/vw-8.20*); do
		$(MAKE) VW="$$vwexe" timeone
	done

chart:
	bin/vwver-boxplot.R

clean:
	rm *.cache
