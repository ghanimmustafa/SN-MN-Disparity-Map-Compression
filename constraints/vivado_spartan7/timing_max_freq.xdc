## ============================================================================
## Xilinx Vivado Timing Constraints - Maximum Frequency Targets
## Target Device: 28 nm Xilinx Spartan-7 (xc7s50fgga484-2)
## Implementation Strategy: Performance_ExtraTimingOpt (with synth -retiming)
## ============================================================================
## Uncomment the constraint corresponding to the active top-level module, or use
## scripts/vivado/run_vivado_synth_impl.tcl which sets the exact period automatically.

## 1. SN Encoder Only (SN_encodingSystem_top) -> ~255 MHz post-route (3.819 ns target)
# create_clock -period 3.819 -name system_clock -waveform {0.000 1.905} [get_ports clk]

## 2. MF + SN Encoder (SN_encoding_system_top) -> ~183 MHz post-route (5.400 ns target)
# create_clock -period 5.400 -name system_clock -waveform {0.000 2.700} [get_ports clk]

## 3. SN Decoder (SN_decoder) -> ~194 MHz post-route (5.050 ns target)
# create_clock -period 5.050 -name system_clock -waveform {0.000 2.525} [get_ports clk]

## 4. MN Encoder Only (MN_encoding_system_top_v1) -> ~172 MHz post-route (5.800 ns target)
# create_clock -period 5.800 -name system_clock -waveform {0.000 2.900} [get_ports clk]

## 5. MF + MN Encoder (MN_encoding_system_top_v1) -> ~161 MHz post-route (6.000 ns target)
create_clock -period 6.000 -name system_clock -waveform {0.000 3.000} [get_ports clk]

## 6. HLB MN Encoder Only (HLB_MN_encoding_system_top_v1) -> ~173 MHz post-route (5.800 ns target)
# create_clock -period 5.800 -name system_clock -waveform {0.000 2.900} [get_ports clk]

## 7. MF + HLB MN Encoder (MF_HLB_MN_encoding_system_top) -> ~169 MHz post-route (5.900 ns target)
# create_clock -period 5.900 -name system_clock -waveform {0.000 2.950} [get_ports clk]

## 8. MN Decoder (MN_decoder) -> ~168 MHz post-route (5.700 ns target)
# create_clock -period 5.700 -name system_clock -waveform {0.000 2.850} [get_ports clk]
