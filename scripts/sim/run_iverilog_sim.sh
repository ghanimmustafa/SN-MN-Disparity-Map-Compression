#!/usr/bin/env bash
# ============================================================================
# Icarus Verilog (iverilog / vvp) Compilation & Simulation Verification Script
# Compiles and elaborates all 8 RTL architectures and their testbenches.
#
# Usage:
#   ./scripts/sim/run_iverilog_sim.sh [compile_only | run <design_name>]
# ============================================================================
set -euo pipefail

MODE="${1:-compile_only}"
TARGET_DESIGN="${2:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/iverilog"
mkdir -p "$BUILD_DIR"

compile_and_maybe_run() {
    local name="$1"
    local top_tb="$2"
    shift 2
    local files=("$@")

    echo "[iverilog] Compiling $name (top: $top_tb)..."
    iverilog -g2005 -o "$BUILD_DIR/${name}.vvp" -s "$top_tb" "${files[@]}"
    echo "  -> OK: $BUILD_DIR/${name}.vvp"

    if [[ "$MODE" == "run" ]] && { [[ "$TARGET_DESIGN" == "all" ]] || [[ "$TARGET_DESIGN" == "$name" ]]; }; then
        if [[ ! -f "$BUILD_DIR/input_disparity_map.txt" ]]; then
            echo "[prep] Generating 1080p hex test vectors in $BUILD_DIR..."
            python3 "$SCRIPT_DIR/prepare_1080p_vectors.py" "$BUILD_DIR"
        fi
        echo "[vvp] Running simulation for $name..."
        (cd "$BUILD_DIR" && vvp "${name}.vvp")
    fi
}

# 1. SN Encoder Only
compile_and_maybe_run "sn_encoder" "SN_encoder_only_tb" \
    "$REPO_ROOT/rtl/sn_encoder/src/SN_encodingSystem_top.v" \
    "$REPO_ROOT/rtl/sn_encoder/src/image_processor.v" \
    "$REPO_ROOT/rtl/sn_encoder/src/SN_encoder.v" \
    "$REPO_ROOT/rtl/sn_encoder/src/SN_packetizer.v" \
    "$REPO_ROOT/rtl/sn_encoder/tb/SN_encoder_only_tb.v"

# 2. MF + SN Encoder (Optimized 5-sorter MF)
compile_and_maybe_run "mf_sn_encoder" "SN_MF_encodingSys_tb" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_encoding_system_top.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/image_processor_with_MF.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/line_buffer.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/shift_reg.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/median_filter.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_encoder.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_packetizer.v" \
    "$REPO_ROOT/rtl/mf_sn_encoder/tb/SN_MF_encodingSys_tb.v"

# 3. SN Decoder
compile_and_maybe_run "sn_decoder" "SN_decoder_tb" \
    "$REPO_ROOT/rtl/sn_decoder/src/SN_decoder.v" \
    "$REPO_ROOT/rtl/sn_decoder/tb/SN_decoder_tb.v"

# 4. MN Encoder Only (Single-Port RAM)
compile_and_maybe_run "mn_encoder" "encoder_type2_tb" \
    "$REPO_ROOT/rtl/mn_encoder/src/MN_encoding_system_top_v1.v" \
    "$REPO_ROOT/rtl/mn_encoder/src/image_processor.v" \
    "$REPO_ROOT/rtl/mn_encoder/src/MN_encoder_v1.v" \
    "$REPO_ROOT/rtl/mn_encoder/src/single_port_RAM.v" \
    "$REPO_ROOT/rtl/mn_encoder/src/MN_packetizer_v2.v" \
    "$REPO_ROOT/rtl/mn_encoder/tb/MN_encoder_only_tb.v"

# 5. MF + MN Encoder (Single-Port RAM + Optimized 5-sorter MF)
compile_and_maybe_run "mf_mn_encoder" "MF_MN_Encoder_tb" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/image_processor_with_MF.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/single_port_RAM.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/shift_reg.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/median_filter.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_encoder_v1.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_packetizer_v2.v" \
    "$REPO_ROOT/rtl/mf_mn_encoder/tb/MF_MN_Encoder_tb.v"

# 6. HLB MN Encoder Only
compile_and_maybe_run "hlb_mn_encoder" "HLB_MN_Encoder_tb" \
    "$REPO_ROOT/rtl/hlb_mn_encoder/src/HLB_MN_encoding_system_top_v1.v" \
    "$REPO_ROOT/rtl/hlb_mn_encoder/src/image_processor.v" \
    "$REPO_ROOT/rtl/hlb_mn_encoder/src/HLB_MN_encoder_v1.v" \
    "$REPO_ROOT/rtl/hlb_mn_encoder/src/single_port_RAM.v" \
    "$REPO_ROOT/rtl/hlb_mn_encoder/src/MN_packetizer_v2.v" \
    "$REPO_ROOT/rtl/hlb_mn_encoder/tb/HLB_MN_Encoder_tb.v"

# 7. MF + HLB MN Encoder
compile_and_maybe_run "mf_hlb_mn_encoder" "MF_HLB_MN_Encoder_tb" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/MF_HLB_MN_encoding_system_top.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/image_processor_with_MF.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/single_port_RAM.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/shift_reg.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/median_filter.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/HLB_MN_encoder.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/HLB.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/src/MN_packetizer_v2.v" \
    "$REPO_ROOT/rtl/mf_hlb_mn_encoder/tb/MF_HLB_MN_Encoder_tb.v"

# 8. MN Decoder
compile_and_maybe_run "mn_decoder" "MN_decoder_tb" \
    "$REPO_ROOT/rtl/mn_decoder/src/MN_decoder.v" \
    "$REPO_ROOT/rtl/mn_decoder/src/MN_decoder_line_buffer.v" \
    "$REPO_ROOT/rtl/mn_decoder/tb/MN_decoder_tb.v"

echo "============================================================================"
echo "All 8 RTL architectures and testbenches compiled & elaborated successfully!"
echo "============================================================================"
