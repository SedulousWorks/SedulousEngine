// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The sRGB transfer functions (IEC 61966-2-1), for shaders that receive an AUTHORED colour as
// bytes or floats: authored colours are sRGB, the value a colour picker and a hex code show, and
// rendering works in linear, so a vertex colour is decoded once on its way in. Componentwise
// step/lerp keeps them portable through DXC and naga.
#ifndef COLOR_HLSLI
#define COLOR_HLSLI

float3 SrgbToLinear(float3 c)
{
    float3 t = step(0.04045, c);
    return lerp(c / 12.92, pow(max((c + 0.055) / 1.055, 0.0), 2.4), t);
}

float3 LinearToSrgb(float3 c)
{
    float3 t = step(0.0031308, c);
    return lerp(c * 12.92, 1.055 * pow(max(c, 0.0), 1.0 / 2.4) - 0.055, t);
}

#endif
