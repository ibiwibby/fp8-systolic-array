# Recreate the Vivado project from repository sources.
# Run from the repository root:
#   vivado -mode batch -source scripts/create_project.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_dir build vivado]
set rtl_dir [file join $repo_dir Lab5.srcs sources_1 new]

create_project fp8_systolic $build_dir -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set rtl_sources [list \
    [file join $rtl_dir fp_decode.v] \
    [file join $rtl_dir fp_encode.v] \
    [file join $rtl_dir fp_add.v] \
    [file join $rtl_dir fp_mult.v] \
    [file join $rtl_dir mac_fp.v] \
    [file join $rtl_dir systolic_mul.v]]

add_files -norecurse $rtl_sources
add_files -fileset constrs_1 -norecurse \
    [file join $repo_dir constraints clock.xdc]
set_property top systolic_mul [current_fileset]
update_compile_order -fileset sources_1

puts "Created project: [file join $build_dir fp8_systolic.xpr]"
