export PYTHONPATH := $(GIT_ROOT)/utils:$(PYTHONPATH)

t1=> $@.tmp
t2=mv $@.tmp $@

d2=$(word 2,$^)
d3=$(word 3,$^)
d4=$(word 4,$^)

BIBLIOGRAPHY = $(GIT_ROOT)/references.bib
CSL_STYLE = $(GIT_ROOT)/ieee.csl
