#!/usr/bin/env bash
# ============================================================================
# Batch Launcher for All Xilinx ISE 14.7 Experiments (Table 4.8 of the Thesis)
# Runs both 45 nm Spartan-6 (xc6slx45-3-fgg484) and 90 nm Virtex-4 (xc4vlx15-12-sf363)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 45 nm Spartan-6 runs
"$SCRIPT_DIR/run_ise_flow.sh" sn_encoder        spartan6 5.000
"$SCRIPT_DIR/run_ise_flow.sh" mf_sn_encoder     spartan6 6.800
"$SCRIPT_DIR/run_ise_flow.sh" mf_mn_encoder     spartan6 7.200
"$SCRIPT_DIR/run_ise_flow.sh" hlb_mn_encoder    spartan6 6.200
"$SCRIPT_DIR/run_ise_flow.sh" mf_hlb_mn_encoder spartan6 6.600

# 90 nm Virtex-4 runs
"$SCRIPT_DIR/run_ise_flow.sh" sn_encoder        virtex4  4.600
"$SCRIPT_DIR/run_ise_flow.sh" mf_sn_encoder     virtex4  6.000
"$SCRIPT_DIR/run_ise_flow.sh" mf_mn_encoder     virtex4  6.000
