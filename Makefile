I_D = draft-lhotka-netmod-yang-annotations
REVNO = 00
DATE ?= $(shell date +%F)
MODULES = ietf-yang-annotations
FIGURES =
PYANG_OPTS =

artworks = $(addsuffix .aw, $(yams))
idrev = $(I_D)-$(REVNO)
yams = $(addsuffix .yang, $(MODULES))
xsldir = .tools/xslt
xslpars = --stringparam date $(DATE) --stringparam i-d-name $(I_D) \
	  --stringparam i-d-rev $(REVNO)

.PHONY: all validate clean rnc refs

all: $(idrev).txt

$(idrev).xml: $(I_D).xml $(artworks) figures.ent yang.ent
	@xsltproc $(xslpars) $(xsldir)/upd-i-d.xsl $< | xmllint --noent -o $@ -

$(idrev).txt: $(idrev).xml
	@xml2rfc --dtd=.tools/schema/rfc2629.dtd $<

refs: yang.ent figures.ent $(artworks)
	xsltproc --output stdrefs.ent $(xsldir)/get-refs.xsl $(I_D).xml

yang.ent: $(yams)
	@echo '<!-- External entities for files with modules -->' > $@
	@for f in $^; do                                                 \
	  echo '<!ENTITY '"$$f SYSTEM \"$$f.aw\">" >> $@;          \
	done
ifneq ($EXAMPLE_INST,)
	@echo '<!ENTITY '"$(EXAMPLE_INST) SYSTEM \"$(EXAMPLE_INST).aw\">" >> $@
endif

figures.ent: $(FIGURES)
ifeq ($(FIGURES),)
	@touch $@
else
	@echo '<!-- External entities for files with figures -->' > $@; \
	for f in $^; do                                            \
	  echo '<!ENTITY '"$$f SYSTEM \"$$f.aw\">" >> $@;  \
	done
endif

%.yang: %.yinx
	@xsltproc --xinclude --output $@ $(xslpars) $(xsldir)/yin2yang.xsl $<

ietf-%.yang.aw: ietf-%.yang
	@pyang $(PYANG_OPTS) --ietf $<
	@echo '<artwork>' > $@
	@echo '<![CDATA[<CODE BEGINS> file '"\"$*@$(DATE).yang\"" >> $@
	@echo >> $@
	@cat $< >> $@
	@echo >> $@
	@echo '<CODE ENDS>]]></artwork>' >> $@

%.aw: %
	@echo '<artwork><![CDATA[' > $@; \
	cat $< >> $@;                    \
	echo ']]></artwork>' >> $@

clean:
	@rm -rf *.rng *.rnc *.sch *.dsrl hello.xml model.tree \
	        $(idrev).* $(artworks) figures.ent yang.ent
