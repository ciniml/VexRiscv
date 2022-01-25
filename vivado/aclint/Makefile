.PHONY: all clean ip

RTL_DIR := ../../rtl/verilog
MODULES := $(wildcard *.sv)

all: ip

clean: 
	-@$(RM) component.xml
	-@$(RM) -rf xgui

ip: component.xml

component.xml xgui: $(MODULES) package_ip.tcl
	vivado -mode batch -source package_ip.tcl
