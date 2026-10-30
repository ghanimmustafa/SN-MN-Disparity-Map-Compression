#!/usr/bin/env bash
# ============================================================================
# Batch Launcher for Xilinx Vivado Synthesis, Implementation & SAIF Power
# Target: 28 nm Xilinx Spartan-7 (xc7s50fgga484-2)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DESIGNS=(
    "sn_encoder"
    "mf_sn_encoder"
    "sn_decoder"
    "mn_encoder"
    "mf_mn_encoder"
    "hlb_mn_encoder"
    "mf_hlb_mn_encoder"
    "mn_decoder"
)

MODE="${1:-synth_impl}" # synth_impl | saif_power
CLOCK_MODES=("125mhz" "max_freq")

if ! command -v vivado >/dev/null 2>&1; then
    echo "ERROR: 'vivado' is not in PATH. Source your Xilinx Vivado settings64.sh first."
    exit 1
fi

for design in "${DESIGNS[@]}"; do
    for clk_mode in "${CLOCK_MODES[@]}"; do
        echo "--------------------------------------------------------------------"
        echo "Running Vivado ($MODE) for design=$design, clock_mode=$clk_mode"
        echo "--------------------------------------------------------------------"
        if [[ "$MODE" == "saif_power" ]]; then
            vivado -mode batch -source "$SCRIPT_DIR/run_vivado_saif_power.tcl" -tclargs "$design" "$clk_mode"
        else
            vivado -mode batch -source "$SCRIPT_DIR/run_vivado_synth_impl.tcl" -tclargs "$design" "$clk_mode"
        fi
    done
done
