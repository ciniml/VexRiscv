target extended-remote localhost:3333
add-symbol-file ~/vexriscv/buildroot-2021.11/output/build/linux-5.15/vmlinux
add-symbol-file ~/vexriscv/opensbi/build/platform/vexriscv_litefury/firmware/fw_jump.elf
display/i $pc