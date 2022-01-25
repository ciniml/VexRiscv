if { [llength $argv] == 0 } {
    error "Project name must be specified."
}
set project_name [lindex $argv 0]
set part {xc7a100tfgg484-2L}

create_project project/$project_name .

#set_param board.repoPaths [concat [file join $::env(HOME) {.Xilinx/Vivado/} [version -short] {xhub/board_store}] [get_param board.repoPaths]]
#set_property BOARD_PART_REPO_PATHS [get_param board.repoPaths] [current_project]

set_property PART $part [current_project]

lappend ip_repo_path_list [file normalize ../aclint]
lappend ip_repo_path_list [file normalize ../vexriscv]
set_property ip_repo_paths $ip_repo_path_list [get_filesets sources_1]
update_ip_catalog

# add_files ./dna_reader.v -fileset [get_filesets sources_1]
add_files ./gpio_jtag.v -fileset [get_filesets sources_1]
# add_files ./led_blinker_id.v -fileset [get_filesets sources_1]
# add_files ./user_efuse.v -fileset [get_filesets sources_1]

source ./Top.tcl
make_wrapper -top -fileset sources_1 -import [get_files project/$project_name.srcs/sources_1/bd/Top/Top.bd]

add_files ./early.xdc -fileset [get_filesets constrs_1]
add_files ./normal.xdc -fileset [get_filesets constrs_1]