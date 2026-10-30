# ============================================================================
# Synopsys Design Compiler (dc_shell) 40 nm TSMC CMOS ASIC Synthesis Script
# Library: sc12mc_cln40g_base_rvt_c40_ss_typical_max_0p81v_125c.db
# Corner : Slow-Slow (0.81 V, 125 C)
#
# Reproduces Table 4.9 of the Thesis (500 MHz and 1 GHz targets):
#   dc_shell -f scripts/asic/run_dc_synthesis.tcl \
#            -x "set design_name mf_mn_encoder; set clk_period 1.0"
#
# Supported design_name values:
#   - sn_encoder          (SN Encoder Only)
#   - mf_sn_encoder_7sort (MF + SN Encoder, standard 7-sorter MF)
#   - mf_sn_encoder       (MF + SN Encoder, optimized 5-sorter MF)
#   - sn_decoder          (SN Decoder)
#   - mn_encoder          (MN Encoder Only, Single-Port RAM)
#   - mf_mn_encoder_7sort (MF + MN Encoder, standard 7-sorter MF)
#   - mf_mn_encoder       (MF + MN Encoder, optimized 5-sorter MF)
#   - hlb_mn_encoder      (HLB MN Encoder Only)
#   - mf_hlb_mn_encoder   (MF + HLB MN Encoder)
#   - mn_decoder          (MN Decoder)
# ============================================================================

if { ![info exists design_name] } { set design_name "mf_mn_encoder" }
if { ![info exists clk_period]  } { set clk_period  1.0 } ;# 2.0 = 500 MHz, 1.0 = 1 GHz
if { ![info exists target_lib]  } {
    set target_lib "sc12mc_cln40g_base_rvt_c40_ss_typical_max_0p81v_125c.db"
}

set repo_root [file normalize [file join [file dirname [info script]] "../.." ]]
set freq_tag  [expr {$clk_period == 1.0 ? "1GHz" : ($clk_period == 2.0 ? "500MHz" : "${clk_period}ns")}]
set out_dir   [file join $repo_root "build" "asic_40nm" "${design_name}_${freq_tag}"]
file mkdir $out_dir

set target_library [list $target_lib]
set link_library   [list "*" $target_lib]

define_design_lib USER -path [file join $out_dir "work"]

switch -exact -- $design_name {
    "sn_encoder" {
        set top_module "SN_encodingSystem_top"
        set rtl_files [list \
            [file join $repo_root "rtl/sn_encoder/src/SN_encodingSystem_top.v"] \
            [file join $repo_root "rtl/sn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/sn_encoder/src/SN_encoder.v"] \
            [file join $repo_root "rtl/sn_encoder/src/SN_packetizer.v"] \
        ]
    }
    "mf_sn_encoder_7sort" {
        set top_module "SN_encoding_system_top"
        set rtl_files [list \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoding_system_top.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/line_buffer.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/median_filter_7sorter.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoder.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_packetizer.v"] \
        ]
    }
    "mf_sn_encoder" {
        set top_module "SN_encoding_system_top"
        set rtl_files [list \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoding_system_top.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/line_buffer.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_encoder.v"] \
            [file join $repo_root "rtl/mf_sn_encoder/src/SN_packetizer.v"] \
        ]
    }
    "sn_decoder" {
        set top_module "SN_decoder"
        set rtl_files [list \
            [file join $repo_root "rtl/sn_decoder/src/SN_decoder.v"] \
        ]
    }
    "mn_encoder" {
        set top_module "MN_encoding_system_top_v1"
        set rtl_files [list \
            [file join $repo_root "rtl/mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mn_encoder/src/MN_packetizer_v2.v"] \
        ]
    }
    "mf_mn_encoder_7sort" {
        set top_module "MN_encoding_system_top_v1"
        set rtl_files [list \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/median_filter_7sorter.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
    }
    "mf_mn_encoder" {
        set top_module "MN_encoding_system_top_v1"
        set rtl_files [list \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_encoder_v1.v"] \
            [file join $repo_root "rtl/mf_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
    }
    "hlb_mn_encoder" {
        set top_module "HLB_MN_encoding_system_top_v1"
        set rtl_files [list \
            [file join $repo_root "rtl/hlb_mn_encoder/src/HLB_MN_encoding_system_top_v1.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/image_processor.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/HLB_MN_encoder_v1.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/hlb_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
    }
    "mf_hlb_mn_encoder" {
        set top_module "MF_HLB_MN_encoding_system_top"
        set rtl_files [list \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/MF_HLB_MN_encoding_system_top.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/image_processor_with_MF.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/single_port_RAM.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/shift_reg.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/median_filter.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/HLB_MN_encoder.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/HLB.v"] \
            [file join $repo_root "rtl/mf_hlb_mn_encoder/src/MN_packetizer_v2.v"] \
        ]
    }
    "mn_decoder" {
        set top_module "MN_decoder"
        set rtl_files [list \
            [file join $repo_root "rtl/mn_decoder/src/MN_decoder.v"] \
            [file join $repo_root "rtl/mn_decoder/src/MN_decoder_line_buffer.v"] \
        ]
    }
    default {
        error "Unknown design_name: $design_name"
    }
}

set clkPer $clk_period
analyze -format verilog -lib USER $rtl_files
elaborate $top_module -lib USER
current_design $top_module
link
uniquify

# Synthesis constraints (matching exact thesis flow)
set_max_area 0
set_wire_load_mode top
create_clock -name clk -period $clkPer [get_ports clk]

# Ultra compile with high timing effort
compile_ultra -no_autoungroup -timing_high_effort_script

# Reports & Gate-Level Netlist
check_design > [file join $out_dir "${design_name}_${freq_tag}_check_design.rpt"]
report_timing > [file join $out_dir "${design_name}_${freq_tag}_timing.rpt"]
report_area -hierarchy > [file join $out_dir "${design_name}_${freq_tag}_area.rpt"]
report_power -hierarchy > [file join $out_dir "${design_name}_${freq_tag}_power.rpt"]
write -f verilog -hier -output [file join $out_dir "${top_module}.vg"] $top_module

exit
