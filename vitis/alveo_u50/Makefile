.PHONY: all clean

PROJECT_NAME = vexriscv_vitis
LINK_DIR = link
BINARY_CONTAINER = $(PROJECT_NAME).xclbin
BINARY_CONTAINER_PATH = $(LINK_DIR)/$(BINARY_CONTAINER)
KERNEL_DIR = ../../vivado/alveo_u50_linux
KERNEL = $(KERNEL_DIR)/kernel/vexriscv_vitis.xo
LINK_CONFIG = $(PROJECT_NAME)-link.cfg
IP_REPO_DIR = ../../vivado
ACLINT_REPO_DIR = $(IP_REPO_DIR)/aclint
VEXRISCV_REPO_DIR = $(IP_REPO_DIR)/vexriscv

all: $(BINARY_CONTAINER_PATH)

$(LINK_DIR):
	mkdir -p $(LINK_DIR)

$(BINARY_CONTAINER_PATH): $(LINK_DIR)
	cd $(LINK_DIR) && \
	${XILINX_VITIS}/bin/v++ \
		--target hw \
		--link \
		--user_ip_repo_paths $(abspath $(ACLINT_REPO_DIR))   \
		--user_ip_repo_paths $(abspath $(VEXRISCV_REPO_DIR)) \
		--config $(abspath $(LINK_CONFIG)) \
		-o"$(BINARY_CONTAINER)" $(abspath $(KERNEL))

clean:
	-@$(RM) -r $(LINK_DIR)