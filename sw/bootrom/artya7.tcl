# adapter driver ftdi
# ftdi device_desc "Dual RS232"
# ftdi vid_pid 0x0403 0x6010
# # channel 1 does not have any functionality
# ftdi channel 0
# # just TCK TDI TDO TMS, no reset
# ftdi layout_init 0x0014 0x001b
# reset_config none
adapter speed 10000

source [find interface/raspberrypi-native.cfg]
#source [find cpld/xilinx-xc7.cfg]
#source [find cpld/jtagspi.cfg]

set  _ENDIAN little
set _TAP_TYPE 1234

if { [info exists CPUTAPID] } {
   set _CPUTAPID $CPUTAPID
} else {
  # set useful default
   set _CPUTAPID 0x10001fff 
}

set VEXRISCV_YAML {../../cpu0.yaml}

set _CHIPNAME fpga_spinal
#jtag newtap xilinx bridge -expected-id 0x13631093 -irlen 6 -ircapture 0x1 -irmask 0xF 
jtag newtap $_CHIPNAME bridge -expected-id $_CPUTAPID -irlen 4 -ircapture 0x1 -irmask 0xF 

target create $_CHIPNAME.cpu0 vexriscv -endian $_ENDIAN -chain-position $_CHIPNAME.bridge -coreid 0 -dbgbase 0xF00F0000
vexriscv readWaitCycles 12
vexriscv cpuConfigFile $VEXRISCV_YAML
# vexriscv networkProtocol iverilog

poll_period 50

init
reset halt