set project_name aclint
set vendor_name vendor
set library_name VexRiscv
set taxonomy /Network
set display_name "RISC-V ACLINT"
set supported_families "*"
set core_version 1.0
set core_revision 1

set rtl_dir .

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
lappend source_files $rtl_dir/aclint_v1_0_S_AXI_IPI.sv
lappend source_files $rtl_dir/aclint_v1_0_S_AXI_TIMER.sv
lappend source_files $rtl_dir/aclint_v1_0.sv

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


# Generate other files and save IP core.
ipx::create_xgui_files $ipcore
ipx::update_checksums $ipcore
ipx::save_core $ipcore

# Finalize project
close_project
