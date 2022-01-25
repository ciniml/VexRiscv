set project_name vexriscv
set vendor_name VexRiscv
set library_name VexRiscv
set taxonomy /Network
set display_name "VexRiscv"
set supported_families "*"
set core_version 1.0
set core_revision 1

set rtl_dir ../..

create_project $project_name.xpr -in_memory
set device_part "xc7z010clg400-1"
set_property part $device_part [current_project]

# Add target files
# Create 'sources_1' fileset
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
# Create 'constrs_1' fileset
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -srcset constrs_1
}
# Create 'sim_1' fileset
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -srcset sim_1
}

# Define source file list

set source_files {}
lappend source_files $rtl_dir/VexRiscv.v

set constraint_files {}

# Add source files to filesets
foreach source_file $source_files {
  set name [file tail $source_file]
  add_file -fileset [get_filesets sources_1] $source_file
}
# foreach constraint_file $constraint_files {
#   add_file -fileset [get_filesets constrs_1] $constraint_file
# }

# Package IP.
ipx::package_project -root_dir . -vendor $vendor_name -library $library_name -taxonomy $taxonomy -force
set ipcore [ipx::current_core]

# Set basic properties.
set_property NAME $project_name $ipcore
set_property DISPLAY_NAME $display_name $ipcore
set_property SUPPORTED_FAMILIES $supported_families $ipcore
set_property VERSION $core_version $ipcore
set_property CORE_REVISION $core_revision $ipcore

## Helper interface generator functions
proc add_clock_if { name direction associated_busif } {
  set bus_if [ipx::add_bus_interface $name [ipx::current_core]]
  set_property ABSTRACTION_TYPE_VLNV xilinx.com:signal:clock_rtl:1.0 $bus_if
  set_property BUS_TYPE_VLNV xilinx.com:signal:clock:1.0 $bus_if
  set_property INTERFACE_MODE $direction $bus_if
  ipx::add_port_map CLK $bus_if
  set_property physical_name $name [ipx::get_port_maps CLK -of_objects $bus_if]
  # ipx::add_bus_parameter FREQ_HZ $bus_if
  # set_property VALUE $freq_hz [ipx::get_bus_parameters FREQ_HZ -of_objects $bus_if]
  if { [string length $associated_busif] ne 0 } {
    ipx::add_bus_parameter ASSOCIATED_BUSIF $bus_if
    set_property VALUE $associated_busif [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects $bus_if]
  }
}
proc add_reset_if { name direction polarity } {
  set bus_if [ipx::add_bus_interface $name [ipx::current_core]]
  set_property ABSTRACTION_TYPE_VLNV xilinx.com:signal:reset_rtl:1.0 $bus_if
  set_property BUS_TYPE_VLNV xilinx.com:signal:reset:1.0 $bus_if
  set_property INTERFACE_MODE $direction $bus_if
  ipx::add_port_map RST $bus_if
  set_property PHYSICAL_NAME $name [ipx::get_port_maps RST -of_objects $bus_if]
  ipx::add_bus_parameter POLARITY $bus_if
  set_property VALUE $polarity [ipx::get_bus_parameters POLARITY -of_objects $bus_if]
}

proc add_port_map {bus_if if_name physical_name} {
  set_property PHYSICAL_NAME $physical_name [ipx::add_port_map $if_name $bus_if]
}


# iBus AXI Interface
set ibus_if [ipx::add_bus_interface iBusAxi [ipx::current_core]]
set_property ABSTRACTION_TYPE_VLNV xilinx.com:interface:aximm_rtl:1.0 $ibus_if
set_property BUS_TYPE_VLNV xilinx.com:interface:aximm:1.0 $ibus_if
set_property INTERFACE_MODE master $ibus_if

add_port_map $ibus_if ARVALID  iBusAxi_ar_valid
add_port_map $ibus_if ARREADY  iBusAxi_ar_ready
add_port_map $ibus_if ARADDR   iBusAxi_ar_payload_addr
add_port_map $ibus_if ARID     iBusAxi_ar_payload_id
add_port_map $ibus_if ARREGION iBusAxi_ar_payload_region
add_port_map $ibus_if ARLEN    iBusAxi_ar_payload_len
add_port_map $ibus_if ARSIZE   iBusAxi_ar_payload_size
add_port_map $ibus_if ARBURST  iBusAxi_ar_payload_burst
add_port_map $ibus_if ARLOCK   iBusAxi_ar_payload_lock
add_port_map $ibus_if ARCACHE  iBusAxi_ar_payload_cache
add_port_map $ibus_if ARQOS    iBusAxi_ar_payload_qos
add_port_map $ibus_if ARPROT   iBusAxi_ar_payload_prot

add_port_map $ibus_if RVALID   iBusAxi_r_valid
add_port_map $ibus_if RREADY   iBusAxi_r_ready
add_port_map $ibus_if RDATA    iBusAxi_r_payload_data
add_port_map $ibus_if RID      iBusAxi_r_payload_id
add_port_map $ibus_if RRESP    iBusAxi_r_payload_resp
add_port_map $ibus_if RLAST    iBusAxi_r_payload_last

# dBus AXI Interface
set dbus_if [ipx::add_bus_interface dBusAxi [ipx::current_core]]
set_property ABSTRACTION_TYPE_VLNV xilinx.com:interface:aximm_rtl:1.0 $dbus_if
set_property BUS_TYPE_VLNV xilinx.com:interface:aximm:1.0 $dbus_if
set_property INTERFACE_MODE master $dbus_if

add_port_map $dbus_if ARVALID  dBusAxi_ar_valid
add_port_map $dbus_if ARREADY  dBusAxi_ar_ready
add_port_map $dbus_if ARADDR   dBusAxi_ar_payload_addr
add_port_map $dbus_if ARID     dBusAxi_ar_payload_id
add_port_map $dbus_if ARREGION dBusAxi_ar_payload_region
add_port_map $dbus_if ARLEN    dBusAxi_ar_payload_len
add_port_map $dbus_if ARSIZE   dBusAxi_ar_payload_size
add_port_map $dbus_if ARBURST  dBusAxi_ar_payload_burst
add_port_map $dbus_if ARLOCK   dBusAxi_ar_payload_lock
add_port_map $dbus_if ARCACHE  dBusAxi_ar_payload_cache
add_port_map $dbus_if ARQOS    dBusAxi_ar_payload_qos
add_port_map $dbus_if ARPROT   dBusAxi_ar_payload_prot

add_port_map $dbus_if RVALID   dBusAxi_r_valid
add_port_map $dbus_if RREADY   dBusAxi_r_ready
add_port_map $dbus_if RDATA    dBusAxi_r_payload_data
add_port_map $dbus_if RID      dBusAxi_r_payload_id
add_port_map $dbus_if RRESP    dBusAxi_r_payload_resp
add_port_map $dbus_if RLAST    dBusAxi_r_payload_last

add_port_map $dbus_if AWVALID  dBusAxi_aw_valid
add_port_map $dbus_if AWREADY  dBusAxi_aw_ready
add_port_map $dbus_if AWADDR   dBusAxi_aw_payload_addr
add_port_map $dbus_if AWID     dBusAxi_aw_payload_id
add_port_map $dbus_if AWREGION dBusAxi_aw_payload_region
add_port_map $dbus_if AWLEN    dBusAxi_aw_payload_len
add_port_map $dbus_if AWSIZE   dBusAxi_aw_payload_size
add_port_map $dbus_if AWBURST  dBusAxi_aw_payload_burst
add_port_map $dbus_if AWLOCK   dBusAxi_aw_payload_lock
add_port_map $dbus_if AWCACHE  dBusAxi_aw_payload_cache
add_port_map $dbus_if AWQOS    dBusAxi_aw_payload_qos
add_port_map $dbus_if AWPROT   dBusAxi_aw_payload_prot

add_port_map $dbus_if WVALID   dBusAxi_w_valid
add_port_map $dbus_if WREADY   dBusAxi_w_ready
add_port_map $dbus_if WDATA    dBusAxi_w_payload_data
add_port_map $dbus_if WSTRB    dBusAxi_w_payload_strb
add_port_map $dbus_if WLAST    dBusAxi_w_payload_last

add_port_map $dbus_if BVALID   dBusAxi_b_valid
add_port_map $dbus_if BREADY   dBusAxi_b_ready
add_port_map $dbus_if BRESP    dBusAxi_b_payload_resp
add_port_map $dbus_if BID      dBusAxi_b_payload_id

# JTAG interface
set jtag_if [ipx::add_bus_interface jtag [ipx::current_core]]
set_property ABSTRACTION_TYPE_VLNV xilinx.com:interface:jtag_rtl:2.0 $jtag_if
set_property BUS_TYPE_VLNV xilinx.com:interface:jtag:2.0 $jtag_if
set_property INTERFACE_MODE slave $jtag_if
add_port_map $jtag_if TDI jtag_tdi
add_port_map $jtag_if TDO jtag_tdo
add_port_map $jtag_if TMS jtag_tms
add_port_map $jtag_if TCK jtag_tck

# Clock and Reset
add_clock_if clk slave {iBusAxi:dBusAxi:reset:debugReset:timerInterrupt:externalInterrupt:softwareInterrupt:externalInterruptS}
add_reset_if reset slave ACTIVE_HIGH
add_reset_if debugReset slave ACTIVE_HIGH
add_reset_if debug_resetOut master ACTIVE_HIGH

# Address space configuration
proc add_address_space {name range width target_interface} {
  set address_space [ipx::add_address_space $name [ipx::current_core]]
  set_property RANGE_FORMAT long $address_space
  set_property RANGE 4294967295  $address_space
  set_property WIDTH_FORMAT long $address_space
  set_property WIDTH 32          $address_space
  # Add address space reference to the target interface
  set_property MASTER_ADDRESS_SPACE_REF $name $target_interface
}

add_address_space iBusAxi 4294967295 32 $ibus_if
add_address_space dBusAxi 4294967295 32 $dbus_if

# Generate other files and save IP core.
ipx::create_xgui_files $ipcore
ipx::update_checksums $ipcore
ipx::save_core $ipcore

# Finalize project
close_project
