#!/usr/bin/env python3
"""
prepare_1080p_vectors.py
========================
Dynamically discovers all `.mat` disparity maps in `data/` (or a custom directory)
and converts them into raster-scan hexadecimal `.txt` files for RTL testbenches.
Also writes `input_disparity_map.txt` (the default input filename expected by the
RTL encoder testbenches) from the first discovered `.mat` file.

Usage:
    python3 scripts/sim/prepare_1080p_vectors.py [output_dir] [data_dir]
"""

import glob
import os
import shutil
import struct
import sys
import zlib

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEFAULT_DATA_DIR = os.path.join(REPO_ROOT, "data")


def load_mat_2d_uint8(mat_path):
    """Minimal pure-Python MATLAB v5 .mat reader (no scipy required)."""
    try:
        import scipy.io as sio
        mat = sio.loadmat(mat_path)
        for k, v in mat.items():
            if not k.startswith("__"):
                return v
    except ImportError:
        pass

    with open(mat_path, "rb") as f:
        data = f.read()

    pos = 128
    dtype, nbytes = struct.unpack("<II", data[pos:pos + 8])
    raw = data[pos + 8:pos + 8 + nbytes]
    if dtype == 15:  # miCOMPRESSED
        raw = zlib.decompress(raw)

    p = 8
    t, nb = struct.unpack("<II", raw[p:p + 8])
    p += 8 + ((nb + 7) & ~7)
    t, nb = struct.unpack("<II", raw[p:p + 8])
    rows, cols = struct.unpack("<ii", raw[p + 8:p + 16])
    p += 8 + ((nb + 7) & ~7)
    t_raw, = struct.unpack("<I", raw[p:p + 4])
    if (t_raw >> 16) != 0:
        p += 8
    else:
        _, nb = struct.unpack("<II", raw[p:p + 8])
        p += 8 + ((nb + 7) & ~7)
    t, nb = struct.unpack("<II", raw[p:p + 8])
    payload = raw[p + 8:p + 8 + nb]

    if t == 2:  # miUINT8
        vals = list(payload)
    elif t == 7:  # miSINGLE (float32)
        vals = [int(round(x)) for x in struct.unpack(f"<{rows * cols}f", payload)]
    elif t == 9:  # miDOUBLE (float64)
        vals = [int(round(x)) for x in struct.unpack(f"<{rows * cols}d", payload)]
    else:
        raise RuntimeError(f"Unsupported MAT data type tag: {t}")

    grid = []
    for r in range(rows):
        row_vals = [vals[r + c * rows] for c in range(cols)]
        grid.append(row_vals)
    return grid


def write_hex_vector(grid, out_path):
    rows = len(grid)
    cols = len(grid[0])
    with open(out_path, "w") as f:
        for r in range(rows):
            for c in range(cols):
                f.write(f"{int(grid[r][c]) & 0xFF:x}\n")
    return rows, cols


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    data_dir = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_DATA_DIR
    os.makedirs(out_dir, exist_ok=True)

    mat_files = sorted(glob.glob(os.path.join(data_dir, "*.mat")))
    if not mat_files:
        print(f"[WARN] No .mat files found in {data_dir}")
        return

    first_out = None
    for mat_path in mat_files:
        stem = os.path.splitext(os.path.basename(mat_path))[0]
        out_path = os.path.join(out_dir, f"{stem}_in.txt")
        grid = load_mat_2d_uint8(mat_path)
        h, w = write_hex_vector(grid, out_path)
        print(f"[OK] Wrote {out_path} ({w}x{h} = {w * h} pixels)")
        if first_out is None:
            first_out = out_path

    default_in = os.path.join(out_dir, "input_disparity_map.txt")
    if first_out and os.path.abspath(first_out) != os.path.abspath(default_in):
        shutil.copyfile(first_out, default_in)
        print(f"[OK] Set default testbench input -> {default_in}")


if __name__ == "__main__":
    main()
