# ============================================================================
# Vivado SAIF-Based Post-Implementation Dynamic Power Estimation Script
# Target Device: 28 nm Xilinx Spartan-7 (xc7s50fgga484-2)
#
# Reproduces Table 4.7 of the thesis:
#   1. Creates a Vivado project for <design_name>
#   2. Runs Synthesis & Implementation (Performance_ExtraTimingOpt)
#   3. Launches Post-Implementation Functional Simulation (xsim)
#   4. Logs switching activity of all internal signals into a .saif file:
#        open_saif <design>.saif
#        log_saif [get_objects -r *]
#        run all
#        close_saif
#   5. Opens the routed design, reads the .saif file, and runs report_power
#
# Usage:
#   vivado -mode batch -source scripts/vivado/run_vivado_saif_power.tcl \
#          -tclargs <design_name> <clock_mode>
# ============================================================================

set design_name "mf_mn_encoder"
set clock_mode  "125mhz"

if { $argc >= 1 } { set design_name [lindex $argv 0] }
if { $argc >= 2 } { set clock_mode  [lindex $argv 1] }

set part_name "xc7s50fgga484-2"
set repo_root [file normalize [file join [file dirname [info script]] "../.." ]]
set proj_dir  [file join $repo_root "build" "vivado_saif" "${design_name}_${clock_mode}"]
file mkdir $proj_dir

switch -exact -- $design_name {
    "sn_encoder" {
        set top_module "SN_encodingSystem_top"
        set tb_module  "SN_encoder_only_tb"
        set src_files  [glob [file join $repo_root "rtl/sn_encoder/src/*.v"]]
        set tb_file    [file join $repo_root "rtl/sn_encoder/tb/SN_encoder_only_tb.v"]
        set use_retiming 0
        set max_period 3.819
    }
    "mf_sn_encoder" {
        set top_module "SN_encoding_system_top"
        set tb_module  "SN_MF_encodingSys_tb"
        set src_files  [list \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoding_system_top.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/line_buffer.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoder.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_packetizer.v"] \
        ]
        set tb_file    [file join $repo_root "rtl/mf_sn_encoder/tb/SN_MF_encodingSys_tb.v"]
        set use_retiming 1
        set max_period 5.400
    }
    "sn_decoder" {
        set top_module "SN_decoder"
        set tb_module  "SN_decoder_tb"
        set src_files  [glob [file join $repo_root "rtl/sn_decoder/src/*.v"]]
        set tb_file    [file join $repo_root "rtl/sn_decoder/tb/SN_decoder_tb.v"]
        set use_retiming 0
        set max_period 5.050
    }
    "mn_encoder" {
        set top_module "MN_encoding_system_top_v1"
        set tb_module  "encoder_type2_tb"
        set src_files  [list \
            [file join $repo_root "rtl/mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set tb_file    [file join $repo_root "rtl/mn_encoder/tb/MN_encoder_only_tb.v"]
        set use_retiming 0
        set max_period 5.800
    }
    "mf_mn_encoder" {
        set top_module "MN_encoding_system_top_v1"
        set tb_module  "MF_MN_Encoder_tb"
        set src_files  [list \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set tb_file    [file join $repo_root "rtl/mf_mn_encoder/tb/MF_MN_Encoder_tb.v"]
        set use_retiming 1
        set max_period 6.000
    }
    "hlb_mn_encoder" {
        set top_module "HLB_MN_encoding_system_top_v1"
        set tb_module  "HLB_MN_Encoder_tb"
        set src_files  [list \
            [file join $repo_root "rtl/hlb_mn_encoder/src/HLB_MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/HLB_MN_encoder_v1.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set tb_file    [file join $repo_root "rtl/hlb_mn_encoder/tb/HLB_MN_Encoder_tb.v"]
        set use_retiming 0
        set max_period 5.800
    }
    "mf_hlb_mn_encoder" {
        set top_module "MF_HLB_MN_encoding_system_top"
        set tb_module  "MF_HLB_MN_Encoder_tb"
        set src_files  [list \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/MF_HLB_MN_encoding_system_top.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/HLB_MN_encoder.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/HLB.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set tb_file    [file join $repo_root "rtl/mf_hlb_mn_encoder/tb/MF_HLB_MN_Encoder_tb.v"]
        set use_retiming 1
        set max_period 5.900
    }
    "mn_decoder" {
        set top_module "MN_decoder"
        set tb_module  "MN_decoder_tb"
        set src_files  [glob [file join $repo_root "rtl/mn_decoder/src/*.v"]]
        set tb_file    [file join $repo_root "rtl/mn_decoder/tb/MN_decoder_tb.v"]
        set use_retiming 0
        set max_period 5.700
    }
    default {
        error "Unknown design_name: $design_name"
    }
}

if { $clock_mode eq "max_freq" } {
    set clk_period $max_period
} else {
    set clk_period 8.000
}
set half_period [expr {$clk_period / 2.0}]

create_project -force $design_name $proj_dir -part $part_name
add_files -fileset sources_1 $src_files
set_property top $top_module [current_fileset]

add_files -fileset sim_1 $tb_file
set_property top $tb_module [get_filesets sim_1]

# Write XDC timing constraint for project
set xdc_file [file join $proj_dir "timing_const.xdc"]
set fp [open $xdc_file "w"]
puts $fp "create_clock -period $clk_period -name system_clock -waveform {0.000 $half_period} \[get_ports clk\]"
close $fp
add_files -fileset constrs_1 $xdc_file

if { $use_retiming } {
    set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
}
set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]

# Run Synthesis and Implementation
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Launch Post-Implementation Functional Simulation to record SAIF
open_run impl_1
set saif_file [file join $proj_dir "${design_name}_${clock_mode}.saif"]
launch_simulation -mode post-implementation -type functional
open_saif $saif_file
log_saif [get_objects -r *]
run all
close_saif
close_sim

# Read SAIF and generate accurate dynamic + static power report
read_saif $saif_file
report_power -file [file join $proj_dir "${design_name}_${clock_mode}_saif_power.txt"]

puts "SAIF Power Report written to: [file join $proj_dir "${design_name}_${clock_mode}_saif_power.txt"]"
exit
