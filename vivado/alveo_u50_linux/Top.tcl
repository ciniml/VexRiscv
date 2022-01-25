
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
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:hbm:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:system_ila:1.1\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:util_vector_logic:2.0\
VexRiscv:VexRiscv:vexriscv:1.0\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:xdma:4.1\
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
  set cmc_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 cmc_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $cmc_clk

  set hbm_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 hbm_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $hbm_clk

  set pci_express_x16 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x16 ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]


  # Create ports
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_perstn

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
   CONFIG.M06_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {6} \
   CONFIG.NUM_SI {1} \
 ] $axi_interconnect_dbus

  # Create instance: axi_interconnect_hbm, and set properties
  set axi_interconnect_hbm [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_hbm ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {3} \
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
 ] $axi_interconnect_xdma

  # Create instance: axi_uart16550_cpu, and set properties
  set axi_uart16550_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_cpu ]
  set_property -dict [ list \
   CONFIG.C_S_AXI_ACLK_FREQ_HZ {250000000} \
 ] $axi_uart16550_cpu

  # Create instance: axi_uart16550_host, and set properties
  set axi_uart16550_host [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_host ]
  set_property -dict [ list \
   CONFIG.C_S_AXI_ACLK_FREQ_HZ {250000000} \
 ] $axi_uart16550_host

  # Create instance: clk_wiz_cmc, and set properties
  set clk_wiz_cmc [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_cmc ]
  set_property -dict [ list \
   CONFIG.CLK_IN1_BOARD_INTERFACE {cmc_clk} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_cmc

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
  
  # Create instance: hbm_0, and set properties
  set hbm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:hbm:1.0 hbm_0 ]
  set_property -dict [ list \
   CONFIG.USER_APB_EN {false} \
   CONFIG.USER_CLK_SEL_LIST0 {AXI_00_ACLK} \
   CONFIG.USER_SAXI_01 {false} \
   CONFIG.USER_SAXI_02 {false} \
   CONFIG.USER_SAXI_03 {false} \
   CONFIG.USER_SAXI_04 {false} \
   CONFIG.USER_SAXI_05 {false} \
   CONFIG.USER_SAXI_06 {false} \
   CONFIG.USER_SAXI_07 {false} \
   CONFIG.USER_SAXI_08 {false} \
   CONFIG.USER_SAXI_09 {false} \
   CONFIG.USER_SAXI_10 {false} \
   CONFIG.USER_SAXI_11 {false} \
   CONFIG.USER_SAXI_12 {false} \
   CONFIG.USER_SAXI_13 {false} \
   CONFIG.USER_SAXI_14 {false} \
   CONFIG.USER_SAXI_15 {false} \
 ] $hbm_0

  # Create instance: proc_sys_reset_apb, and set properties
  set proc_sys_reset_apb [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_apb ]

  # Create instance: proc_sys_reset_cpu, and set properties
  set proc_sys_reset_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_cpu ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {1} \
 ] $proc_sys_reset_cpu

  # Create instance: system_ila_cpu, and set properties
  set system_ila_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_cpu ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {0.5} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_MON_TYPE {MIX} \
   CONFIG.C_NUM_MONITOR_SLOTS {4} \
   CONFIG.C_NUM_OF_PROBES {13} \
   CONFIG.C_PROBE0_TYPE {0} \
   CONFIG.C_PROBE10_TYPE {0} \
   CONFIG.C_PROBE11_TYPE {0} \
   CONFIG.C_PROBE12_TYPE {0} \
   CONFIG.C_PROBE1_TYPE {0} \
   CONFIG.C_PROBE2_TYPE {0} \
   CONFIG.C_PROBE3_TYPE {0} \
   CONFIG.C_PROBE7_TYPE {0} \
   CONFIG.C_PROBE8_TYPE {0} \
   CONFIG.C_PROBE9_TYPE {0} \
   CONFIG.C_SLOT_0_APC_EN {0} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_1_APC_EN {0} \
   CONFIG.C_SLOT_1_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_2_APC_EN {0} \
   CONFIG.C_SLOT_2_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_AXI_AW_SEL {0} \
   CONFIG.C_SLOT_2_AXI_AW_SEL_DATA {0} \
   CONFIG.C_SLOT_2_AXI_AW_SEL_TRIG {0} \
   CONFIG.C_SLOT_2_AXI_B_SEL {0} \
   CONFIG.C_SLOT_2_AXI_B_SEL_DATA {0} \
   CONFIG.C_SLOT_2_AXI_B_SEL_TRIG {0} \
   CONFIG.C_SLOT_2_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_2_AXI_W_SEL {0} \
   CONFIG.C_SLOT_2_AXI_W_SEL_DATA {0} \
   CONFIG.C_SLOT_2_AXI_W_SEL_TRIG {0} \
   CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_3_APC_EN {0} \
   CONFIG.C_SLOT_3_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_3_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_3_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_3_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_3_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_3_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_3_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_3_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_3_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_3_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
 ] $system_ila_cpu

  # Create instance: util_ds_buf_hbm_refclk, and set properties
  set util_ds_buf_hbm_refclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_hbm_refclk ]
  set_property -dict [ list \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {hbm_clk} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $util_ds_buf_hbm_refclk

  # Create instance: util_ds_buf_pcie, and set properties
  set util_ds_buf_pcie [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_pcie ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
   CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk} \
 ] $util_ds_buf_pcie

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

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0 ]
  set_property -dict [ list \
   CONFIG.PCIE_BOARD_INTERFACE {pci_express_x16} \
   CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn} \
   CONFIG.axil_master_64bit_en {true} \
   CONFIG.axilite_master_en {true} \
   CONFIG.cfg_ext_if {false} \
   CONFIG.cfg_mgmt_if {false} \
   CONFIG.pf0_class_code {070002} \
   CONFIG.pf0_class_code_interface {02} \
   CONFIG.pf0_msi_enabled {false} \
   CONFIG.pf0_msix_cap_pba_bir {BAR_3:2} \
   CONFIG.pf0_msix_cap_table_bir {BAR_3:2} \
   CONFIG.pf0_sub_class_interface_menu {16550_compatible_serial_controller} \
   CONFIG.xdma_pcie_64bit_en {true} \
 ] $xdma_0

  # Create instance: xlconstant_cpu_interrupt, and set properties
  set xlconstant_cpu_interrupt [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_cpu_interrupt ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_cpu_interrupt

  # Create instance: xlconstant_uart_freeze, and set properties
  set xlconstant_uart_freeze [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_uart_freeze ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_uart_freeze

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins util_ds_buf_pcie/CLK_IN_D]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M00_AXI [get_bd_intf_pins axi_interconnect_dbus/M00_AXI] [get_bd_intf_pins axi_interconnect_hbm/S02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M01_AXI [get_bd_intf_pins axi_gpio_vled/S_AXI] [get_bd_intf_pins axi_interconnect_dbus/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M02_AXI [get_bd_intf_pins aclint_cpu/s_axi_timer] [get_bd_intf_pins axi_interconnect_dbus/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M03_AXI [get_bd_intf_pins axi_interconnect_dbus/M03_AXI] [get_bd_intf_pins axi_uart16550_cpu/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M04_AXI [get_bd_intf_pins axi_intc_platform/s_axi] [get_bd_intf_pins axi_interconnect_dbus/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M05_AXI [get_bd_intf_pins aclint_cpu/s_axi_ipi] [get_bd_intf_pins axi_interconnect_dbus/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_hbm_M00_AXI [get_bd_intf_pins axi_interconnect_hbm/M00_AXI] [get_bd_intf_pins hbm_0/SAXI_00]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M00_AXI [get_bd_intf_pins axi_interconnect_xdma/M00_AXI] [get_bd_intf_pins axi_uart16550_host/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M01_AXI [get_bd_intf_pins axi_gpio_jtag/S_AXI] [get_bd_intf_pins axi_interconnect_xdma/M01_AXI]
  connect_bd_intf_net -intf_net cmc_clk_1 [get_bd_intf_ports cmc_clk] [get_bd_intf_pins clk_wiz_cmc/CLK_IN1_D]
  connect_bd_intf_net -intf_net cpu_dBusAxi [get_bd_intf_pins axi_interconnect_dbus/S00_AXI] [get_bd_intf_pins vexriscv_inst/dBusAxi]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpu_dBusAxi] [get_bd_intf_pins axi_interconnect_dbus/S00_AXI] [get_bd_intf_pins system_ila_cpu/SLOT_1_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpu_dBusAxi]
  connect_bd_intf_net -intf_net cpu_iBusAxi [get_bd_intf_pins axi_interconnect_hbm/S01_AXI] [get_bd_intf_pins vexriscv_inst/iBusAxi]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpu_iBusAxi] [get_bd_intf_pins axi_interconnect_hbm/S01_AXI] [get_bd_intf_pins system_ila_cpu/SLOT_2_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpu_iBusAxi]
  connect_bd_intf_net -intf_net hbm_clk_1 [get_bd_intf_ports hbm_clk] [get_bd_intf_pins util_ds_buf_hbm_refclk/CLK_IN_D]
  connect_bd_intf_net -intf_net xdma_0_M_AXI [get_bd_intf_pins axi_interconnect_hbm/S00_AXI] [get_bd_intf_pins xdma_0/M_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets xdma_0_M_AXI] [get_bd_intf_pins system_ila_cpu/SLOT_0_AXI] [get_bd_intf_pins xdma_0/M_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets xdma_0_M_AXI]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pci_express_x16] [get_bd_intf_pins xdma_0/pcie_mgt]
  connect_bd_intf_net -intf_net xdma_M_AXI_LITE [get_bd_intf_pins axi_interconnect_xdma/S00_AXI] [get_bd_intf_pins xdma_0/M_AXI_LITE]
connect_bd_intf_net -intf_net [get_bd_intf_nets xdma_M_AXI_LITE] [get_bd_intf_pins system_ila_cpu/SLOT_3_AXI] [get_bd_intf_pins xdma_0/M_AXI_LITE]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets xdma_M_AXI_LITE]

  # Create port connections
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins axi_interconnect_hbm/S02_ARESETN] [get_bd_pins axi_uart16550_cpu/s_axi_aresetn] [get_bd_pins proc_sys_reset_cpu/peripheral_aresetn]
  connect_bd_net -net VexRiscv_inst_jtag_tdo [get_bd_pins gpio_jtag_inst/tdo] [get_bd_pins system_ila_cpu/probe3] [get_bd_pins vexriscv_inst/jtag_tdo]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets VexRiscv_inst_jtag_tdo]
  connect_bd_net -net aclint_cpu_timer_interrupt_out [get_bd_pins aclint_cpu/timer_interrupt_out] [get_bd_pins system_ila_cpu/probe12] [get_bd_pins vexriscv_inst/timerInterrupt]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets aclint_cpu_timer_interrupt_out]
  connect_bd_net -net axi_gpio_jtag_gpio2_io_o [get_bd_pins axi_gpio_jtag/gpio2_io_o] [get_bd_pins system_ila_cpu/probe8] [get_bd_pins util_vector_logic_cpu_reset/Op1]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_gpio_jtag_gpio2_io_o]
  connect_bd_net -net axi_gpio_jtag_gpio_io_o [get_bd_pins axi_gpio_jtag/gpio_io_o] [get_bd_pins gpio_jtag_inst/gpio_o] [get_bd_pins system_ila_cpu/probe2]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_gpio_jtag_gpio_io_o]
  connect_bd_net -net axi_gpio_vled_gpio_io_o [get_bd_pins axi_gpio_vled/gpio_io_o] [get_bd_pins vio_vled/probe_in0]
  connect_bd_net -net axi_intc_platform_irq [get_bd_pins axi_intc_platform/irq] [get_bd_pins vexriscv_inst/externalInterrupt]
  connect_bd_net -net axi_uart16550_cpu_sout [get_bd_pins axi_uart16550_cpu/sout] [get_bd_pins axi_uart16550_host/sin] [get_bd_pins system_ila_cpu/probe9]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_uart16550_cpu_sout]
  connect_bd_net -net axi_uart16550_host_sout [get_bd_pins axi_uart16550_cpu/sin] [get_bd_pins axi_uart16550_host/sout] [get_bd_pins system_ila_cpu/probe11]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_uart16550_host_sout]
  connect_bd_net -net clk_wiz_cmc_clk_out1 [get_bd_pins clk_wiz_cmc/clk_out1] [get_bd_pins hbm_0/APB_0_PCLK] [get_bd_pins proc_sys_reset_apb/slowest_sync_clk]
  connect_bd_net -net clk_wiz_cmc_locked [get_bd_pins clk_wiz_cmc/locked] [get_bd_pins proc_sys_reset_apb/dcm_locked]
  connect_bd_net -net debug_resetOut [get_bd_pins proc_sys_reset_cpu/aux_reset_in] [get_bd_pins system_ila_cpu/probe1] [get_bd_pins vexriscv_inst/debug_resetOut]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets debug_resetOut]
  connect_bd_net -net gpio_jtag_0_gpio_i [get_bd_pins axi_gpio_jtag/gpio_io_i] [get_bd_pins gpio_jtag_inst/gpio_i] [get_bd_pins system_ila_cpu/probe7]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_gpio_i]
  connect_bd_net -net gpio_jtag_0_tck [get_bd_pins gpio_jtag_inst/tck] [get_bd_pins system_ila_cpu/probe6] [get_bd_pins vexriscv_inst/jtag_tck]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_tck]
  connect_bd_net -net gpio_jtag_0_tdi [get_bd_pins gpio_jtag_inst/tdi] [get_bd_pins system_ila_cpu/probe4] [get_bd_pins vexriscv_inst/jtag_tdi]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_tdi]
  connect_bd_net -net gpio_jtag_0_tms [get_bd_pins gpio_jtag_inst/tms] [get_bd_pins system_ila_cpu/probe5] [get_bd_pins vexriscv_inst/jtag_tms]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets gpio_jtag_0_tms]
  connect_bd_net -net iBusAxi [get_bd_pins aclint_cpu/s_axi_ipi_aclk] [get_bd_pins aclint_cpu/s_axi_timer_aclk] [get_bd_pins axi_gpio_jtag/s_axi_aclk] [get_bd_pins axi_gpio_vled/s_axi_aclk] [get_bd_pins axi_intc_platform/s_axi_aclk] [get_bd_pins axi_interconnect_dbus/ACLK] [get_bd_pins axi_interconnect_dbus/M00_ACLK] [get_bd_pins axi_interconnect_dbus/M01_ACLK] [get_bd_pins axi_interconnect_dbus/M02_ACLK] [get_bd_pins axi_interconnect_dbus/M03_ACLK] [get_bd_pins axi_interconnect_dbus/M04_ACLK] [get_bd_pins axi_interconnect_dbus/M05_ACLK] [get_bd_pins axi_interconnect_dbus/S00_ACLK] [get_bd_pins axi_interconnect_hbm/ACLK] [get_bd_pins axi_interconnect_hbm/M00_ACLK] [get_bd_pins axi_interconnect_hbm/S00_ACLK] [get_bd_pins axi_interconnect_hbm/S01_ACLK] [get_bd_pins axi_interconnect_hbm/S02_ACLK] [get_bd_pins axi_interconnect_xdma/ACLK] [get_bd_pins axi_interconnect_xdma/M00_ACLK] [get_bd_pins axi_interconnect_xdma/M01_ACLK] [get_bd_pins axi_interconnect_xdma/S00_ACLK] [get_bd_pins axi_uart16550_cpu/s_axi_aclk] [get_bd_pins axi_uart16550_host/s_axi_aclk] [get_bd_pins hbm_0/AXI_00_ACLK] [get_bd_pins proc_sys_reset_cpu/slowest_sync_clk] [get_bd_pins system_ila_cpu/clk] [get_bd_pins vexriscv_inst/clk] [get_bd_pins vio_vled/clk] [get_bd_pins xdma_0/axi_aclk]
  connect_bd_net -net pcie_perstn_1 [get_bd_ports pcie_perstn] [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net proc_sys_reset_apb_peripheral_aresetn [get_bd_pins hbm_0/APB_0_PRESET_N] [get_bd_pins proc_sys_reset_apb/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_cpu_interconnect_aresetn [get_bd_pins axi_interconnect_dbus/ARESETN] [get_bd_pins axi_interconnect_hbm/ARESETN] [get_bd_pins axi_interconnect_hbm/M00_ARESETN] [get_bd_pins axi_interconnect_xdma/ARESETN] [get_bd_pins proc_sys_reset_cpu/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_cpu_mb_reset [get_bd_pins proc_sys_reset_cpu/mb_reset] [get_bd_pins util_vector_logic_cpu_reset/Op2]
  connect_bd_net -net util_ds_buf_0_IBUF_DS_ODIV2 [get_bd_pins util_ds_buf_pcie/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins hbm_0/HBM_REF_CLK_0] [get_bd_pins util_ds_buf_hbm_refclk/IBUF_OUT]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT1 [get_bd_pins util_ds_buf_pcie/IBUF_OUT] [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_vector_logic_cpu_reset_Res [get_bd_pins system_ila_cpu/probe10] [get_bd_pins util_vector_logic_cpu_reset/Res] [get_bd_pins vexriscv_inst/reset]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets util_vector_logic_cpu_reset_Res]
  connect_bd_net -net util_vector_logic_debugReset_Res [get_bd_pins util_vector_logic_debugReset/Res] [get_bd_pins vexriscv_inst/debugReset]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_pins aclint_cpu/s_axi_ipi_aresetn] [get_bd_pins aclint_cpu/s_axi_timer_aresetn] [get_bd_pins axi_gpio_jtag/s_axi_aresetn] [get_bd_pins axi_gpio_vled/s_axi_aresetn] [get_bd_pins axi_intc_platform/s_axi_aresetn] [get_bd_pins axi_interconnect_dbus/M00_ARESETN] [get_bd_pins axi_interconnect_dbus/M01_ARESETN] [get_bd_pins axi_interconnect_dbus/M02_ARESETN] [get_bd_pins axi_interconnect_dbus/M03_ARESETN] [get_bd_pins axi_interconnect_dbus/M04_ARESETN] [get_bd_pins axi_interconnect_dbus/M05_ARESETN] [get_bd_pins axi_interconnect_dbus/S00_ARESETN] [get_bd_pins axi_interconnect_hbm/S00_ARESETN] [get_bd_pins axi_interconnect_hbm/S01_ARESETN] [get_bd_pins axi_interconnect_xdma/M00_ARESETN] [get_bd_pins axi_interconnect_xdma/M01_ARESETN] [get_bd_pins axi_interconnect_xdma/S00_ARESETN] [get_bd_pins axi_uart16550_host/s_axi_aresetn] [get_bd_pins hbm_0/AXI_00_ARESET_N] [get_bd_pins proc_sys_reset_apb/ext_reset_in] [get_bd_pins proc_sys_reset_cpu/ext_reset_in] [get_bd_pins system_ila_cpu/resetn] [get_bd_pins util_vector_logic_debugReset/Op1] [get_bd_pins xdma_0/axi_aresetn]
  connect_bd_net -net xlconstant_cpu_interrupt_dout [get_bd_pins axi_intc_platform/intr] [get_bd_pins vexriscv_inst/externalInterruptS] [get_bd_pins vexriscv_inst/softwareInterrupt] [get_bd_pins xlconstant_cpu_interrupt/dout]
  connect_bd_net -net xlconstant_uart_freeze_dout [get_bd_pins axi_uart16550_cpu/freeze] [get_bd_pins axi_uart16550_host/freeze] [get_bd_pins xlconstant_uart_freeze/dout]

  # Create address segments
  assign_bd_address -offset 0x40022000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs aclint_cpu/s_axi_ipi/reg0] -force
  assign_bd_address -offset 0x40020000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs aclint_cpu/s_axi_timer/reg0] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_gpio_vled/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_intc_platform/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_uart16550_cpu/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM01] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM01] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM02] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM02] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM03] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM03] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM04] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM04] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM05] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM05] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM06] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM06] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs axi_gpio_jtag/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs axi_uart16550_host/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM01] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM02] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM03] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM04] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM05] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM06] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x70000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM07]
  exclude_bd_addr_seg -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM08]
  exclude_bd_addr_seg -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM09]
  exclude_bd_addr_seg -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM10]
  exclude_bd_addr_seg -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM11]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM12]
  exclude_bd_addr_seg -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM13]
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM14]
  exclude_bd_addr_seg -offset 0xF0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM15]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


