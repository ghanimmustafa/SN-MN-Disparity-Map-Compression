# ============================================================================
# Vivado Batch Synthesis & Implementation Script (28 nm Xilinx Spartan-7)
# Part: xc7s50fgga484-2
# Strategy: Performance_ExtraTimingOpt (with -retiming enabled for MF designs)
#
# Usage:
#   vivado -mode batch -source scripts/vivado/run_vivado_synth_impl.tcl \
#          -tclargs <design_name> <clock_mode>
#
#   <design_name>: sn_encoder | mf_sn_encoder | sn_decoder |
#                  mn_encoder | mf_mn_encoder | hlb_mn_encoder |
#                  mf_hlb_mn_encoder | mn_decoder
#   <clock_mode> : 125mhz (default, 8.000 ns) | max_freq
# ============================================================================

set design_name "mf_mn_encoder"
set clock_mode  "125mhz"

if { $argc >= 1 } { set design_name [lindex $argv 0] }
if { $argc >= 2 } { set clock_mode  [lindex $argv 1] }

set part_name "xc7s50fgga484-2"
set repo_root [file normalize [file join [file dirname [info script]] "../.." ]]
set out_dir   [file join $repo_root "build" "vivado" "${design_name}_${clock_mode}"]
file mkdir $out_dir

# Map design_name to top module, RTL directory, retiming flag, and max_freq period (ns)
switch -exact -- $design_name {
    "sn_encoder" {
        set top_module "SN_encodingSystem_top"
        set src_files  [glob [file join $repo_root "rtl/sn_encoder/src/*.v"]]
        set use_retiming 0
        set max_period 3.819
    }
    "mf_sn_encoder" {
        set top_module "SN_encoding_system_top"
        set src_files  [list \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoding_system_top.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/line_buffer.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoder.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_packetizer.v"] \
        ]
        set use_retiming 1
        set max_period 5.400
    }
    "sn_decoder" {
        set top_module "SN_decoder"
        set src_files  [glob [file join $repo_root "rtl/sn_decoder/src/*.v"]]
        set use_retiming 0
        set max_period 5.050
    }
    "mn_encoder" {
        set top_module "MN_encoding_system_top_v1"
        set src_files  [list \
            [file join $repo_root "rtl/mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set use_retiming 0
        set max_period 5.800
    }
    "mf_mn_encoder" {
        set top_module "MN_encoding_system_top_v1"
        set src_files  [list \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set use_retiming 1
        set max_period 6.000
    }
    "hlb_mn_encoder" {
        set top_module "HLB_MN_encoding_system_top_v1"
        set src_files  [list \
            [file join $repo_root "rtl/hlb_mn_encoder/src/HLB_MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/HLB_MN_encoder_v1.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
        set use_retiming 0
        set max_period 5.800
    }
    "mf_hlb_mn_encoder" {
        set top_module "MF_HLB_MN_encoding_system_top"
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
        set use_retiming 1
        set max_period 5.900
    }
    "mn_decoder" {
        set top_module "MN_decoder"
        set src_files  [glob [file join $repo_root "rtl/mn_decoder/src/*.v"]]
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

puts "============================================================================"
puts "Running Vivado Flow for $design_name ($top_module)"
puts "Part: $part_name | Clock Period: ${clk_period} ns | Retiming: $use_retiming"
puts "============================================================================"

foreach f $src_files {
    read_verilog $f
}

# Apply in-memory timing constraint
create_clock -period $clk_period -name system_clock -waveform [list 0.000 $half_period] [get_ports clk]

# 1. Synthesis
if { $use_retiming } {
    synth_design -top $top_module -part $part_name -retiming
} else {
    synth_design -top $top_module -part $part_name
}
write_checkpoint -force [file join $out_dir "${design_name}_post_synth.dcp"]
report_utilization -file [file join $out_dir "${design_name}_synth_utilization.rpt"]
report_timing_summary -file [file join $out_dir "${design_name}_synth_timing.rpt"]

# 2. Implementation (Performance_ExtraTimingOpt strategy)
opt_design
power_opt_design
place_design -directive ExtraTimingOpt
phys_opt_design -directive Explore
route_design -directive NoTimingRelaxation

write_checkpoint -force [file join $out_dir "${design_name}_post_route.dcp"]

# 3. Post-Implementation Reports
report_utilization -file [file join $out_dir "${design_name}_impl_utilization.rpt"]
report_timing_summary -max_paths 10 -file [file join $out_dir "${design_name}_impl_timing_summary.rpt"]
report_power -file [file join $out_dir "${design_name}_impl_vectorless_power.rpt"]
report_drc -file [file join $out_dir "${design_name}_impl_drc.rpt"]

puts "Done! Reports and checkpoints written to: $out_dir"
exit
