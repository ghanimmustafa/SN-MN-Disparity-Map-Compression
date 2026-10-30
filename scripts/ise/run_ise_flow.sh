#!/usr/bin/env bash
# ============================================================================
# Xilinx ISE 14.7 Command-Line Synthesis & Implementation Flow
# Targets (Table 4.8 of the Thesis):
#   - spartan6 (45 nm): xc6slx45-3-fgg484
#   - virtex4  (90 nm): xc4vlx15-12-sf363
#
# Design Goal & Strategy:
#   Timing Performance -> Performance without IOB Packing
#   - XST: -opt_mode Speed -opt_level 2 -register_balancing Yes -iob False
#   - MAP: -intstyle ise -ol high -xe n -register_duplication off -r 4 -ir off -pr off -lc off -power off
#   - PAR: -intstyle ise -ol high -xe n
#
# Usage:
#   ./scripts/ise/run_ise_flow.sh <design_name> <fpga_target> [clk_period_ns]
#
# Example:
#   ./scripts/ise/run_ise_flow.sh mf_mn_encoder spartan6 7.2
#   ./scripts/ise/run_ise_flow.sh mf_sn_encoder virtex4 6.0
# ============================================================================
set -euo pipefail

DESIGN_NAME="${1:-mf_mn_encoder}"
FPGA_TARGET="${2:-spartan6}" # spartan6 | virtex4
CLK_PERIOD="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

case "$FPGA_TARGET" in
    spartan6|45nm)
        PART="xc6slx45-3-fgg484"
        DEFAULT_PERIOD="6.600"
        MAP_EXTRA_FLAGS="-r 4 -lc off -power off"
        PAR_EXTRA_FLAGS=""
        ;;
    virtex4|90nm)
        PART="xc4vlx15-12-sf363"
        DEFAULT_PERIOD="6.000"
        MAP_EXTRA_FLAGS=""
        PAR_EXTRA_FLAGS=""
        ;;
    *)
        echo "Unknown FPGA_TARGET: $FPGA_TARGET (expected 'spartan6' or 'virtex4')"
        exit 1
        ;;
esac

if [[ -z "$CLK_PERIOD" ]]; then
    CLK_PERIOD="$DEFAULT_PERIOD"
fi

case "$DESIGN_NAME" in
    sn_encoder)
        TOP_MODULE="SN_encodingSystem_top"
        RTL_FILES=(
            "$REPO_ROOT/rtl/sn_encoder/src/SN_encodingSystem_top.v"
            "$REPO_ROOT/rtl/sn_encoder/src/image_processor.v"
            "$REPO_ROOT/rtl/sn_encoder/src/SN_encoder.v"
            "$REPO_ROOT/rtl/sn_encoder/src/SN_packetizer.v"
        )
        ;;
    mf_sn_encoder)
        TOP_MODULE="SN_encoding_system_top"
        RTL_FILES=(
            "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_encoding_system_top.v"
            "$REPO_ROOT/rtl/mf_sn_encoder/src/image_processor_with_MF.v"
            "$REPO_ROOT/rtl/mf_sn_encoder/src/line_buffer.v"
            "$REPO_ROOT/rtl/mf_sn_encoder/src/shift_reg.v"
            "$REPO_ROOT/rtl/mf_sn_encoder/src/median_filter.v"
            "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_encoder.v"
            "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_packetizer.v"
        )
        ;;
    sn_decoder)
        TOP_MODULE="SN_decoder"
        RTL_FILES=("$REPO_ROOT/rtl/sn_decoder/src/SN_decoder.v")
        ;;
    mn_encoder)
        TOP_MODULE="MN_encoding_system_top_v1"
        RTL_FILES=(
            "$REPO_ROOT/rtl/mn_encoder/src/MN_encoding_system_top_v1.v"
            "$REPO_ROOT/rtl/mn_encoder/src/image_processor.v"
            "$REPO_ROOT/rtl/mn_encoder/src/MN_encoder_v1.v"
            "$REPO_ROOT/rtl/mn_encoder/src/single_port_RAM.v"
            "$REPO_ROOT/rtl/mn_encoder/src/MN_packetizer_v2.v"
        )
        ;;
    mf_mn_encoder)
        TOP_MODULE="MN_encoding_system_top_v1"
        RTL_FILES=(
            "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v"
            "$REPO_ROOT/rtl/mf_mn_encoder/src/image_processor_with_MF.v"
            "$REPO_ROOT/rtl/mf_mn_encoder/src/single_port_RAM.v"
            "$REPO_ROOT/rtl/mf_mn_encoder/src/shift_reg.v"
            "$REPO_ROOT/rtl/mf_mn_encoder/src/median_filter.v"
            "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_encoder_v1.v"
            "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_packetizer_v2.v"
        )
        ;;
    hlb_mn_encoder)
        TOP_MODULE="HLB_MN_encoding_system_top_v1"
        RTL_FILES=(
            "$REPO_ROOT/rtl/hlb_mn_encoder/src/HLB_MN_encoding_system_top_v1.v"
            "$REPO_ROOT/rtl/hlb_mn_encoder/src/image_processor.v"
            "$REPO_ROOT/rtl/hlb_mn_encoder/src/HLB_MN_encoder_v1.v"
            "$REPO_ROOT/rtl/hlb_mn_encoder/src/single_port_RAM.v"
            "$REPO_ROOT/rtl/hlb_mn_encoder/src/MN_packetizer_v2.v"
        )
        ;;
    mf_hlb_mn_encoder)
        TOP_MODULE="MF_HLB_MN_encoding_system_top"
        RTL_FILES=(
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/MF_HLB_MN_encoding_system_top.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/image_processor_with_MF.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/single_port_RAM.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/shift_reg.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/median_filter.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/HLB_MN_encoder.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/HLB.v"
            "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/MN_packetizer_v2.v"
        )
        ;;
    mn_decoder)
        TOP_MODULE="MN_decoder"
        RTL_FILES=(
            "$REPO_ROOT/rtl/mn_decoder/src/MN_decoder.v"
            "$REPO_ROOT/rtl/mn_decoder/src/MN_decoder_line_buffer.v"
        )
        ;;
    *)
        echo "Unknown DESIGN_NAME: $DESIGN_NAME"
        exit 1
        ;;
esac

WORK_DIR="$REPO_ROOT/build/ise/${DESIGN_NAME}_${FPGA_TARGET}"
mkdir -p "$WORK_DIR/xst/projnav.tmp"
cd "$WORK_DIR"

# 1. Generate .prj file
PRJ_FILE="$WORK_DIR/${TOP_MODULE}.prj"
: > "$PRJ_FILE"
for vf in "${RTL_FILES[@]}"; do
    echo "verilog work \"$vf\"" >> "$PRJ_FILE"
done

# 2. Generate .ucf file
UCF_FILE="$WORK_DIR/${TOP_MODULE}.ucf"
cat > "$UCF_FILE" <<EOF
NET "clk" TNM_NET = "clk";
TIMESPEC "TS_clk" = PERIOD "clk" ${CLK_PERIOD} ns HIGH 50%;
EOF

# 3. Generate .xst file (Performance without IOB Packing strategy)
XST_FILE="$WORK_DIR/${TOP_MODULE}.xst"
cat > "$XST_FILE" <<EOF
set -tmpdir "xst/projnav.tmp"
set -xsthdpdir "xst"
run
-ifn ${TOP_MODULE}.prj
-ofn ${TOP_MODULE}
-ofmt NGC
-p ${PART}
-top ${TOP_MODULE}
-opt_mode Speed
-opt_level 2
-iuc NO
-keep_hierarchy No
-netlist_hierarchy As_Optimized
-rtlview Yes
-glob_opt AllClockNets
-read_cores YES
-write_timing_constraints NO
-cross_clock_analysis NO
-hierarchy_separator /
-bus_delimiter <>
-case Maintain
-slice_utilization_ratio 100
-bram_utilization_ratio 100
-fsm_extract YES -fsm_encoding Auto
-safe_implementation No
-fsm_style LUT
-ram_extract Yes
-ram_style Auto
-rom_extract Yes
-shreg_extract YES
-rom_style Auto
-auto_bram_packing NO
-resource_sharing YES
-async_to_sync NO
-shreg_min_size 2
-auto_bram_cascade_ratio 100
-bufg 16
-register_duplication YES
-register_balancing Yes
-move_first_stage YES
-move_last_stage YES
-optimize_primitives NO
-use_clock_enable Auto
-use_sync_set Auto
-use_sync_reset Auto
-iob False
-equivalent_register_removal YES
-slice_utilization_ratio_maxmargin 5
EOF

echo "============================================================================"
echo "Running Xilinx ISE 14.7 Flow: $DESIGN_NAME ($TOP_MODULE) on $PART (${CLK_PERIOD} ns)"
echo "============================================================================"

if ! command -v xst >/dev/null 2>&1; then
    echo "Generated ISE project files (.prj, .xst, .ucf) in: $WORK_DIR"
    echo "NOTE: 'xst' is not in PATH. Source Xilinx ISE settings64.sh to execute xst/ngdbuild/map/par/trce."
    exit 0
fi

xst -intstyle ise -ifn "$XST_FILE" -ofn "${TOP_MODULE}.syr"
ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc "$UCF_FILE" -p "$PART" "${TOP_MODULE}.ngc" "${TOP_MODULE}.ngd"
# shellcheck disable=SC2086
map -intstyle ise -p "$PART" -w -logic_opt off -ol high -xe n -t 1 -xt 0 -register_duplication off $MAP_EXTRA_FLAGS -ir off -pr off -o "${TOP_MODULE}_map.ncd" "${TOP_MODULE}.ngd" "${TOP_MODULE}.pcf"
# shellcheck disable=SC2086
par -w -intstyle ise -ol high -xe n $PAR_EXTRA_FLAGS "${TOP_MODULE}_map.ncd" "${TOP_MODULE}.ncd" "${TOP_MODULE}.pcf"
trce -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml "${TOP_MODULE}.twx" "${TOP_MODULE}.ncd" -o "${TOP_MODULE}.twr" "${TOP_MODULE}.pcf" -ucf "$UCF_FILE"

echo "ISE Flow complete! Reports written to: $WORK_DIR"
