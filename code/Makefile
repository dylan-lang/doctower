all: doctower

REGISTRY = $(abspath registry)

.PHONY: all

doctower:
	OPEN_DYLAN_USER_REGISTRIES=$(REGISTRY):$(OPEN_DYLAN_USER_REGISTRIES) \
	 dylan-compiler -build doctower-library
	cp $(OPEN_DYLAN_USER_ROOT)/bin/doctower .
