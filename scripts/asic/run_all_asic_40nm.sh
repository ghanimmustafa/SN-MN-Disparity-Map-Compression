#!/usr/bin/env bash
# ============================================================================
# Batch Launcher for 40 nm TSMC CMOS ASIC Synthesis (Table 4.9 of the Thesis)
# Runs Synopsys Design Compiler (dc_shell) at 500 MHz (2.0 ns) and 1 GHz (1.0 ns)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DESIGNS=(
    "sn_encoder"
    "mf_sn_encoder_7sort"
    "mf_sn_encoder"
    "sn_decoder"
    "mn_encoder"
    "mf_mn_encoder_7sort"
    "mf_mn_encoder"
    "hlb_mn_encoder"
    "mf_hlb_mn_encoder"
    "mn_decoder"
)

PERIODS=("2.0" "1.0") # 2.0 ns = 500 MHz, 1.0 ns = 1 GHz

if ! command -v dc_shell >/dev/null 2>&1; then
    echo "ERROR: 'dc_shell' is not in PATH. Source your Synopsys Design Compiler environment first."
    echo "Pre-generated reference synthesis logs are available in: results/asic_40nm_reports/"
    exit 1
fi

# 1. Synthesize 2-input NAND reference gate for Gate Equivalent (GE) calculation
dc_shell -f "$SCRIPT_DIR/run_nand2_ref.tcl"

# 2. Synthesize all architectures at 500 MHz and 1 GHz
for design in "${DESIGNS[@]}"; do
    for clk_per in "${PERIODS[@]}"; do
        echo "--------------------------------------------------------------------"
        echo "Running 40nm ASIC Synthesis: design=$design, clk_period=${clk_per}ns"
        echo "--------------------------------------------------------------------"
        dc_shell -f "$SCRIPT_DIR/run_dc_synthesis.tcl" -x "set design_name $design; set clk_period $clk_per"
    done
done
