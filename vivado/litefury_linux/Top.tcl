
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
   create_project project_1 myproj -part xc7a100tfgg484-2L
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
xilinx.com:ip:axi_quad_spi:3.2\
xilinx.com:ip:axi_uart16550:2.0\
xilinx.com:ip:mig_7series:4.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:system_ila:1.1\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:util_vector_logic:2.0\
VexRiscv:VexRiscv:vexriscv:1.0\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:xadc_wiz:3.3\
xilinx.com:ip:xdma:4.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:c_counter_binary:12.0\
xilinx.com:ip:xlslice:1.0\
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
# MIG PRJ FILE TCL PROCs
##################################################################

proc write_mig_file_Top_mig_7series_0_0 { str_mig_prj_filepath } {

   file mkdir [ file dirname "$str_mig_prj_filepath" ]
   set mig_prj_file [open $str_mig_prj_filepath  w+]

   puts $mig_prj_file {<?xml version='1.0' encoding='UTF-8'?>}
   puts $mig_prj_file {<!-- IMPORTANT: This is an internal file that has been generated by the MIG software. Any direct editing or changes made to this file may result in unpredictable behavior or data corruption. It is strongly advised that users do not edit the contents of this file. Re-run the MIG GUI with the required settings if any of the options provided below need to be altered. -->}
   puts $mig_prj_file {<Project NoOfControllers="1" >}
   puts $mig_prj_file {    <ModuleName>Top_mig_7series_0_0</ModuleName>}
   puts $mig_prj_file {    <dci_inouts_inputs>1</dci_inouts_inputs>}
   puts $mig_prj_file {    <dci_inputs>1</dci_inputs>}
   puts $mig_prj_file {    <Debug_En>OFF</Debug_En>}
   puts $mig_prj_file {    <DataDepth_En>1024</DataDepth_En>}
   puts $mig_prj_file {    <LowPower_En>ON</LowPower_En>}
   puts $mig_prj_file {    <XADC_En>Disabled</XADC_En>}
   puts $mig_prj_file {    <TargetFPGA>xc7a100t-fgg484/-2L</TargetFPGA>}
   puts $mig_prj_file {    <Version>4.1</Version>}
   puts $mig_prj_file {    <SystemClock>Differential</SystemClock>}
   puts $mig_prj_file {    <ReferenceClock>Use System Clock</ReferenceClock>}
   puts $mig_prj_file {    <SysResetPolarity>ACTIVE LOW</SysResetPolarity>}
   puts $mig_prj_file {    <BankSelectionFlag>FALSE</BankSelectionFlag>}
   puts $mig_prj_file {    <InternalVref>0</InternalVref>}
   puts $mig_prj_file {    <dci_hr_inouts_inputs>50 Ohms</dci_hr_inouts_inputs>}
   puts $mig_prj_file {    <dci_cascade>0</dci_cascade>}
   puts $mig_prj_file {    <Controller number="0" >}
   puts $mig_prj_file {        <MemoryDevice>DDR3_SDRAM/Components/MT41J256m16XX-125</MemoryDevice>}
   puts $mig_prj_file {        <TimePeriod>2500</TimePeriod>}
   puts $mig_prj_file {        <VccAuxIO>1.8V</VccAuxIO>}
   puts $mig_prj_file {        <PHYRatio>4:1</PHYRatio>}
   puts $mig_prj_file {        <InputClkFreq>200</InputClkFreq>}
   puts $mig_prj_file {        <UIExtraClocks>0</UIExtraClocks>}
   puts $mig_prj_file {        <MMCM_VCO>800</MMCM_VCO>}
   puts $mig_prj_file {        <MMCMClkOut0> 1.000</MMCMClkOut0>}
   puts $mig_prj_file {        <MMCMClkOut1>1</MMCMClkOut1>}
   puts $mig_prj_file {        <MMCMClkOut2>1</MMCMClkOut2>}
   puts $mig_prj_file {        <MMCMClkOut3>1</MMCMClkOut3>}
   puts $mig_prj_file {        <MMCMClkOut4>1</MMCMClkOut4>}
   puts $mig_prj_file {        <DataWidth>16</DataWidth>}
   puts $mig_prj_file {        <DeepMemory>1</DeepMemory>}
   puts $mig_prj_file {        <DataMask>1</DataMask>}
   puts $mig_prj_file {        <ECC>Disabled</ECC>}
   puts $mig_prj_file {        <Ordering>Strict</Ordering>}
   puts $mig_prj_file {        <BankMachineCnt>4</BankMachineCnt>}
   puts $mig_prj_file {        <CustomPart>FALSE</CustomPart>}
   puts $mig_prj_file {        <NewPartName></NewPartName>}
   puts $mig_prj_file {        <RowAddress>15</RowAddress>}
   puts $mig_prj_file {        <ColAddress>10</ColAddress>}
   puts $mig_prj_file {        <BankAddress>3</BankAddress>}
   puts $mig_prj_file {        <MemoryVoltage>1.5V</MemoryVoltage>}
   puts $mig_prj_file {        <C0_MEM_SIZE>536870912</C0_MEM_SIZE>}
   puts $mig_prj_file {        <UserMemoryAddressMap>BANK_ROW_COLUMN</UserMemoryAddressMap>}
   puts $mig_prj_file {        <PinSelection>}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="M15" SLEW="" name="ddr3_addr[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="J21" SLEW="" name="ddr3_addr[10]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="M22" SLEW="" name="ddr3_addr[11]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="K22" SLEW="" name="ddr3_addr[12]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="N18" SLEW="" name="ddr3_addr[13]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="N22" SLEW="" name="ddr3_addr[14]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="L21" SLEW="" name="ddr3_addr[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="M16" SLEW="" name="ddr3_addr[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="L18" SLEW="" name="ddr3_addr[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="K21" SLEW="" name="ddr3_addr[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="M18" SLEW="" name="ddr3_addr[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="M21" SLEW="" name="ddr3_addr[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="N20" SLEW="" name="ddr3_addr[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="M20" SLEW="" name="ddr3_addr[8]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="N19" SLEW="" name="ddr3_addr[9]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="L19" SLEW="" name="ddr3_ba[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="J20" SLEW="" name="ddr3_ba[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="L20" SLEW="" name="ddr3_ba[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="K18" SLEW="" name="ddr3_cas_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="DIFF_SSTL15" PADName="J17" SLEW="" name="ddr3_ck_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="DIFF_SSTL15" PADName="K17" SLEW="" name="ddr3_ck_p[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="H22" SLEW="" name="ddr3_cke[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="A19" SLEW="" name="ddr3_dm[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="G22" SLEW="" name="ddr3_dm[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="D19" SLEW="" name="ddr3_dq[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="D20" SLEW="" name="ddr3_dq[10]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="E21" SLEW="" name="ddr3_dq[11]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="C22" SLEW="" name="ddr3_dq[12]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="D21" SLEW="" name="ddr3_dq[13]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="B22" SLEW="" name="ddr3_dq[14]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="D22" SLEW="" name="ddr3_dq[15]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="B20" SLEW="" name="ddr3_dq[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="E19" SLEW="" name="ddr3_dq[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="A20" SLEW="" name="ddr3_dq[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="F19" SLEW="" name="ddr3_dq[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="C19" SLEW="" name="ddr3_dq[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="F20" SLEW="" name="ddr3_dq[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="C18" SLEW="" name="ddr3_dq[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="E22" SLEW="" name="ddr3_dq[8]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="G21" SLEW="" name="ddr3_dq[9]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="DIFF_SSTL15" PADName="E18" SLEW="" name="ddr3_dqs_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="DIFF_SSTL15" PADName="A21" SLEW="" name="ddr3_dqs_n[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="DIFF_SSTL15" PADName="F18" SLEW="" name="ddr3_dqs_p[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="DIFF_SSTL15" PADName="B21" SLEW="" name="ddr3_dqs_p[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="K19" SLEW="" name="ddr3_odt[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="H20" SLEW="" name="ddr3_ras_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="LVCMOS15" PADName="K16" SLEW="" name="ddr3_reset_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="" IOSTANDARD="SSTL15" PADName="L16" SLEW="" name="ddr3_we_n" IN_TERM="" />}
   puts $mig_prj_file {        </PinSelection>}
   puts $mig_prj_file {        <System_Clock>}
   puts $mig_prj_file {            <Pin PADName="J19/H19(CC_P/N)" Bank="15" name="sys_clk_p/n" />}
   puts $mig_prj_file {        </System_Clock>}
   puts $mig_prj_file {        <System_Control>}
   puts $mig_prj_file {            <Pin PADName="No connect" Bank="Select Bank" name="sys_rst" />}
   puts $mig_prj_file {            <Pin PADName="No connect" Bank="Select Bank" name="init_calib_complete" />}
   puts $mig_prj_file {            <Pin PADName="No connect" Bank="Select Bank" name="tg_compare_error" />}
   puts $mig_prj_file {        </System_Control>}
   puts $mig_prj_file {        <TimingParameters>}
   puts $mig_prj_file {            <Parameters twtr="7.5" trrd="7.5" trefi="7.8" tfaw="40" trtp="7.5" tcke="5" trfc="260" trp="13.75" tras="35" trcd="13.75" />}
   puts $mig_prj_file {        </TimingParameters>}
   puts $mig_prj_file {        <mrBurstLength name="Burst Length" >8 - Fixed</mrBurstLength>}
   puts $mig_prj_file {        <mrBurstType name="Read Burst Type and Length" >Sequential</mrBurstType>}
   puts $mig_prj_file {        <mrCasLatency name="CAS Latency" >6</mrCasLatency>}
   puts $mig_prj_file {        <mrMode name="Mode" >Normal</mrMode>}
   puts $mig_prj_file {        <mrDllReset name="DLL Reset" >No</mrDllReset>}
   puts $mig_prj_file {        <mrPdMode name="DLL control for precharge PD" >Slow Exit</mrPdMode>}
   puts $mig_prj_file {        <emrDllEnable name="DLL Enable" >Enable</emrDllEnable>}
   puts $mig_prj_file {        <emrOutputDriveStrength name="Output Driver Impedance Control" >RZQ/7</emrOutputDriveStrength>}
   puts $mig_prj_file {        <emrMirrorSelection name="Address Mirroring" >Disable</emrMirrorSelection>}
   puts $mig_prj_file {        <emrCSSelection name="Controller Chip Select Pin" >Disable</emrCSSelection>}
   puts $mig_prj_file {        <emrRTT name="RTT (nominal) - On Die Termination (ODT)" >RZQ/4</emrRTT>}
   puts $mig_prj_file {        <emrPosted name="Additive Latency (AL)" >0</emrPosted>}
   puts $mig_prj_file {        <emrOCD name="Write Leveling Enable" >Disabled</emrOCD>}
   puts $mig_prj_file {        <emrDQS name="TDQS enable" >Enabled</emrDQS>}
   puts $mig_prj_file {        <emrRDQS name="Qoff" >Output Buffer Enabled</emrRDQS>}
   puts $mig_prj_file {        <mr2PartialArraySelfRefresh name="Partial-Array Self Refresh" >Full Array</mr2PartialArraySelfRefresh>}
   puts $mig_prj_file {        <mr2CasWriteLatency name="CAS write latency" >5</mr2CasWriteLatency>}
   puts $mig_prj_file {        <mr2AutoSelfRefresh name="Auto Self Refresh" >Enabled</mr2AutoSelfRefresh>}
   puts $mig_prj_file {        <mr2SelfRefreshTempRange name="High Temparature Self Refresh Rate" >Normal</mr2SelfRefreshTempRange>}
   puts $mig_prj_file {        <mr2RTTWR name="RTT_WR - Dynamic On Die Termination (ODT)" >Dynamic ODT off</mr2RTTWR>}
   puts $mig_prj_file {        <PortInterface>AXI</PortInterface>}
   puts $mig_prj_file {        <AXIParameters>}
   puts $mig_prj_file {            <C0_C_RD_WR_ARB_ALGORITHM>RD_PRI_REG</C0_C_RD_WR_ARB_ALGORITHM>}
   puts $mig_prj_file {            <C0_S_AXI_ADDR_WIDTH>29</C0_S_AXI_ADDR_WIDTH>}
   puts $mig_prj_file {            <C0_S_AXI_DATA_WIDTH>128</C0_S_AXI_DATA_WIDTH>}
   puts $mig_prj_file {            <C0_S_AXI_ID_WIDTH>4</C0_S_AXI_ID_WIDTH>}
   puts $mig_prj_file {            <C0_S_AXI_SUPPORTS_NARROW_BURST>1</C0_S_AXI_SUPPORTS_NARROW_BURST>}
   puts $mig_prj_file {        </AXIParameters>}
   puts $mig_prj_file {    </Controller>}
   puts $mig_prj_file {</Project>}

   close $mig_prj_file
}
# End of write_mig_file_Top_mig_7series_0_0()



##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: LED_BLINKER1
proc create_hier_cell_LED_BLINKER1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_LED_BLINKER1() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I CLK
  create_bd_pin -dir O -from 0 -to 0 LED_ON_L
  create_bd_pin -dir I OK
  create_bd_pin -dir I RESET_L

  # Create instance: c_counter_binary_0, and set properties
  set c_counter_binary_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0 ]
  set_property -dict [ list \
   CONFIG.Output_Width {26} \
 ] $c_counter_binary_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $util_vector_logic_2

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {25} \
   CONFIG.DIN_TO {25} \
   CONFIG.DIN_WIDTH {26} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_0

  # Create port connections
  connect_bd_net -net CLK_1 [get_bd_pins CLK] [get_bd_pins c_counter_binary_0/CLK]
  connect_bd_net -net OK_1 [get_bd_pins OK] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net RESET_L_1 [get_bd_pins RESET_L] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net c_counter_binary_0_Q [get_bd_pins c_counter_binary_0/Q] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins util_vector_logic_2/Op2]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins LED_ON_L] [get_bd_pins util_vector_logic_2/Res]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins util_vector_logic_1/Op1] [get_bd_pins xlslice_0/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: LED_BLINKER
proc create_hier_cell_LED_BLINKER { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_LED_BLINKER() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I CLK
  create_bd_pin -dir O -from 0 -to 0 LED_ON_L
  create_bd_pin -dir I OK
  create_bd_pin -dir I RESET_L

  # Create instance: c_counter_binary_0, and set properties
  set c_counter_binary_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0 ]
  set_property -dict [ list \
   CONFIG.Output_Width {26} \
 ] $c_counter_binary_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $util_vector_logic_2

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {25} \
   CONFIG.DIN_TO {25} \
   CONFIG.DIN_WIDTH {26} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_0

  # Create port connections
  connect_bd_net -net CLK_1 [get_bd_pins CLK] [get_bd_pins c_counter_binary_0/CLK]
  connect_bd_net -net OK_1 [get_bd_pins OK] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net RESET_L_1 [get_bd_pins RESET_L] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net c_counter_binary_0_Q [get_bd_pins c_counter_binary_0/Q] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins util_vector_logic_2/Op2]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins LED_ON_L] [get_bd_pins util_vector_logic_2/Res]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins util_vector_logic_1/Op1] [get_bd_pins xlslice_0/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}


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
  set DDR3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR3 ]

  set SPI_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 SPI_0 ]

  set pcie_clkin [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_clkin ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_clkin

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_mgt ]

  set sys_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $sys_clk


  # Create ports
  set LED_A1 [ create_bd_port -dir O -from 0 -to 0 LED_A1 ]
  set LED_A2 [ create_bd_port -dir O -from 0 -to 0 LED_A2 ]
  set LED_A3 [ create_bd_port -dir O -from 0 -to 0 LED_A3 ]
  set LED_A4 [ create_bd_port -dir O -from 0 -to 0 LED_A4 ]
  set pci_reset [ create_bd_port -dir I -type rst pci_reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pci_reset
  set pcie_clkreq_l [ create_bd_port -dir O -from 0 -to 0 pcie_clkreq_l ]
  set real_spi_ss [ create_bd_port -dir O -from 0 -to 0 real_spi_ss ]

  # Create instance: LED_BLINKER
  create_hier_cell_LED_BLINKER [current_bd_instance .] LED_BLINKER

  # Create instance: LED_BLINKER1
  create_hier_cell_LED_BLINKER1 [current_bd_instance .] LED_BLINKER1

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
   CONFIG.NUM_MI {7} \
   CONFIG.NUM_SI {1} \
 ] $axi_interconnect_dbus

  # Create instance: axi_interconnect_mig, and set properties
  set axi_interconnect_mig [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_mig ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {3} \
   CONFIG.S00_HAS_REGSLICE {4} \
   CONFIG.S01_HAS_REGSLICE {4} \
   CONFIG.S02_HAS_REGSLICE {4} \
 ] $axi_interconnect_mig

  # Create instance: axi_interconnect_xdma, and set properties
  set axi_interconnect_xdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_xdma ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {3} \
 ] $axi_interconnect_xdma

  # Create instance: axi_quad_spi_0, and set properties
  set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_0 ]
  set_property -dict [ list \
   CONFIG.C_FIFO_DEPTH {256} \
   CONFIG.C_SCK_RATIO {2} \
   CONFIG.C_SPI_MEMORY {3} \
   CONFIG.C_SPI_MODE {2} \
 ] $axi_quad_spi_0

  # Create instance: axi_uart16550_cpu, and set properties
  set axi_uart16550_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_cpu ]

  # Create instance: axi_uart16550_host, and set properties
  set axi_uart16550_host [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_host ]

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
  
  # Create instance: mig_7series_0, and set properties
  set mig_7series_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0 ]

  # Generate the PRJ File for MIG
  set str_mig_folder [get_property IP_DIR [ get_ips [ get_property CONFIG.Component_Name $mig_7series_0 ] ] ]
  set str_mig_file_name mig_a.prj
  set str_mig_file_path ${str_mig_folder}/${str_mig_file_name}

  write_mig_file_Top_mig_7series_0_0 $str_mig_file_path

  set_property -dict [ list \
   CONFIG.BOARD_MIG_PARAM {Custom} \
   CONFIG.RESET_BOARD_INTERFACE {Custom} \
   CONFIG.XML_INPUT_FILE {mig_a.prj} \
 ] $mig_7series_0

  # Create instance: proc_sys_reset_cpu, and set properties
  set proc_sys_reset_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_cpu ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {1} \
 ] $proc_sys_reset_cpu

  # Create instance: proc_sys_reset_mig, and set properties
  set proc_sys_reset_mig [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_mig ]

  # Create instance: system_ila_cpu, and set properties
  set system_ila_cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_cpu ]
  set_property -dict [ list \
   CONFIG.C_BRAM_CNT {6.5} \
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
   CONFIG.C_SLOT_2_AXI_AW_SEL_DATA {0} \
   CONFIG.C_SLOT_2_AXI_AW_SEL_TRIG {0} \
   CONFIG.C_SLOT_2_AXI_B_SEL_DATA {0} \
   CONFIG.C_SLOT_2_AXI_B_SEL_TRIG {0} \
   CONFIG.C_SLOT_2_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_2_AXI_R_SEL_TRIG {1} \
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

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $util_ds_buf

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_1

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

  # Create instance: xadc_wiz_0, and set properties
  set xadc_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc_wiz_0 ]
  set_property -dict [ list \
   CONFIG.ADC_CONVERSION_RATE {1000} \
   CONFIG.DCLK_FREQUENCY {125} \
   CONFIG.ENABLE_RESET {false} \
   CONFIG.ENABLE_TEMP_BUS {true} \
   CONFIG.INTERFACE_SELECTION {Enable_AXI} \
 ] $xadc_wiz_0

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0 ]
  set_property -dict [ list \
   CONFIG.PF0_DEVICE_ID_mqdma {9024} \
   CONFIG.PF0_SRIOV_VF_DEVICE_ID {0000} \
   CONFIG.PF1_SRIOV_VF_DEVICE_ID {A134} \
   CONFIG.PF2_DEVICE_ID_mqdma {9024} \
   CONFIG.PF2_SRIOV_VF_DEVICE_ID {A234} \
   CONFIG.PF3_DEVICE_ID_mqdma {9024} \
   CONFIG.PF3_SRIOV_VF_DEVICE_ID {A334} \
   CONFIG.axi_bypass_64bit_en {false} \
   CONFIG.axi_bypass_prefetchable {false} \
   CONFIG.axi_data_width {128_bit} \
   CONFIG.axi_id_width {2} \
   CONFIG.axil_master_64bit_en {true} \
   CONFIG.axil_master_prefetchable {false} \
   CONFIG.axilite_master_en {true} \
   CONFIG.axilite_master_scale {Kilobytes} \
   CONFIG.axilite_master_size {128} \
   CONFIG.axist_bypass_en {false} \
   CONFIG.axist_bypass_scale {Megabytes} \
   CONFIG.axist_bypass_size {1} \
   CONFIG.axisten_freq {125} \
   CONFIG.cfg_mgmt_if {false} \
   CONFIG.copy_pf0 {true} \
   CONFIG.enable_gen4 {false} \
   CONFIG.mode_selection {Basic} \
   CONFIG.pcie_extended_tag {true} \
   CONFIG.pf0_Use_Class_Code_Lookup_Assistant {false} \
   CONFIG.pf0_base_class_menu {Simple_communication_controllers} \
   CONFIG.pf0_class_code {070002} \
   CONFIG.pf0_class_code_base {07} \
   CONFIG.pf0_class_code_interface {02} \
   CONFIG.pf0_class_code_sub {00} \
   CONFIG.pf0_device_id {7011} \
   CONFIG.pf0_interrupt_pin {NONE} \
   CONFIG.pf0_msix_cap_pba_bir {BAR_3:2} \
   CONFIG.pf0_msix_cap_pba_offset {00000000} \
   CONFIG.pf0_msix_cap_table_bir {BAR_3:2} \
   CONFIG.pf0_msix_cap_table_offset {00000000} \
   CONFIG.pf0_msix_cap_table_size {000} \
   CONFIG.pf0_msix_enabled {false} \
   CONFIG.pf0_sub_class_interface_menu {16550_compatible_serial_controller} \
   CONFIG.pf0_subsystem_id {0} \
   CONFIG.pf0_subsystem_vendor_id {0} \
   CONFIG.pf1_msix_cap_table_size {020} \
   CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} \
   CONFIG.pl_link_cap_max_link_width {X4} \
   CONFIG.plltype {QPLL1} \
   CONFIG.vendor_id {10EE} \
   CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
   CONFIG.xdma_pcie_64bit_en {true} \
   CONFIG.xdma_pcie_prefetchable {false} \
   CONFIG.xdma_rnum_chnl {1} \
   CONFIG.xdma_rnum_rids {2} \
   CONFIG.xdma_wnum_chnl {1} \
   CONFIG.xdma_wnum_rids {2} \
 ] $xdma_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_1

  # Create instance: xlconstant_cpu_interrupt, and set properties
  set xlconstant_cpu_interrupt [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_cpu_interrupt ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_cpu_interrupt

  # Create instance: xlconstant_state, and set properties
  set xlconstant_state [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_state ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $xlconstant_state

  # Create instance: xlconstant_sys_rst, and set properties
  set xlconstant_sys_rst [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_sys_rst ]

  # Create instance: xlconstant_uart_freeze, and set properties
  set xlconstant_uart_freeze [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_uart_freeze ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_uart_freeze

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M00_AXI [get_bd_intf_pins axi_interconnect_dbus/M00_AXI] [get_bd_intf_pins axi_interconnect_mig/S02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M01_AXI [get_bd_intf_pins axi_gpio_vled/S_AXI] [get_bd_intf_pins axi_interconnect_dbus/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M02_AXI [get_bd_intf_pins axi_interconnect_dbus/M02_AXI] [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M03_AXI [get_bd_intf_pins axi_interconnect_dbus/M03_AXI] [get_bd_intf_pins axi_uart16550_cpu/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M04_AXI [get_bd_intf_pins axi_intc_platform/s_axi] [get_bd_intf_pins axi_interconnect_dbus/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M05_AXI [get_bd_intf_pins aclint_cpu/s_axi_ipi] [get_bd_intf_pins axi_interconnect_dbus/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_dbus_M06_AXI [get_bd_intf_pins aclint_cpu/s_axi_timer] [get_bd_intf_pins axi_interconnect_dbus/M06_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_mig_M00_AXI [get_bd_intf_pins axi_interconnect_mig/M00_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M00_AXI [get_bd_intf_pins axi_interconnect_xdma/M00_AXI] [get_bd_intf_pins axi_uart16550_host/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M01_AXI [get_bd_intf_pins axi_gpio_jtag/S_AXI] [get_bd_intf_pins axi_interconnect_xdma/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_xdma_M02_AXI [get_bd_intf_pins axi_interconnect_xdma/M02_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net axi_quad_spi_0_SPI_0 [get_bd_intf_ports SPI_0] [get_bd_intf_pins axi_quad_spi_0/SPI_0]
  connect_bd_intf_net -intf_net cpu_dBusAxi [get_bd_intf_pins axi_interconnect_dbus/S00_AXI] [get_bd_intf_pins vexriscv_inst/dBusAxi]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpu_dBusAxi] [get_bd_intf_pins axi_interconnect_dbus/S00_AXI] [get_bd_intf_pins system_ila_cpu/SLOT_1_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpu_dBusAxi]
  connect_bd_intf_net -intf_net cpu_iBusAxi [get_bd_intf_pins axi_interconnect_mig/S01_AXI] [get_bd_intf_pins vexriscv_inst/iBusAxi]
connect_bd_intf_net -intf_net [get_bd_intf_nets cpu_iBusAxi] [get_bd_intf_pins axi_interconnect_mig/S01_AXI] [get_bd_intf_pins system_ila_cpu/SLOT_2_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets cpu_iBusAxi]
  connect_bd_intf_net -intf_net diff_clock_rtl_0_1 [get_bd_intf_ports pcie_clkin] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net diff_clock_rtl_1_1 [get_bd_intf_ports sys_clk] [get_bd_intf_pins mig_7series_0/SYS_CLK]
  connect_bd_intf_net -intf_net mig_7series_0_DDR3 [get_bd_intf_ports DDR3] [get_bd_intf_pins mig_7series_0/DDR3]
  connect_bd_intf_net -intf_net xdma_0_M_AXI [get_bd_intf_pins axi_interconnect_mig/S00_AXI] [get_bd_intf_pins xdma_0/M_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets xdma_0_M_AXI] [get_bd_intf_pins system_ila_cpu/SLOT_0_AXI] [get_bd_intf_pins xdma_0/M_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets xdma_0_M_AXI]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins xdma_0/pcie_mgt]
  connect_bd_intf_net -intf_net xdma_M_AXI_LITE [get_bd_intf_pins axi_interconnect_xdma/S00_AXI] [get_bd_intf_pins xdma_0/M_AXI_LITE]
connect_bd_intf_net -intf_net [get_bd_intf_nets xdma_M_AXI_LITE] [get_bd_intf_pins system_ila_cpu/SLOT_3_AXI] [get_bd_intf_pins xdma_0/M_AXI_LITE]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets xdma_M_AXI_LITE]

  # Create port connections
  connect_bd_net -net LED_BLINKER1_LED_ON_L [get_bd_ports LED_A4] [get_bd_pins LED_BLINKER1/LED_ON_L]
  connect_bd_net -net LED_BLINKER_LED_ON_L [get_bd_ports LED_A3] [get_bd_pins LED_BLINKER/LED_ON_L]
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins axi_interconnect_mig/S02_ARESETN] [get_bd_pins axi_uart16550_cpu/s_axi_aresetn] [get_bd_pins proc_sys_reset_cpu/peripheral_aresetn]
  connect_bd_net -net OK_1 [get_bd_pins LED_BLINKER/OK] [get_bd_pins system_ila_cpu/probe0] [get_bd_pins xdma_0/user_lnk_up]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets OK_1]
  connect_bd_net -net RESET_L_1 [get_bd_pins LED_BLINKER1/RESET_L] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins aclint_cpu/s_axi_ipi_aresetn] [get_bd_pins aclint_cpu/s_axi_timer_aresetn] [get_bd_pins axi_gpio_jtag/s_axi_aresetn] [get_bd_pins axi_gpio_vled/s_axi_aresetn] [get_bd_pins axi_intc_platform/s_axi_aresetn] [get_bd_pins axi_interconnect_dbus/M00_ARESETN] [get_bd_pins axi_interconnect_dbus/M01_ARESETN] [get_bd_pins axi_interconnect_dbus/M02_ARESETN] [get_bd_pins axi_interconnect_dbus/M03_ARESETN] [get_bd_pins axi_interconnect_dbus/M04_ARESETN] [get_bd_pins axi_interconnect_dbus/M05_ARESETN] [get_bd_pins axi_interconnect_dbus/M06_ARESETN] [get_bd_pins axi_interconnect_dbus/S00_ARESETN] [get_bd_pins axi_interconnect_mig/S00_ARESETN] [get_bd_pins axi_interconnect_mig/S01_ARESETN] [get_bd_pins axi_interconnect_xdma/M00_ARESETN] [get_bd_pins axi_interconnect_xdma/M01_ARESETN] [get_bd_pins axi_interconnect_xdma/M02_ARESETN] [get_bd_pins axi_interconnect_xdma/S00_ARESETN] [get_bd_pins axi_quad_spi_0/s_axi_aresetn] [get_bd_pins axi_uart16550_host/s_axi_aresetn] [get_bd_pins proc_sys_reset_cpu/ext_reset_in] [get_bd_pins proc_sys_reset_mig/ext_reset_in] [get_bd_pins system_ila_cpu/resetn] [get_bd_pins util_vector_logic_debugReset/Op1] [get_bd_pins xadc_wiz_0/s_axi_aresetn] [get_bd_pins xdma_0/axi_aresetn]
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
  connect_bd_net -net axi_quad_spi_0_ss_o [get_bd_ports LED_A2] [get_bd_ports real_spi_ss] [get_bd_pins axi_quad_spi_0/ss_o]
  connect_bd_net -net axi_uart16550_cpu_sout [get_bd_pins axi_uart16550_cpu/sout] [get_bd_pins axi_uart16550_host/sin] [get_bd_pins system_ila_cpu/probe9]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_uart16550_cpu_sout]
  connect_bd_net -net axi_uart16550_host_sout [get_bd_pins axi_uart16550_cpu/sin] [get_bd_pins axi_uart16550_host/sout] [get_bd_pins system_ila_cpu/probe11]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets axi_uart16550_host_sout]
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
  connect_bd_net -net iBusAxi [get_bd_pins aclint_cpu/s_axi_ipi_aclk] [get_bd_pins aclint_cpu/s_axi_timer_aclk] [get_bd_pins axi_gpio_jtag/s_axi_aclk] [get_bd_pins axi_gpio_vled/s_axi_aclk] [get_bd_pins axi_intc_platform/s_axi_aclk] [get_bd_pins axi_interconnect_dbus/ACLK] [get_bd_pins axi_interconnect_dbus/M00_ACLK] [get_bd_pins axi_interconnect_dbus/M01_ACLK] [get_bd_pins axi_interconnect_dbus/M02_ACLK] [get_bd_pins axi_interconnect_dbus/M03_ACLK] [get_bd_pins axi_interconnect_dbus/M04_ACLK] [get_bd_pins axi_interconnect_dbus/M05_ACLK] [get_bd_pins axi_interconnect_dbus/M06_ACLK] [get_bd_pins axi_interconnect_dbus/S00_ACLK] [get_bd_pins axi_interconnect_mig/ACLK] [get_bd_pins axi_interconnect_mig/S00_ACLK] [get_bd_pins axi_interconnect_mig/S01_ACLK] [get_bd_pins axi_interconnect_mig/S02_ACLK] [get_bd_pins axi_interconnect_xdma/M00_ACLK] [get_bd_pins axi_interconnect_xdma/M01_ACLK] [get_bd_pins axi_interconnect_xdma/M02_ACLK] [get_bd_pins axi_interconnect_xdma/S00_ACLK] [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins axi_quad_spi_0/s_axi_aclk] [get_bd_pins axi_uart16550_cpu/s_axi_aclk] [get_bd_pins axi_uart16550_host/s_axi_aclk] [get_bd_pins proc_sys_reset_cpu/slowest_sync_clk] [get_bd_pins system_ila_cpu/clk] [get_bd_pins vexriscv_inst/clk] [get_bd_pins vio_vled/clk] [get_bd_pins xadc_wiz_0/s_axi_aclk] [get_bd_pins xdma_0/axi_aclk]
  connect_bd_net -net mig_7series_0_init_calib_complete [get_bd_pins LED_BLINKER1/OK] [get_bd_pins mig_7series_0/init_calib_complete]
  connect_bd_net -net mig_7series_0_mmcm_locked [get_bd_pins mig_7series_0/mmcm_locked] [get_bd_pins proc_sys_reset_mig/dcm_locked]
  connect_bd_net -net mig_7series_0_ui_clk [get_bd_pins LED_BLINKER1/CLK] [get_bd_pins axi_interconnect_mig/M00_ACLK] [get_bd_pins axi_interconnect_xdma/ACLK] [get_bd_pins mig_7series_0/ui_clk] [get_bd_pins proc_sys_reset_mig/slowest_sync_clk]
  connect_bd_net -net mig_7series_0_ui_clk_sync_rst [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net pci_reset_1 [get_bd_ports pci_reset] [get_bd_pins LED_BLINKER/RESET_L] [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net proc_sys_reset_cpu_interconnect_aresetn [get_bd_pins axi_interconnect_dbus/ARESETN] [get_bd_pins axi_interconnect_mig/ARESETN] [get_bd_pins proc_sys_reset_cpu/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_cpu_mb_reset [get_bd_pins proc_sys_reset_cpu/mb_reset] [get_bd_pins util_vector_logic_cpu_reset/Op2]
  connect_bd_net -net proc_sys_reset_mig_peripheral_aresetn [get_bd_pins axi_interconnect_mig/M00_ARESETN] [get_bd_pins axi_interconnect_xdma/ARESETN] [get_bd_pins mig_7series_0/aresetn] [get_bd_pins proc_sys_reset_mig/peripheral_aresetn]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins LED_BLINKER/CLK] [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_vector_logic_cpu_reset_Res [get_bd_pins system_ila_cpu/probe10] [get_bd_pins util_vector_logic_cpu_reset/Res] [get_bd_pins vexriscv_inst/reset]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets util_vector_logic_cpu_reset_Res]
  connect_bd_net -net util_vector_logic_debugReset_Res [get_bd_pins util_vector_logic_debugReset/Res] [get_bd_pins vexriscv_inst/debugReset]
  connect_bd_net -net xadc_wiz_1_temp_out [get_bd_pins mig_7series_0/device_temp_i] [get_bd_pins xadc_wiz_0/temp_out]
  connect_bd_net -net xlconstant_1_dout [get_bd_ports pcie_clkreq_l] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlconstant_2_dout [get_bd_pins mig_7series_0/sys_rst] [get_bd_pins xlconstant_sys_rst/dout]
  connect_bd_net -net xlconstant_cpu_interrupt_dout [get_bd_pins axi_intc_platform/intr] [get_bd_pins vexriscv_inst/externalInterruptS] [get_bd_pins vexriscv_inst/softwareInterrupt] [get_bd_pins xlconstant_cpu_interrupt/dout]
  connect_bd_net -net xlconstant_state_dout [get_bd_ports LED_A1] [get_bd_pins xlconstant_state/dout]
  connect_bd_net -net xlconstant_uart_freeze_dout [get_bd_pins axi_uart16550_cpu/freeze] [get_bd_pins axi_uart16550_host/freeze] [get_bd_pins xlconstant_uart_freeze/dout]

  # Create address segments
  assign_bd_address -offset 0x40022000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs aclint_cpu/s_axi_ipi/reg0] -force
  assign_bd_address -offset 0x40020000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs aclint_cpu/s_axi_timer/reg0] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_gpio_vled/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_intc_platform/S_AXI/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs axi_uart16550_cpu/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/iBusAxi] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces vexriscv_inst/dBusAxi] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs axi_gpio_jtag/S_AXI/Reg] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs axi_uart16550_host/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] -force


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


