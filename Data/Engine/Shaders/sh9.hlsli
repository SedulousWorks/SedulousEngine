// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Irradiance from nine spherical harmonic coefficients of radiance, cosine-convolved (Ramamoorthi
// and Hanrahan, "An Efficient Representation for Irradiance Environment Maps", equation 13), in
// the basis and order ibl_sh.cs.hlsl projects with: [0] L00, [1] L1-1 (y), [2] L10 (z), [3] L11 (x),
// [4] L2-2 (xy), [5] L2-1 (yz), [6] L20 (3z^2 - 1), [7] L21 (xz), [8] L22 (x^2 - y^2). The one
// evaluator every pass that reads the scene's SH uses, so they cannot drift apart.
#ifndef SH9_HLSLI
#define SH9_HLSLI

float3 EvalSH9Irradiance(float3 sh[9], float3 n) {
    float3 r = sh[0] * 0.886227;                                // c4 L00
    r += sh[1] * (2.0 * 0.511664 * n.y);                        // 2 c2 L1m
    r += sh[2] * (2.0 * 0.511664 * n.z);
    r += sh[3] * (2.0 * 0.511664 * n.x);
    r += sh[4] * (2.0 * 0.429043 * n.x * n.y);                  // 2 c1 L2m
    r += sh[5] * (2.0 * 0.429043 * n.y * n.z);
    r += sh[6] * (0.247708 * (3.0 * n.z * n.z - 1.0));          // c3 z^2 - c5 = c5 (3z^2 - 1)
    r += sh[7] * (2.0 * 0.429043 * n.x * n.z);
    r += sh[8] * (0.429043 * (n.x * n.x - n.y * n.y));          // c1 L22
    return max(r, 0.0);
}

#endif // SH9_HLSLI
