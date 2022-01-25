.PHONY: all clean ip

all: ip

clean: 
	-@$(RM) component.xml
	-@$(RM) -rf xgui

ip: component.xml

../../VexRiscv.v:
	cd ../..; sbt "runMain vexriscv.demo.LinuxGen"

component.xml xgui: ../../VexRiscv.v package_ip.tcl
	vivado -mode batch -source package_ip.tcl
