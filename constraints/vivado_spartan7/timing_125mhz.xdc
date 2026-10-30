## ============================================================================
## Xilinx Vivado Timing Constraints - 125 MHz Real-Time Target (1080p @ 60 fps)
## Target Device: 28 nm Xilinx Spartan-7 (xc7s50fgga484-2)
## ============================================================================
## 1920 x 1080 x 60 fps = 124,416,000 pixels/sec -> 125 MHz (8.000 ns period)

create_clock -period 8.000 -name system_clock -waveform {0.000 4.000} [get_ports clk]
