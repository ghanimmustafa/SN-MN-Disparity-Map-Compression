# ============================================================================
# Synopsys Design Compiler 2-Input NAND Gate Reference Area Script
# Used to compute Gate Equivalents (GE = Total Design Area / NAND2 Area)
# In TSMC 40nm (sc12mc_cln40g_base_rvt_c40_ss_typical_max_0p81v_125c.db),
# NAND2_X0P5M_A12TR area = 0.7056 um^2 (see results/asic_40nm_reports/nand_results_log.txt)
# ============================================================================

if { ![info exists target_lib] } {
    set target_lib "sc12mc_cln40g_base_rvt_c40_ss_typical_max_0p81v_125c.db"
}

set repo_root [file normalize [file join [file dirname [info script]] "../.." ]]
set out_dir   [file join $repo_root "build" "asic_40nm" "nand2_ref"]
file mkdir $out_dir

set nand_v [file join $out_dir "nand_gate.v"]
set fp [open $nand_v "w"]
puts $fp "module nand_gate(input a, input b, output y);"
puts $fp "    assign y = ~(a & b);"
puts $fp "endmodule"
close $fp

set target_library [list $target_lib]
set link_library   [list "*" $target_lib]

define_design_lib USER -path [file join $out_dir "work"]
analyze -format verilog -lib USER $nand_v
elaborate nand_gate -lib USER
link
uniquify
set_max_area 0
set_wire_load_mode top
compile_ultra -no_autoungroup
report_area > [file join $out_dir "nand2_area.rpt"]
write -f verilog -hier -output [file join $out_dir "nand_gate.vg"] nand_gate
exit
