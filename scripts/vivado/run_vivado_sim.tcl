# ============================================================================
# Vivado Behavioral Simulation Script (xsim)
#
# Usage:
#   vivado -mode batch -source scripts/vivado/run_vivado_sim.tcl \
#          -tclargs <design_name>
# ============================================================================

set design_name "mf_mn_encoder"
if { $argc >= 1 } { set design_name [lindex $argv 0] }

set part_name "xc7s50fgga484-2"
set repo_root [file normalize [file join [file dirname [info script]] "../.." ]]
set proj_dir  [file join $repo_root "build" "vivado_sim" $design_name]
file mkdir $proj_dir

switch -exact -- $design_name {
    "sn_encoder" {
        set top_module "SN_encodingSystem_top"
        set tb_module  "SN_encoder_only_tb"
        set src_files  [glob [file join $repo_root "rtl/sn_encoder/src/*.v"]]
        set tb_file    [file join $repo_root "rtl/sn_encoder/tb/SN_encoder_only_tb.v"]
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
    }
    "sn_decoder" {
        set top_module "SN_decoder"
        set tb_module  "SN_decoder_tb"
        set src_files  [glob [file join $repo_root "rtl/sn_decoder/src/*.v"]]
        set tb_file    [file join $repo_root "rtl/sn_decoder/tb/SN_decoder_tb.v"]
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
    }
    "mn_decoder" {
        set top_module "MN_decoder"
        set tb_module  "MN_decoder_tb"
        set src_files  [glob [file join $repo_root "rtl/mn_decoder/src/*.v"]]
        set tb_file    [file join $repo_root "rtl/mn_decoder/tb/MN_decoder_tb.v"]
    }
    default {
        error "Unknown design_name: $design_name"
    }
}

create_project -force $design_name $proj_dir -part $part_name
add_files -fileset sources_1 $src_files
set_property top $top_module [current_fileset]
add_files -fileset sim_1 $tb_file
set_property top $tb_module [get_filesets sim_1]

launch_simulation -mode behavioral
run all
close_sim
exit
