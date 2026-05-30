"""
Generates the pre-computed BRDF integration LUT for split-sum image-based
lighting and emits it as a Beef source file with the bytes embedded.

Generated file (`BRDFLutData.bf`) defines a static array that the renderer
uploads to a 2D Texture (RG16Float) at engine init. Bake-once, runtime-zero.

Usage (from repo root):
    python Scripts/generate_brdf_lut.py
        -> writes Code/Foundation/Sedulous.Renderer/src/IBL/BRDFLutData.bf

Format: SIZE x SIZE RG16Float, 4 bytes per pixel.
  Y axis = roughness  in [0, 1]
  X axis = NdotV      in [0, 1]
  R channel = scale (multiplies F0)
  G channel = bias  (added)

Indirect specular reconstruction in shader:
    specular = prefilteredColor * (F0 * lut.r + lut.g)

Algorithm: GGX importance sampling (Hammersley sequence), NUM_SAMPLES per
texel. Faithful port of the old engine's SkyFeature.GenerateBRDFLut().

To regenerate: edit constants below, run, commit the resulting .bf.
"""

import numpy as np
import os
import struct
import sys
import time

# 256 matches Unity's default and is visually identical to 512 for a smooth
# LUT. Keeps the embedded array at ~256 KB raw (~1.3 MB as hex source).
SIZE = 256
NUM_SAMPLES = 1024

# Output path is resolved relative to this script's location so the command
# works from anywhere.
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT_PATH = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "Code", "Foundation", "Sedulous.Renderer",
    "src", "IBL", "BRDFLutData.bf"))


def radical_inverse_vdc(bits):
    """Hammersley quasi-random sequence (Van der Corput) - vectorized."""
    bits = bits.astype(np.uint32)
    bits = ((bits << 16) | (bits >> 16))
    bits = (((bits & 0x55555555) << 1) | ((bits & 0xAAAAAAAA) >> 1))
    bits = (((bits & 0x33333333) << 2) | ((bits & 0xCCCCCCCC) >> 2))
    bits = (((bits & 0x0F0F0F0F) << 4) | ((bits & 0xF0F0F0F0) >> 4))
    bits = (((bits & 0x00FF00FF) << 8) | ((bits & 0xFF00FF00) >> 8))
    return bits.astype(np.float64) * 2.3283064365386963e-10


def generate_brdf_lut():
    """Generate the BRDF LUT data using vectorized numpy."""
    start = time.time()

    # Pre-compute Hammersley sequence for all samples.
    sample_indices = np.arange(NUM_SAMPLES, dtype=np.uint32)
    xi1_all = sample_indices.astype(np.float64) / NUM_SAMPLES
    xi2_all = radical_inverse_vdc(sample_indices)

    result_scale = np.zeros((SIZE, SIZE), dtype=np.float64)
    result_bias = np.zeros((SIZE, SIZE), dtype=np.float64)

    for y in range(SIZE):
        if y % 32 == 0:
            elapsed = time.time() - start
            print(f"  Row {y}/{SIZE} ({100*y//SIZE}%) [{elapsed:.1f}s]", file=sys.stderr)

        roughness = (y + 1) / SIZE
        a = roughness * roughness
        a2 = a * a

        # GGX importance sampling: compute H for all samples.
        cos_theta = np.sqrt((1.0 - xi2_all) / (1.0 + (a2 - 1.0) * xi2_all))
        sin_theta = np.sqrt(np.maximum(1.0 - cos_theta * cos_theta, 0.0))
        phi = 2.0 * np.pi * xi1_all

        # H in tangent space (N = Z-up).
        Hx = np.cos(phi) * sin_theta
        Hy = np.sin(phi) * sin_theta
        Hz = cos_theta

        # Geometry k for IBL: k = a / 2 (a = roughness^2).
        k = a * 0.5

        # NdotV values for this row (all x values).
        ndot_v = np.maximum(np.arange(1, SIZE + 1, dtype=np.float64) / SIZE, 0.001)

        # V in tangent space where N = (0,0,1): V = (sqrt(1 - NdotV^2), 0, NdotV).
        Vx = np.sqrt(1.0 - ndot_v * ndot_v)
        Vz = ndot_v

        # VdotH for all (x, sample) combos.
        VdotH = Vx[:, None] * Hx[None, :] + Vz[:, None] * Hz[None, :]
        VdotH = np.maximum(VdotH, 0.0)

        # L = 2 * VdotH * H - V; only need L.z for NdotL since N = (0,0,1).
        Lz = 2.0 * VdotH * Hz[None, :] - Vz[:, None]
        NdotL = np.maximum(Lz, 0.0)
        NdotH = np.maximum(Hz[None, :] * np.ones((SIZE, 1)), 0.0)

        # Only contributing samples (NdotL > 0) accumulate.
        mask = NdotL > 0.0

        # Smith GGX geometry term (split-sum form).
        gv = ndot_v[:, None] / (ndot_v[:, None] * (1.0 - k) + k)
        gl = NdotL / (NdotL * (1.0 - k) + k + 1e-10)
        G = gv * gl

        # G_Vis = G * VdotH / (NdotH * NdotV + epsilon).
        G_Vis = (G * VdotH) / (NdotH * ndot_v[:, None] + 0.0001)

        # Schlick Fresnel split: Fc = (1 - VdotH)^5.
        Fc = np.power(np.maximum(1.0 - VdotH, 0.0), 5.0)

        scale_contrib = np.where(mask, (1.0 - Fc) * G_Vis, 0.0)
        bias_contrib = np.where(mask, Fc * G_Vis, 0.0)

        result_scale[y, :] = np.sum(scale_contrib, axis=1) / NUM_SAMPLES
        result_bias[y, :] = np.sum(bias_contrib, axis=1) / NUM_SAMPLES

    elapsed = time.time() - start
    print(f"  Computation done in {elapsed:.1f}s", file=sys.stderr)

    # Clamp to [0, 1].
    result_scale = np.clip(result_scale, 0.0, 1.0)
    result_bias = np.clip(result_bias, 0.0, 1.0)

    # Convert to float16, then to raw bytes interleaved as RG.
    scale_f16 = result_scale.astype(np.float16)
    bias_f16 = result_bias.astype(np.float16)
    scale_u16 = scale_f16.view(np.uint16)
    bias_u16 = bias_f16.view(np.uint16)
    interleaved = np.stack([scale_u16, bias_u16], axis=-1)  # [SIZE, SIZE, 2]
    return interleaved.tobytes()


def write_bf_file(data: bytes, output_path: str):
    """Write the BRDF LUT data as a Beef source file."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', newline='\n') as f:
        f.write("// AUTO-GENERATED by Scripts/generate_brdf_lut.py - do not edit by hand.\n")
        f.write("// To regenerate: `python Scripts/generate_brdf_lut.py` from the repo root.\n")
        f.write("\n")
        f.write("namespace Sedulous.Renderer.IBL;\n")
        f.write("\n")
        f.write("/// Pre-baked BRDF integration LUT for split-sum image-based lighting.\n")
        f.write(f"/// {SIZE}x{SIZE} RG16Float, {len(data)} bytes total. Uploaded once to a GPU\n")
        f.write("/// texture at renderer init; sampled by the forward shader for indirect\n")
        f.write("/// specular: `specular = prefilteredColor * (F0 * lut.r + lut.g)`.\n")
        f.write("///\n")
        f.write("/// Row layout: Y = roughness [0,1], X = NdotV [0,1].\n")
        f.write(f"/// Algorithm: GGX importance sampling, {NUM_SAMPLES} samples per texel.\n")
        f.write("static class BRDFLutData\n")
        f.write("{\n")
        f.write(f"\tpublic const int32 Width = {SIZE};\n")
        f.write(f"\tpublic const int32 Height = {SIZE};\n")
        f.write(f"\tpublic const int32 DataSize = {len(data)};\n")
        f.write("\n")
        f.write(f"\tpublic static uint8[DataSize] Data = .(\n")

        bytes_per_line = 32
        total = len(data)
        for i in range(0, total, bytes_per_line):
            chunk = data[i:i + bytes_per_line]
            hex_vals = ", ".join(f"0x{b:02X}" for b in chunk)
            if i + bytes_per_line >= total:
                f.write(f"\t\t{hex_vals}\n")
            else:
                f.write(f"\t\t{hex_vals},\n")

        f.write("\t);\n")
        f.write("}\n")


if __name__ == "__main__":
    output_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUT_PATH

    print(f"Generating {SIZE}x{SIZE} BRDF LUT ({NUM_SAMPLES} samples/texel)...", file=sys.stderr)
    data = generate_brdf_lut()
    print(f"Generated {len(data)} bytes", file=sys.stderr)
    print(f"Writing to {output_path}", file=sys.stderr)

    write_bf_file(data, output_path)

    print("Done.", file=sys.stderr)
