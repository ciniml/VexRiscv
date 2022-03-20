.PHONY: all clean restore device-tree open

PROJECT_NAME := litefury_linux
PROJECT_DIR := project
BD_NAME := Top
BITSTREAM := $(PROJECT_DIR)/$(PROJECT_NAME).runs/impl_1/$(BD_NAME)_wrapper.bit
VIVADO ?= vivado

all: $(BITSTREAM)

restore: $(PROJECT_DIR)/$(PROJECT_NAME).xpr

kernel: kernel/vexriscv_vitis.xo

clean:
	-@$(RM) -rf $(PROJECT_dir) .Xil NA kernel.tmp kernel
	-@$(RM) *.jou *.str *.btree *.log

open: $(PROJECT_DIR)/$(PROJECT_NAME).xpr
	$(VIVADO) $<&

$(PROJECT_DIR)/$(PROJECT_NAME).xpr: ../aclint/component.xml ../vexriscv/component.xml
	$(VIVADO) -mode batch -source restore_project.tcl -tclargs $(PROJECT_NAME)

# Generate RTL kernel package
kernel.tmp/vexriscv_vitis.xo: $(PROJECT_DIR)/$(PROJECT_NAME).xpr package_kernel.tcl
	-$(RM) -r kernel.tmp
	mkdir -p kernel.tmp
	$(VIVADO) -mode batch -source package_kernel.tcl -tclargs $(PROJECT_NAME) $(BD_NAME) $(abspath $@)

# Fix RTL kernel definition in the generated package.
kernel/vexriscv_vitis.xo: kernel.tmp/vexriscv_vitis.xo
	rm $@
	mkdir -p kernel.tmp/work && cd kernel.tmp/work && unzip $(abspath $<) && python3 $(abspath fix_kernel_port.py) vexriscv/kernel.xml && zip -ur $(abspath $@) *
	$(RM) -r kernel.tmp/work

# $(BITSTREAM): $(PROJECT_DIR)/$(PROJECT_NAME).xpr $(SRCS) $(PROJECT_DIR)/$(PROJECT_NAME).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
# 	$(VIVADO) -mode batch -source implement.tcl -tclargs $(PROJECT_NAME) $(BD_NAME)
