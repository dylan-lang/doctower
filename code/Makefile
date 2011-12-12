all: doctower

SOURCES = \
	support-lib/support-library.lid \
	midsupport-lib/midsupport-library.lid \
	markup-parser-lib/markup-parser-library.lid \
	dylan-parser-lib/dylan-parser-library.lid \
	markup-rep-lib/markup-rep-library.lid \
	dylan-rep-lib/dylan-rep-library.lid \
	output-lib/output-library.lid \
	main-lib/doctower-library.lid

BASE_LIBDIR = ../..

LIBRARIES = \
	$(BASE_LIBDIR)/monday/lib/program-representation/source-location \
	$(BASE_LIBDIR)/skip-list \
	$(BASE_LIBDIR)/command-line-parser \
	$(BASE_LIBDIR)/dynamic-binding \
	$(BASE_LIBDIR)/slot-visitor \
	$(BASE_LIBDIR)/sequence-stream \
	$(BASE_LIBDIR)/wrapper-streams \
	$(BASE_LIBDIR)/peg-parser \
	$(BASE_LIBDIR)/template-engine

libraries = $(abspath $(LIBRARIES))
sources = $(abspath $(SOURCES))
libflags = $(addprefix -L,$(libraries)) $(addprefix -L,$(dir $(sources)))

.PHONY: all
.PHONY: clean
.PHONY: required-libs

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),required-libs)
-include $(SOURCES:.lid=.dep)
endif
endif

support-lib/support-library.lib.du : \
	support-lib/support-library.lid

midsupport-lib/midsupport-library.lib.du : \
	midsupport-lib/midsupport-library.lid

markup-parser-lib/markup-parser-library.lib.du : \
	markup-parser-lib/markup-parser-library.lid

dylan-parser-lib/dylan-parser-library.lib.du : \
	dylan-parser-lib/dylan-parser-library.lid

markup-rep-lib/markup-rep-library.lib.du : \
	markup-rep-lib/markup-rep-library.lid

dylan-rep-lib/dylan-rep-library.lib.du : \
	dylan-rep-lib/dylan-rep-library.lid

output-lib/output-library.lib.du : \
	output-lib/output-library.lid

main-lib/doctower-library.lib.du : \
	main-lib/doctower-library.lid

doctower : main-lib/doctower-library.lib.du
	cp main-lib/doctower doctower

%.dep %.lib.du : %.lid
	cd $(dir $<) ; d2c -gM $(libflags) $(notdir $<)
	@sed -i "~" -e "1s'.*:'$*.dep $*.lib.du:'" $*.dep

required-libs:
	cd $(BASE_LIBDIR)/monday/lib/program-representation/source-location ; \
	  rm *.a *.lib.du ; d2c source-location.lid
	cd $(BASE_LIBDIR)/skip-list ; \
	  make clean ; make
	cd $(BASE_LIBDIR)/command-line-parser ; \
	  rm *.a *.lib.du ; d2c command-line-parser.lid
	cd $(BASE_LIBDIR)/dynamic-binding ; \
	  make clean ; make
	cd $(BASE_LIBDIR)/slot-visitor ; \
	  make clean ; make
	cd $(BASE_LIBDIR)/sequence-stream ; \
	  make clean ; make
	cd $(BASE_LIBDIR)/wrapper-streams ; \
	  make clean ; make
	cd $(BASE_LIBDIR)/peg-parser ; \
	  make clean ; make
	cd $(BASE_LIBDIR)/template-engine ; \
	  make clean ; make

clean:
	-find . \( -name "doctower" -or \
		   -name "*.o" -or \
		   -name "*.s" -or \
		   -name "*.a" -or \
		   -name "*.c" -or \
		   -name "*.du" -or \
		   -name "*.el" -or \
		   -name "*.mak" -or \
		   -name "*.mak-temp" -or \
		   -name "*.dep" -or \
		   -name "*~" -or \
		   -name ".libs" \) \
		-delete
