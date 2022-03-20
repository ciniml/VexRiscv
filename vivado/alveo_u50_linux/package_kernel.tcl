if { [llength $argv] < 3 } {
    error "Project name, BD name and XO path must be specified."
}
set project_name [lindex $argv 0]
set bd_name [lindex $argv 1]
set xo_path [lindex $argv 2]

open_project project/$project_name

generate_target all [get_files project/${project_name}.srcs/sources_1/bd/$bd_name/$bd_name.bd]

ipx::package_project -root_dir vitis_kernel -vendor fugafuga.org -library user -taxonomy /UserIP -module Top -import_files -force
set core [ipx::current_core]

# Configure the IP for a Vitis kernel
set_property ipi_drc {ignore_freq_hz false} $core
set_property sdx_kernel true $core
set_property sdx_kernel_type rtl $core
set_property vitis_drc {ctrl_protocol user_managed} $core
set_property ipi_drc {ignore_freq_hz true} $core

# Remove FREQ_HZ bus parameter from the clock port
set clock_if [ipx::get_bus_interfaces CLK.CLOCK -of_objects $core]
ipx::remove_bus_parameter FREQ_HZ $clock_if
set_property value -1 [ipx::add_bus_parameter FREQ_TOLERANCE_HZ $clock_if]

# Remove default reg blocks
set mm_control [ipx::get_memory_maps s_axi_control -of_objects $core]
foreach block [ipx::get_address_blocks -of_object $mm_control] { ipx::remove_address_block [get_property NAME $block] $mm_control }

# Add reg block
set block [ipx::add_address_block {Reg0} $mm_control]
set_property range 0x10000 $block

# Add AXI MM pointer register
set reg_mm_ptr [ipx::add_register mem_ptr $block]
set_property address_offset 0x3000 $reg_mm_ptr
set_property size 32 $reg_mm_ptr
set reg_param [ipx::add_register_parameter ASSOCIATED_BUSIF $reg_mm_ptr]
set_property value m_axi_mem $reg_param

# Add AXI Slave dummy register
set reg_dummy_start [ipx::add_register dummy_start $block]
set_property address_offset 0x0000 $reg_dummy_start
set_property size 32 $reg_dummy_start
set reg_dummy_end [ipx::add_register dummy_end $block]
set_property address_offset 0xfffc $reg_dummy_end
set_property size 32 $reg_dummy_end

# Export kernel
set_property core_revision 2 $core
ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::check_integrity -kernel $core
ipx::save_core $core
package_xo  -xo_path $xo_path -kernel_name vexriscv -ip_directory vitis_kernel -ctrl_protocol user_managed
