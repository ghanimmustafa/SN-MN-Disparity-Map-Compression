#!/usr/bin/env bash
# ============================================================================
# End-to-End Behavioral Simulation & Bit-Accurate Verification Suite
# Simulates all 8 RTL architectures in Icarus Verilog (iverilog / vvp) and
# verifies 100% lossless bit-accurate reconstruction (0 pixel mismatches):
#   1. sn_encoder        -> sn_decoder    (Unfiltered SN Encoding & Decoding)
#   2. mf_sn_encoder     -> sn_decoder    (3x3 Median Filter + SN Encoding & Decoding)
#   3. mn_encoder        -> mn_decoder    (Unfiltered MN Encoding & Decoding)
#   4. mf_mn_encoder     -> mn_decoder    (3x3 Median Filter + MN Encoding & Decoding)
#   5. hlb_mn_encoder    -> SW HLB-MN Dec (Unfiltered HLB-MN Encoding & Decoding)
#   6. mf_hlb_mn_encoder -> SW HLB-MN Dec (3x3 Median Filter + HLB-MN Encoding & Decoding)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK_DIR="$REPO_ROOT/build/iverilog_e2e"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

WIDTH=32
HEIGHT=16

# 1. Generate synthetic 32x16 input disparity map and golden 3x3 median-filtered map (14x32)
python3 - "$WORK_DIR" "$WIDTH" "$HEIGHT" << 'PYEOF'
import sys, os
import numpy as np

work_dir = sys.argv[1]
W, H = int(sys.argv[2]), int(sys.argv[3])

# Build a synthetic disparity map with horizontal, vertical, diagonal, and varying regions
img = np.zeros((H, W), dtype=np.uint8)
for r in range(H):
    for c in range(W):
        if c < 8:
            img[r, c] = 40 + (r // 2)
        elif c < 16:
            img[r, c] = 80 + ((r + c) // 3)
        elif c < 24:
            img[r, c] = 120 + ((r - (c % 2)) & 0x1F)
        else:
            img[r, c] = (r * 7 + c * 3 + (r % 3)) & 0xFF

# Hardware-matching 3x3 median filter (my_median_filter.m with only_filtered=true):
# - Keeps first and last columns unfiltered (line_header and line_end in RTL)
# - Clips first and last rows -> output height is H - 2
mf_img = np.zeros((H, W), dtype=np.uint8)
for r in range(H):
    for c in range(W):
        r0, r1 = max(0, r - 1), min(H - 1, r + 1)
        c0, c1 = max(0, c - 1), min(W - 1, c + 1)
        window = img[r0:r1+1, c0:c1+1].flatten()
        mf_img[r, c] = int(np.median(window))
mf_img[0, :] = img[0, :]
mf_img[-1, :] = img[-1, :]
mf_img[:, 0] = img[:, 0]
mf_img[:, -1] = img[:, -1]
mf_cropped = mf_img[1:-1, :]

with open(os.path.join(work_dir, "input_unfiltered.hex"), "w") as f:
    for p in img.flatten():
        f.write(f"{int(p):02x}\n")

with open(os.path.join(work_dir, "golden_filtered.hex"), "w") as f:
    for p in mf_cropped.flatten():
        f.write(f"{int(p):02x}\n")

print(f"[1/4] Generated test frame ({W}x{H} = {W*H} pixels) and golden 3x3 MF frame ({W}x{H-2} = {W*(H-2)} pixels).")
PYEOF

# 2. Generate parameterized Verilog testbenches for encoders and decoders
cat > "$WORK_DIR/tb_all_e2e.v" << 'VEOF'
`timescale 1ns / 1ps

module tb_sn_enc;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, vsynch_in = 0, hsynch_in = 0, data_enable_in = 0;
    reg [7:0] data_in = 0;
    wire [8:0] encoded_data;
    wire valid_encoded, valid_word, compressed_flag_r, overflow_flag, last_packet, hsynch_out, vsynch_out, update_frame;
    wire [127:0] memory_word;
    wire [11:0] column_cnt_r;

    SN_encodingSystem_top #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn),
        .vsynch_in(vsynch_in), .hsynch_in(hsynch_in), .data_enable_in(data_enable_in),
        .data_in(data_in), .encoded_data(encoded_data), .valid_encoded(valid_encoded),
        .compressed_flag_r(compressed_flag_r), .overflow_flag(overflow_flag),
        .memory_word(memory_word), .valid_word(valid_word), .last_packet(last_packet),
        .column_cnt_r(column_cnt_r), .hsynch_out(hsynch_out), .vsynch_out(vsynch_out),
        .update_frame(update_frame)
    );

    reg [7:0] input_pixels [0:TOTAL_PIXELS-1];
    integer i, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        $readmemh("input_unfiltered.hex", input_pixels);
        fd = $fopen("packets_sn.txt", "w");
        #90; rstn = 1; data_enable_in = 1;
        for (i = 0; i <= TOTAL_PIXELS + 20; i = i + 1) begin
            data_in = (i < TOTAL_PIXELS) ? input_pixels[i] : 8'd0;
            if (i > 0 && valid_word) $fdisplay(fd, "%b", memory_word);
            hsynch_in = (column_cnt_r == (WIDTH - 1) && i > 0) ? 1'b1 : 1'b0;
            vsynch_in = (i == TOTAL_PIXELS - 1) ? 1'b1 : 1'b0;
            if (i == TOTAL_PIXELS) data_enable_in = 0;
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_mf_sn_enc;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, vsynch_in = 0, hsynch_in = 0, data_enable_in = 0;
    reg [7:0] data_in = 0;
    wire [8:0] encoded_data;
    wire valid_encoded, valid_word, compressed_flag_r, overflow_flag, last_packet, hsynch_out, vsynch_out, update_frame;
    wire [127:0] memory_word;
    wire [10:0] column_cnt_r;

    SN_encoding_system_top #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn),
        .vsynch_in(vsynch_in), .hsynch_in(hsynch_in), .data_enable_in(data_enable_in),
        .data_in(data_in), .encoded_data(encoded_data), .valid_encoded(valid_encoded),
        .compressed_flag_r(compressed_flag_r), .overflow_flag(overflow_flag),
        .memory_word(memory_word), .valid_word(valid_word), .last_packet(last_packet),
        .column_cnt_r(column_cnt_r), .hsynch_out(hsynch_out), .vsynch_out(vsynch_out),
        .update_frame(update_frame)
    );

    reg [7:0] input_pixels [0:TOTAL_PIXELS-1];
    integer i, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        $readmemh("input_unfiltered.hex", input_pixels);
        fd = $fopen("packets_mf_sn.txt", "w");
        #90; rstn = 1; data_enable_in = 1;
        for (i = 0; i <= TOTAL_PIXELS + 50; i = i + 1) begin
            data_in = (i < TOTAL_PIXELS) ? input_pixels[i] : 8'd0;
            if (i > 0 && valid_word) $fdisplay(fd, "%b", memory_word);
            hsynch_in = (column_cnt_r == (WIDTH - 1) && i > 0) ? 1'b1 : 1'b0;
            vsynch_in = (i == TOTAL_PIXELS - 1) ? 1'b1 : 1'b0;
            if (i == TOTAL_PIXELS) data_enable_in = 0;
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_sn_dec;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter TOTAL_MW = 64;
    parameter IN_FILE = "packets_sn.txt";
    parameter OUT_FILE = "decoded_sn_hw.hex";
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, valid_in = 0;
    reg [127:0] memory_word = 0;
    wire valid_dec, packet_decoded, hsynch_dec, vsynch_dec;
    wire [7:0] decoder_out;

    SN_decoder #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn), .valid_in(valid_in),
        .memory_word(memory_word), .hsynch_dec(hsynch_dec), .vsynch_dec(vsynch_dec),
        .decoder_out(decoder_out), .valid_dec(valid_dec), .packet_decoded(packet_decoded)
    );

    reg [127:0] input_mw [0:TOTAL_MW-1];
    integer i, mw_counter, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        for (i = 0; i < TOTAL_MW; i = i + 1) input_mw[i] = 128'd0;
        $readmemb(IN_FILE, input_mw);
        fd = $fopen(OUT_FILE, "w");
        #90; rstn = 1; memory_word = input_mw[0]; mw_counter = 1;
        #CLOCK_PERIOD;
        for (i = 0; i < TOTAL_PIXELS * 4; i = i + 1) begin
            valid_in = (i == 0) ? 1'b1 : 1'b0;
            if (packet_decoded) begin
                memory_word = input_mw[mw_counter];
                mw_counter = mw_counter + 1;
                valid_in = 1'b1;
            end
            if (valid_dec) $fdisplay(fd, "%02x", decoder_out);
            if (vsynch_dec) begin
                #CLOCK_PERIOD;
                $fclose(fd);
                $finish;
            end
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_mn_enc;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, vsynch_in = 0, hsynch_in = 0, data_enable_in = 0;
    reg [7:0] data_in = 0;
    wire [9:0] encoded_data;
    wire valid_encoded, valid_word, compressed_flag_r, overflow_flag, last_packet, hsynch_out, vsynch_out, update_frame;
    wire [127:0] valid_memory_word;
    wire [10:0] column_cnt_r, line_cnt_r;

    MN_encoding_system_top_v1 #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn),
        .vsynch_in(vsynch_in), .hsynch_in(hsynch_in), .data_enable_in(data_enable_in),
        .data_in(data_in), .encoded_data(encoded_data), .valid_encoded(valid_encoded),
        .compressed_flag_r(compressed_flag_r), .column_cnt_r(column_cnt_r),
        .hsynch_out(hsynch_out), .vsynch_out(vsynch_out), .line_cnt_r(line_cnt_r),
        .valid_memory_word(valid_memory_word), .valid_word(valid_word),
        .overflow_flag(overflow_flag), .last_packet(last_packet), .update_frame(update_frame)
    );

    reg [7:0] input_pixels [0:TOTAL_PIXELS-1];
    integer i, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        $readmemh("input_unfiltered.hex", input_pixels);
        fd = $fopen("packets_mn.txt", "w");
        #90; rstn = 1; data_enable_in = 1;
        for (i = 0; i <= TOTAL_PIXELS + 30; i = i + 1) begin
            data_in = (i < TOTAL_PIXELS) ? input_pixels[i] : 8'd0;
            if (i > 0 && valid_word) $fdisplay(fd, "%b", valid_memory_word);
            hsynch_in = (column_cnt_r == (WIDTH - 1) && i > 0) ? 1'b1 : 1'b0;
            vsynch_in = (i == TOTAL_PIXELS - 1) ? 1'b1 : 1'b0;
            if (i == TOTAL_PIXELS) data_enable_in = 0;
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_mf_mn_enc;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, vsynch_in = 0, hsynch_in = 0, data_enable_in = 0;
    reg [7:0] data_in = 0;
    wire [9:0] encoded_data;
    wire valid_encoded, valid_word, compressed_flag_r, overflow_flag, last_packet, hsynch_out, vsynch_out, update_frame;
    wire [127:0] valid_memory_word;
    wire [10:0] column_cnt_r, line_cnt_r;

    MN_encoding_system_top_v1 #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn),
        .vsynch_in(vsynch_in), .hsynch_in(hsynch_in), .data_enable_in(data_enable_in),
        .data_in(data_in), .encoded_data(encoded_data), .valid_encoded(valid_encoded),
        .compressed_flag_r(compressed_flag_r), .column_cnt_r(column_cnt_r),
        .hsynch_out(hsynch_out), .vsynch_out(vsynch_out), .line_cnt_r(line_cnt_r),
        .valid_memory_word(valid_memory_word), .valid_word(valid_word),
        .overflow_flag(overflow_flag), .last_packet(last_packet), .update_frame(update_frame)
    );

    reg [7:0] input_pixels [0:TOTAL_PIXELS-1];
    integer i, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        $readmemh("input_unfiltered.hex", input_pixels);
        fd = $fopen("packets_mf_mn.txt", "w");
        #90; rstn = 1; data_enable_in = 1;
        for (i = 0; i <= TOTAL_PIXELS + 50; i = i + 1) begin
            data_in = (i < TOTAL_PIXELS) ? input_pixels[i] : 8'd0;
            if (i > 0 && valid_word) $fdisplay(fd, "%b", valid_memory_word);
            hsynch_in = (column_cnt_r == (WIDTH - 1) && i > 0) ? 1'b1 : 1'b0;
            vsynch_in = (i == TOTAL_PIXELS - 1) ? 1'b1 : 1'b0;
            if (i == TOTAL_PIXELS) data_enable_in = 0;
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_mn_dec;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter TOTAL_MW = 64;
    parameter IN_FILE = "packets_mn.txt";
    parameter OUT_FILE = "decoded_mn_hw.hex";
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, valid_in = 0;
    reg [127:0] memory_word = 0;
    wire valid_dec, packet_decoded, hsynch_dec, vsynch_dec;
    wire [7:0] decoder_out;

    MN_decoder #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn), .valid_in(valid_in),
        .memory_word(memory_word), .hsynch_dec(hsynch_dec), .vsynch_dec(vsynch_dec),
        .decoder_out(decoder_out), .valid_dec(valid_dec), .packet_decoded(packet_decoded)
    );

    reg [127:0] input_mw [0:TOTAL_MW-1];
    integer i, mw_counter, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        for (i = 0; i < TOTAL_MW; i = i + 1) input_mw[i] = 128'd0;
        $readmemb(IN_FILE, input_mw);
        fd = $fopen(OUT_FILE, "w");
        #90; rstn = 1; memory_word = input_mw[0]; mw_counter = 1;
        #CLOCK_PERIOD;
        for (i = 0; i < TOTAL_PIXELS * 4; i = i + 1) begin
            valid_in = (i == 0) ? 1'b1 : 1'b0;
            if (packet_decoded) begin
                memory_word = input_mw[mw_counter];
                mw_counter = mw_counter + 1;
                valid_in = 1'b1;
            end
            if (valid_dec && !vsynch_dec) $fdisplay(fd, "%02x", decoder_out);
            if (vsynch_dec) begin
                #CLOCK_PERIOD;
                $fclose(fd);
                $finish;
            end
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_hlb_mn_enc;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, vsynch_in = 0, hsynch_in = 0, data_enable_in = 0;
    reg [7:0] data_in = 0;
    wire [9:0] encoded_data;
    wire valid_encoded, valid_word, compressed_flag_r, overflow_flag, last_packet, hsynch_out, vsynch_out, update_frame;
    wire [127:0] valid_memory_word;
    wire [10:0] column_cnt_r, line_cnt_r;

    HLB_MN_encoding_system_top_v1 #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn),
        .vsynch_in(vsynch_in), .hsynch_in(hsynch_in), .data_enable_in(data_enable_in),
        .data_in(data_in), .encoded_data(encoded_data), .valid_encoded(valid_encoded),
        .compressed_flag_r(compressed_flag_r), .column_cnt_r(column_cnt_r),
        .hsynch_out(hsynch_out), .vsynch_out(vsynch_out), .line_cnt_r(line_cnt_r),
        .valid_memory_word(valid_memory_word), .valid_word(valid_word),
        .overflow_flag(overflow_flag), .last_packet(last_packet), .update_frame(update_frame)
    );

    reg [7:0] input_pixels [0:TOTAL_PIXELS-1];
    integer i, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        $readmemh("input_unfiltered.hex", input_pixels);
        fd = $fopen("packets_hlb_mn.txt", "w");
        #90; rstn = 1; data_enable_in = 1;
        for (i = 0; i <= TOTAL_PIXELS + 30; i = i + 1) begin
            data_in = (i < TOTAL_PIXELS) ? input_pixels[i] : 8'd0;
            if (i > 0 && valid_word) $fdisplay(fd, "%b", valid_memory_word);
            hsynch_in = (column_cnt_r == (WIDTH - 1) && i > 0) ? 1'b1 : 1'b0;
            vsynch_in = (i == TOTAL_PIXELS - 1) ? 1'b1 : 1'b0;
            if (i == TOTAL_PIXELS) data_enable_in = 0;
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule

module tb_mf_hlb_mn_enc;
    parameter WIDTH = 32;
    parameter HEIGHT = 16;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLOCK_PERIOD = 8;

    reg clk = 0, clk_en = 1, rstn = 0, vsynch_in = 0, hsynch_in = 0, data_enable_in = 0;
    reg [7:0] data_in = 0;
    wire [9:0] encoded_data;
    wire valid_encoded, valid_word, compressed_flag_r, overflow_flag, last_packet, hsynch_out, vsynch_out, update_frame;
    wire [127:0] valid_memory_word;
    wire [10:0] column_cnt_r, line_cnt_r;

    MF_HLB_MN_encoding_system_top #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) uut (
        .clk(clk), .clk_en(clk_en), .rstn(rstn),
        .vsynch_in(vsynch_in), .hsynch_in(hsynch_in), .data_enable_in(data_enable_in),
        .data_in(data_in), .encoded_data(encoded_data), .valid_encoded(valid_encoded),
        .compressed_flag_r(compressed_flag_r), .column_cnt_r(column_cnt_r),
        .hsynch_out(hsynch_out), .vsynch_out(vsynch_out), .line_cnt_r(line_cnt_r),
        .valid_memory_word(valid_memory_word), .valid_word(valid_word),
        .overflow_flag(overflow_flag), .last_packet(last_packet), .update_frame(update_frame)
    );

    reg [7:0] input_pixels [0:TOTAL_PIXELS-1];
    integer i, fd;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
        $readmemh("input_unfiltered.hex", input_pixels);
        fd = $fopen("packets_mf_hlb_mn.txt", "w");
        #90; rstn = 1; data_enable_in = 1;
        for (i = 0; i <= TOTAL_PIXELS + 50; i = i + 1) begin
            data_in = (i < TOTAL_PIXELS) ? input_pixels[i] : 8'd0;
            if (i > 0 && valid_word) $fdisplay(fd, "%b", valid_memory_word);
            hsynch_in = (column_cnt_r == (WIDTH - 1) && i > 0) ? 1'b1 : 1'b0;
            vsynch_in = (i == TOTAL_PIXELS - 1) ? 1'b1 : 1'b0;
            if (i == TOTAL_PIXELS) data_enable_in = 0;
            #CLOCK_PERIOD;
        end
        $fclose(fd);
        $finish;
    end
endmodule
VEOF

echo "[2/4] Compiling and running all 6 Encoder RTL pipelines in Icarus Verilog..."
(
    cd "$WORK_DIR"
    iverilog -g2005 -s tb_sn_enc -o sim_sn_enc.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/sn_encoder/src/*.v && vvp sim_sn_enc.vvp >/dev/null
    iverilog -g2005 -s tb_mf_sn_enc -o sim_mf_sn_enc.vvp "$WORK_DIR/tb_all_e2e.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_encoding_system_top.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/image_processor_with_MF.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/line_buffer.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/shift_reg.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/median_filter.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_encoder.v" \
        "$REPO_ROOT/rtl/mf_sn_encoder/src/SN_packetizer.v" && vvp sim_mf_sn_enc.vvp >/dev/null
    iverilog -g2005 -s tb_mn_enc -o sim_mn_enc.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/mn_encoder/src/*.v && vvp sim_mn_enc.vvp >/dev/null
    iverilog -g2005 -s tb_mf_mn_enc -o sim_mf_mn_enc.vvp "$WORK_DIR/tb_all_e2e.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_encoding_system_top_v1.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/image_processor_with_MF.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/single_port_RAM.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/shift_reg.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/median_filter.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_encoder_v1.v" \
        "$REPO_ROOT/rtl/mf_mn_encoder/src/MN_packetizer_v2.v" && vvp sim_mf_mn_enc.vvp >/dev/null
    iverilog -g2005 -s tb_hlb_mn_enc -o sim_hlb_mn_enc.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/hlb_mn_encoder/src/*.v && vvp sim_hlb_mn_enc.vvp >/dev/null
    iverilog -g2005 -s tb_mf_hlb_mn_enc -o sim_mf_hlb_mn_enc.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/mf_hlb_mn_encoder/src/*.v && vvp sim_mf_hlb_mn_enc.vvp >/dev/null
)

echo "[3/4] Compiling and running SN & MN Decoder RTL pipelines in Icarus Verilog..."
(
    cd "$WORK_DIR"
    # SN Decoder on unfiltered SN packets (32x16)
    iverilog -g2005 -s tb_sn_dec -Ptb_sn_dec.WIDTH=32 -Ptb_sn_dec.HEIGHT=16 \
        -Ptb_sn_dec.IN_FILE=\"packets_sn.txt\" -Ptb_sn_dec.OUT_FILE=\"decoded_sn_hw.hex\" \
        -o sim_sn_dec.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/sn_decoder/src/*.v && vvp sim_sn_dec.vvp >/dev/null

    # SN Decoder on MF+SN packets (32x14)
    iverilog -g2005 -s tb_sn_dec -Ptb_sn_dec.WIDTH=32 -Ptb_sn_dec.HEIGHT=14 \
        -Ptb_sn_dec.IN_FILE=\"packets_mf_sn.txt\" -Ptb_sn_dec.OUT_FILE=\"decoded_mf_sn_hw.hex\" \
        -o sim_mf_sn_dec.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/sn_decoder/src/*.v && vvp sim_mf_sn_dec.vvp >/dev/null

    # MN Decoder on unfiltered MN packets (32x16)
    iverilog -g2005 -s tb_mn_dec -Ptb_mn_dec.WIDTH=32 -Ptb_mn_dec.HEIGHT=16 \
        -Ptb_mn_dec.IN_FILE=\"packets_mn.txt\" -Ptb_mn_dec.OUT_FILE=\"decoded_mn_hw.hex\" \
        -o sim_mn_dec.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/mn_decoder/src/*.v && vvp sim_mn_dec.vvp >/dev/null

    # MN Decoder on MF+MN packets (32x14)
    iverilog -g2005 -s tb_mn_dec -Ptb_mn_dec.WIDTH=32 -Ptb_mn_dec.HEIGHT=14 \
        -Ptb_mn_dec.IN_FILE=\"packets_mf_mn.txt\" -Ptb_mn_dec.OUT_FILE=\"decoded_mf_mn_hw.hex\" \
        -o sim_mf_mn_dec.vvp "$WORK_DIR/tb_all_e2e.v" "$REPO_ROOT"/rtl/mn_decoder/src/*.v && vvp sim_mf_mn_dec.vvp >/dev/null
)

echo "[4/4] Verifying bit-accurate reconstruction (0 pixel mismatches)..."
python3 - "$WORK_DIR" "$WIDTH" "$HEIGHT" << 'PYEOF'
import sys, os

work_dir = sys.argv[1]
W, H = int(sys.argv[2]), int(sys.argv[3])

def read_hex(name):
    with open(os.path.join(work_dir, name)) as f:
        return [int(line.strip(), 16) for line in f if line.strip()]

def read_packets(name):
    with open(os.path.join(work_dir, name)) as f:
        return [line.strip() for line in f if line.strip()]

def sw_decode_sn(words, total_pixels):
    bitstream = "".join(w[::-1] for w in words)
    pos = 0
    out = []
    while len(out) < total_pixels and pos < len(bitstream):
        if bitstream[pos] == '1':
            out.append(out[-1])
            pos += 1
        else:
            val = int(bitstream[pos+1:pos+9][::-1], 2)
            out.append(val)
            pos += 9
    return out

def sw_decode_mn(words, width, total_pixels, is_hlb=False):
    bitstream = "".join(w[::-1] for w in words)
    pos = 0
    out = []
    while len(out) < total_pixels and pos + 1 < len(bitstream):
        idx = len(out)
        hdr = bitstream[pos:pos+2]
        if hdr == "00":
            val = int(bitstream[pos+2:pos+10][::-1], 2)
            out.append(val)
            pos += 10
        elif hdr == "10": # 2'b01 in Verilog -> bit0=1, bit1=0 -> Left neighbor
            out.append(out[idx - 1])
            pos += 2
        elif hdr == "01": # 2'b10 in Verilog -> bit0=0, bit1=1 -> Top (or Top-Left on even col in HLB)
            if is_hlb and ((idx + 1) % 2 == 0):
                out.append(out[idx - width - 1])
            else:
                out.append(out[idx - width])
            pos += 2
        elif hdr == "11": # 2'b11 in Verilog -> Top-Right (or Top-Right-Right on odd col in HLB)
            if is_hlb and ((idx + 1) % 2 == 1):
                out.append(out[idx - width + 2])
            else:
                out.append(out[idx - width + 1])
            pos += 2
    return out

gt_unfiltered = read_hex("input_unfiltered.hex")
gt_filtered   = read_hex("golden_filtered.hex")

checks = [
    ("1. SN Encoder (HW) -> SN Decoder (HW)",      read_hex("decoded_sn_hw.hex"),                                      gt_unfiltered, len(read_packets("packets_sn.txt"))),
    ("2. SN Encoder (HW) -> SN Decoder (SW)",      sw_decode_sn(read_packets("packets_sn.txt"), len(gt_unfiltered)),   gt_unfiltered, len(read_packets("packets_sn.txt"))),
    ("3. MF+SN Encoder (HW) -> SN Decoder (HW)",   read_hex("decoded_mf_sn_hw.hex"),                                   gt_filtered,   len(read_packets("packets_mf_sn.txt"))),
    ("4. MF+SN Encoder (HW) -> SN Decoder (SW)",   sw_decode_sn(read_packets("packets_mf_sn.txt"), len(gt_filtered)),  gt_filtered,   len(read_packets("packets_mf_sn.txt"))),
    ("5. MN Encoder (HW) -> MN Decoder (HW)",      read_hex("decoded_mn_hw.hex"),                                      gt_unfiltered, len(read_packets("packets_mn.txt"))),
    ("6. MN Encoder (HW) -> MN Decoder (SW)",      sw_decode_mn(read_packets("packets_mn.txt"), W, len(gt_unfiltered), False), gt_unfiltered, len(read_packets("packets_mn.txt"))),
    ("7. MF+MN Encoder (HW) -> MN Decoder (HW)",   read_hex("decoded_mf_mn_hw.hex"),                                   gt_filtered,   len(read_packets("packets_mf_mn.txt"))),
    ("8. MF+MN Encoder (HW) -> MN Decoder (SW)",   sw_decode_mn(read_packets("packets_mf_mn.txt"), W, len(gt_filtered), False), gt_filtered, len(read_packets("packets_mf_mn.txt"))),
    ("9. HLB-MN Encoder (HW) -> HLB Decoder (SW)", sw_decode_mn(read_packets("packets_hlb_mn.txt"), W, len(gt_unfiltered), True), gt_unfiltered, len(read_packets("packets_hlb_mn.txt"))),
    ("10. MF+HLB-MN Enc (HW) -> HLB Decoder (SW)", sw_decode_mn(read_packets("packets_mf_hlb_mn.txt"), W, len(gt_filtered), True), gt_filtered, len(read_packets("packets_mf_hlb_mn.txt"))),
]

all_ok = True
print("----------------------------------------------------------------------------")
print(f"{'Verification Path':<44} | {'Pixels':<6} | {'128b MWs':<8} | {'Mismatches'}")
print("----------------------------------------------------------------------------")
for label, decoded, expected, num_mws in checks:
    mismatches = sum(1 for a, b in zip(decoded, expected) if a != b) + abs(len(decoded) - len(expected))
    status = "0 (PASS)" if mismatches == 0 else f"{mismatches} (FAIL)"
    if mismatches != 0:
        all_ok = False
    print(f"{label:<44} | {len(decoded):<6} | {num_mws:<8} | {status}")
print("----------------------------------------------------------------------------")
if not all_ok:
    sys.exit(1)
print("SUCCESS: All 8 RTL hardware architectures verified with 0 pixel mismatches!")
PYEOF
