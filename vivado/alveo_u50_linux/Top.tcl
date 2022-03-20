
################################################################
# This is a generated script based on design: Top
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2021.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source Top_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# gpio_jtag

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu50-fsvh2104-2-e
   set_property BOARD_PART xilinx.com:au50dd:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name Top

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
vendor:VexRiscv:aclint:1.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:axi_uart16550:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:system_cache:5.0\
xilinx.com:ip:util_vector_logic:2.0\
VexRiscv:VexRiscv:vexriscv:1.0\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
gpio_jtag\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set m_axi_mem [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mem ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $m_axi_mem

  set s_axi_control [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {16} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi_control


  # Create ports
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set clock [ create_bd_port -dir I -type clk -freq_hz 300000000 clock ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {m_axi_mem:s_axi_control} \
   CONFIG.ASSOCIATED_RESET {aresetn} \
 ] $clock

  # Create instance: aclint_cpu, and set properties
  set aclint_cpu [ create_bd_cell -type ip -vlnv vendor:VexRiscv:aclint:1.0 aclint_cpu ]

  # Create instance: axi_gpio_jtag, and set properties
  set axi_gpio_jtag [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_jtag ]
  set_property -dict [ list \
   CONFIG.C_GPIO2_WIDTH {1} \
   CONFIG.C_GPIO_WIDTH {4} \
   CONFIG.C_IS_DUAL {1} \
   CONFIG.C_TRI_DEFAULT {0xFFFFFFF8} \
   CONFIG.C_TRI_DEFAULT_2 {0xFFFFFFFe} \
 ] $axi_gpio_jtag

  # Create instance: axi_gpio_vled, and set properties
  set axi_gpio_vled [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_vled ]
  set_property -dict [ list \
   CONFIG.C_GPIO_WIDTH {8} \
   CONFIG.C_TRI_DEFAULT {0xFFFFFFF0} \
 ] $axi_gpio_vled

  # Create instance: axi_intc_platform, and set properties
  set axi_intc_platform [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_platform ]
  set_property -dict [ list \
   CONFIG.C_HAS_ILR {1} \
   CONFIG.C_NUM_SW_INTR {0} \
 ] $axi_intc_platform

  # Create instance: axi_interconnect_dbus, and set properties
  set axi_interconnect_dbus [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_dbus ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.M03_HAS_REGSLICE {4} \
   CONFIG.M04_HAS_REGSLICE {4} \
   CONFIG.M05_HAS_REGSLICE {4} \
   CONFIG.M06_HAS_REGSLICE {0} \
   CONFIG.NUM_MI {7} \
   CONFIG.NUM_SI {1} \
 ] $axi_interconnect_dbus

  # Create instance: axi_interconnect_hbm, and set properties
  set axi_interconnect_hbm [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_hbm ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_HAS_REGSLICE {4} \
   CONFIG.S01_HAS_REGSLICE {4} \
   CONFIG.S02_HAS_REGSLICE {4} \
 ] $axi_interconnect_hbm

  # Create instance: axi_interconnect_xdma, and set properties
  set axi_interconnect_xdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_xdma ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {2} \
   CONFIG.S00_HAS_REGSLICE {4} \
 ] $axi_interconnect_xdma

  # Create instance: axi_uart16550_cpu, and set properties
  set axi_uart16550_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_cpu ]
  set_property -dict [ list \
   CONFIG.C_S_AXI_ACLK_FREQ_HZ {300000000} \
 ] $axi_uart16550_cpu

  # Create instance: axi_uart16550_host, and set properties
  set axi_uart16550_host [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_host ]
  set_property -dict [ list \
   CONFIG.C_S_AXI_ACLK_FREQ_HZ {300000000} \
 ] $axi_uart16550_host

  # Create instance: gpio_jtag_inst, and set properties
  set block_name gpio_jtag
  set block_cell_name gpio_jtag_inst
  if { [catch {set gpio_jtag_inst [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $gpio_jtag_inst eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: proc_sys_reset_cpu, and set properties
  set proc_sys_reset_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_cpu ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {1} \
 ] $proc_sys_reset_cpu

  # Create instance: system_cache_dbus, and set properties
  set system_cache_dbus [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_cache:5.0 system_cache_dbus ]
  set_property -dict [ list \
   CONFIG.C_CACHE_DATA_WIDTH {512} \
   CONFIG.C_CACHE_SIZE {524288} \
   CONFIG.C_ENABLE_CTRL {1} \
   CONFIG.C_ENABLE_MASTER_COHERENCY {0} \
   CONFIG.C_ENABLE_SLAVE_COHERENCY {0} \
   CONFIG.C_ENABLE_VERSION_REGISTER {1} \
   CONFIG.C_M0_AXI_DATA_WIDTH {512} \
 ] $system_cache_dbus

  # Create instance: util_vector_logic_cpu_reset, and set properties
  set util_vector_logic_cpu_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_cpu_reset ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_cpu_reset

  # Create instance: util_vector_logic_debugReset, and set properties
  set util_vector_logic_debugReset [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_debugReset ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_debugReset

  # Create instance: vexriscv_inst, and set properties
  set vexriscv_inst [ create_bd_cell -type ip -vlnv VexRiscv:VexRiscv:vexriscv:1.0 vexriscv_inst ]

  # Create instance: vio_vled, and set properties
  set vio_vled [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_vled ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_OUT {0} \
 ] $vio_vled

  # Create instance: xlconstant_cpu_interrupt, and set properties
  set xlconstant_cpu_interrupt [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_cpu_interrupt ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_cpu_interrupt

  # Create instance: xlconstant_dbus_arcache, and set properties
  set xlconstant_dbus_arcache [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_dbus_arcache ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0b0111} \
   CONFIG.CONST_WIDTH {4} \
 ] $xlconstant_dbus_arcache

  # Create instance: xlconstant_dbus_awcache, and set properties
  set xlconstant_dbus_awcache [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_dbus_awcache ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0b0111} \
   CONFIG.CONST_WIDTH {4} \
 ] $xlconstant_dbus_awcache

  # Create instance: xlconstant_uart_freeze, and set properties
  set xlconstant_uart_freeze [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_uart_freeze ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_uart_freeze

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M00_AXI [get_bd_intf_pins axi_interconnect_dbus/M00_AXI] [get_bd_intf_pins system_cache_dbus/S0_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M01_AXI [get_bd_intf_pins axi_gpio_vled/S_AXI] [get_bd_intf_pins axi_interconnect_dbus/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M02_AXI [get_bd_intf_pins aclint_cpu/s_axi_timer] [get_bd_intf_pins axi_interconnect_dbus/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M03_AXI [get_bd_intf_pins axi_interconnect_dbus/M03_AXI] [get_bd_intf_pins axi_uart16550_cpu/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M04_AXI [get_bd_intf_pins axi_intc_platform/s_axi] [get_bd_intf_pins axi_interconnect_dbus/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M05_AXI [get_bd_intf_pins aclint_cpu/s_axi_ipi] [get_bd_intf_pins axi_interconnect_dbus/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M06_AXI [get_bd_intf_pins axi_interconnect_dbus/M06_AXI] [get_bd_intf_pins system_cache_dbus/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_hbm_M00_AXI [get_bd_intf_ports m_axi_mem] [get_bd_intf_pins axi_interconnect_hbm/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M00_AXI [get_bd_intf_pins axi_interconnect_xdma/M00_AXI] [get_bd_intf_pins axi_uart16550_host/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M01_AXI [get_bd_intf_pins axi_gpio_jtag/S_AXI] [get_bd_intf_pins axi_interconnect_xdma/M01_AXI]
  connect_bd_intf_net -intf_net cpu_dBusAxi [get_bd_intf_pins axi_interconnect_dbus/S00_AXI] [get_bd_intf_pins vexriscv_inst/dBusAxi]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpu_dBusAxi]
  connect_bd_intf_net -intf_net cpu_iBusAxi [get_bd_intf_pins axi_interconnect_hbm/S01_AXI] [get_bd_intf_pins vexriscv_inst/iBusAxi]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpu_iBusAxi]
  connect_bd_intf_net -intf_net system_cache_0_M0_AXI [get_bd_intf_pins axi_interconnect_hbm/S00_AXI] [get_bd_intf_pins system_cache_dbus/M0_AXI]
  connect_bd_intf_net -intf_net xdma_M_AXI_LITE [get_bd_intf_ports s_axi_control] [get_bd_intf_pins axi_interconnect_xdma/S00_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets xdma_M_AXI_LITE]

  # Create port connections
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins axi_interconnect_hbm/M00_ARESETN] [get_bd_pins axi_uart16550_cpu/s_axi_aresetn] [get_bd_pins proc_sys_reset_cpu/peripheral_aresetn] [get_bd_pins system_cache_dbus/ARESETN]
  connect_bd_net -net VexRiscv_inst_jtag_tdo [get_bd_pins gpio_jtag_inst/tdo] [get_bd_pins vexriscv_inst/jtag_tdo]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets VexRiscv_inst_jtag_tdo]
  connect_bd_net -net aclint_cpu_timer_interrupt_out [get_bd_pins aclint_cpu/timer_interrupt_out] [get_bd_pins vexriscv_inst/timerInterrupt]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets aclint_cpu_timer_interrupt_out]
  connect_bd_net -net axi_gpio_jtag_gpio2_io_o [get_bd_pins axi_gpio_jtag/gpio2_io_o] [get_bd_pins util_vector_logic_cpu_reset/Op1]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_gpio_jtag_gpio2_io_o]
  connect_bd_net -net axi_gpio_jtag_gpio_io_o [get_bd_pins axi_gpio_jtag/gpio_io_o] [get_bd_pins gpio_jtag_inst/gpio_o]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_gpio_jtag_gpio_io_o]
  connect_bd_net -net axi_gpio_vled_gpio_io_o [get_bd_pins axi_gpio_vled/gpio_io_o] [get_bd_pins vio_vled/probe_in0]
  connect_bd_net -net axi_intc_platform_irq [get_bd_pins axi_intc_platform/irq] [get_bd_pins vexriscv_inst/externalInterrupt]
  connect_bd_net -net axi_uart16550_cpu_sout [get_bd_pins axi_uart16550_cpu/sout] [get_bd_pins axi_uart16550_host/sin]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_uart16550_cpu_sout]
  connect_bd_net -net axi_uart16550_host_sout [get_bd_pins axi_uart16550_cpu/sin] [get_bd_pins axi_uart16550_host/sout]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_uart16550_host_sout]
  connect_bd_net -net debug_resetOut [get_bd_pins proc_sys_reset_cpu/aux_reset_in] [get_bd_pins vexriscv_inst/debug_resetOut]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets debug_resetOut]
  connect_bd_net -net gpio_jtag_0_gpio_i [get_bd_pins axi_gpio_jtag/gpio_io_i] [get_bd_pins gpio_jtag_inst/gpio_i]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_gpio_i]
  connect_bd_net -net gpio_jtag_0_tck [get_bd_pins gpio_jtag_inst/tck] [get_bd_pins vexriscv_inst/jtag_tck]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_tck]
  connect_bd_net -net gpio_jtag_0_tdi [get_bd_pins gpio_jtag_inst/tdi] [get_bd_pins vexriscv_inst/jtag_tdi]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_tdi]
  connect_bd_net -net gpio_jtag_0_tms [get_bd_pins gpio_jtag_inst/tms] [get_bd_pins vexriscv_inst/jtag_tms]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_tms]
  connect_bd_net -net iBusAxi [get_bd_ports clock] [get_bd_pins aclint_cpu/s_axi_ipi_aclk] [get_bd_pins aclint_cpu/s_axi_timer_aclk] [get_bd_pins axi_gpio_jtag/s_axi_aclk] [get_bd_pins axi_gpio_vled/s_axi_aclk] [get_bd_pins axi_intc_platform/s_axi_aclk] [get_bd_pins axi_interconnect_dbus/ACLK] [get_bd_pins axi_interconnect_dbus/M00_ACLK] [get_bd_pins axi_interconnect_dbus/M01_ACLK] [get_bd_pins axi_interconnect_dbus/M02_ACLK] [get_bd_pins axi_interconnect_dbus/M03_ACLK] [get_bd_pins axi_interconnect_dbus/M04_ACLK] [get_bd_pins axi_interconnect_dbus/M05_ACLK] [get_bd_pins axi_interconnect_dbus/M06_ACLK] [get_bd_pins axi_interconnect_dbus/S00_ACLK] [get_bd_pins axi_interconnect_hbm/ACLK] [get_bd_pins axi_interconnect_hbm/M00_ACLK] [get_bd_pins axi_interconnect_hbm/S00_ACLK] [get_bd_pins axi_interconnect_hbm/S01_ACLK] [get_bd_pins axi_interconnect_xdma/ACLK] [get_bd_pins axi_interconnect_xdma/M00_ACLK] [get_bd_pins axi_interconnect_xdma/M01_ACLK] [get_bd_pins axi_interconnect_xdma/S00_ACLK] [get_bd_pins axi_uart16550_cpu/s_axi_aclk] [get_bd_pins axi_uart16550_host/s_axi_aclk] [get_bd_pins proc_sys_reset_cpu/slowest_sync_clk] [get_bd_pins system_cache_dbus/ACLK] [get_bd_pins vexriscv_inst/clk] [get_bd_pins vio_vled/clk]
  connect_bd_net -net proc_sys_reset_cpu_interconnect_aresetn [get_bd_pins axi_interconnect_dbus/ARESETN] [get_bd_pins axi_interconnect_hbm/ARESETN] [get_bd_pins proc_sys_reset_cpu/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_cpu_mb_reset [get_bd_pins proc_sys_reset_cpu/mb_reset] [get_bd_pins util_vector_logic_cpu_reset/Op2]
  connect_bd_net -net util_vector_logic_cpu_reset_Res [get_bd_pins util_vector_logic_cpu_reset/Res] [get_bd_pins vexriscv_inst/reset]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets util_vector_logic_cpu_reset_Res]
  connect_bd_net -net util_vector_logic_debugReset_Res [get_bd_pins util_vector_logic_debugReset/Res] [get_bd_pins vexriscv_inst/debugReset]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_ports aresetn] [get_bd_pins aclint_cpu/s_axi_ipi_aresetn] [get_bd_pins aclint_cpu/s_axi_timer_aresetn] [get_bd_pins axi_gpio_jtag/s_axi_aresetn] [get_bd_pins axi_gpio_vled/s_axi_aresetn] [get_bd_pins axi_intc_platform/s_axi_aresetn] [get_bd_pins axi_interconnect_dbus/M00_ARESETN] [get_bd_pins axi_interconnect_dbus/M01_ARESETN] [get_bd_pins axi_interconnect_dbus/M02_ARESETN] [get_bd_pins axi_interconnect_dbus/M03_ARESETN] [get_bd_pins axi_interconnect_dbus/M04_ARESETN] [get_bd_pins axi_interconnect_dbus/M05_ARESETN] [get_bd_pins axi_interconnect_dbus/M06_ARESETN] [get_bd_pins axi_interconnect_dbus/S00_ARESETN] [get_bd_pins axi_interconnect_hbm/S00_ARESETN] [get_bd_pins axi_interconnect_hbm/S01_ARESETN] [get_bd_pins axi_interconnect_xdma/ARESETN] [get_bd_pins axi_interconnect_xdma/M00_ARESETN] [get_bd_pins axi_interconnect_xdma/M01_ARESETN] [get_bd_pins axi_interconnect_xdma/S00_ARESETN] [get_bd_pins axi_uart16550_host/s_axi_aresetn] [get_bd_pins proc_sys_reset_cpu/ext_reset_in] [get_bd_pins util_vector_logic_debugReset/Op1]
  connect_bd_net -net xlconstant_cpu_interrupt_dout [get_bd_pins axi_intc_platform/intr] [get_bd_pins vexriscv_inst/externalInterruptS] [get_bd_pins vexriscv_inst/softwareInterrupt] [get_bd_pins xlconstant_cpu_interrupt/dout]
  connect_bd_net -net xlconstant_dbus_arcache_dout [get_bd_pins system_cache_dbus/S0_AXI_ARCACHE] [get_bd_pins xlconstant_dbus_arcache/dout]
  connect_bd_net -net xlconstant_dbus_awcache_dout [get_bd_pins system_cache_dbus/S0_AXI_AWCACHE] [get_bd_pins xlconstant_dbus_awcache/dout]
  connect_bd_net -net xlconstant_uart_freeze_dout [get_bd_pins axi_uart16550_cpu/freeze] [get_bd_pins axi_uart16550_host/freeze] [get_bd_pins xlconstant_uart_freeze/dout]

  # Create address segments
  assign_bd_address -offset 0x40022000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs aclint_cpu/s_axi_ipi/reg0] -force
  assign_bd_address -offset 0x40020000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs aclint_cpu/s_axi_timer/reg0] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_gpio_vled/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_intc_platform/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_uart16550_cpu/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs m_axi_mem/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs m_axi_mem/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00020000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs system_cache_dbus/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces s_axi_control] [get_bd_addr_segs axi_gpio_jtag/S_AXI/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces s_axi_control] [get_bd_addr_segs axi_uart16550_host/S_AXI/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

