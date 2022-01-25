.PHONY: all clean transfer

BOOTROM_ADDRESS ?= 0x80000000
BOOTROM_BIN ?= ../../../sw/bootrom/bootrom.bin
DTB_ADDRESS ?= 0x83000000
SBI_ADDRESS ?= 0x80010000
SBI_BIN ?= ../../../../opensbi/build/platform/vexriscv_litefury/firmware/fw_jump.bin
LINUX_ADDRESS ?= 0x81000000
LINUX_IMAGE ?= ../../../../buildroot-2021.11/output/images/Image
ROOTFS_ADDRESS ?= 0x88000000
ROOTFS_IMAGE ?= ../../../../buildroot-2021.11/output/images/rootfs.cpio.gz

all: system-top.dtb.dump

system-top.dts.pp: system-top.dts pl.dtsi
	cpp -nostdinc -E  -x assembler-with-cpp $< > $@

system-top.dtb: system-top.dts.pp
	dtc $< -o $@

system-top.dtb.dump: system-top.dtb
	dtc -I dtb -O dts $< -o $@

transfer: system-top.dtb $(SBI_BIN) $(LINUX_IMAGE) $(ROOTFS_IMAGE) $(BOOTROM_BIN)
	sudo `which dma_to_device` -a $(BOOTROM_ADDRESS) -f $(BOOTROM_BIN) -s `stat -c %s $(BOOTROM_BIN)`
	sudo `which dma_to_device` -a $(DTB_ADDRESS) -f $< -s `stat -c %s $<`
	sudo `which dma_to_device` -a $(SBI_ADDRESS) -f $(SBI_BIN) -s `stat -c %s $(SBI_BIN)`
	sudo `which dma_to_device` -a $(LINUX_ADDRESS) -f $(LINUX_IMAGE) -s `stat -c %s $(LINUX_IMAGE)`
	stat -c %s $(ROOTFS_IMAGE)
	sudo `which dma_to_device` -a $(ROOTFS_ADDRESS) -f $(ROOTFS_IMAGE) -s `stat -c %s $(ROOTFS_IMAGE)`

clean:
	-@$(RM) system-top.dtb system-top.dtb.dump system-top.dts.pp
