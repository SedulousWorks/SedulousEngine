// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Portable push-constant declaration.
//
//   PUSH_CONSTANT(TonemapPush, pc, space1);
//
// expands per target so one source line serves every backend:
//
//   Native (default) - Vulkan, DX12, AND native wgpu-native WebGPU:
//     [[vk::push_constant]] ConstantBuffer<TonemapPush> pc : register(b0, space1)
//     DXC lowers the vk attribute to a SPIR-V push-constant block (Vulkan push constants;
//     naga -> WGSL var<immediate> -> wgpu-native's Immediates feature). On DXIL the attribute
//     is ignored and it is a plain cbuffer at (b0, space1) that the DX12 root signature places
//     as root constants. Byte-identical to the raw declaration these shaders used before.
//
//   Browser WebGPU (define PUSH_CONSTANT_AS_CBUFFER, set by the web cook):
//     ConstantBuffer<TonemapPush> pc : register(b0, space1)
//     Browser WebGPU has no push constants / immediates (pipeline layouts with push-constant
//     ranges fail), so the block becomes an ordinary uniform buffer. Under the engine binding
//     shift scheme (CBV shift 0) the `space` becomes its own bind group -> @group(space)
//     @binding(0), a reserved slot the browser pipeline layout binds as a uniform buffer and
//     the encoder feeds via a per-draw uniform-buffer write instead of SetImmediates.
//
// The `space` argument is passed as a token (space0 / space1 / ...) and preserves each
// shader's existing placement, so DX12 root-signature and Vulkan set assignments are unchanged.
// The register is always b0 (a push-constant block is single). No trailing semicolon - write
// one at the call site.
//
// The browser form has no consumer yet (the browser backend is gated on this shaders track's
// P3); it is validated when that backend lands. Until PUSH_CONSTANT_AS_CBUFFER is set
// the expansion is exactly the native push-constant declaration - zero behavior change.

#ifndef PUSH_CONSTANT_HLSLI
#define PUSH_CONSTANT_HLSLI

#ifdef PUSH_CONSTANT_AS_CBUFFER
#define PUSH_CONSTANT(Type, name, space) ConstantBuffer<Type> name : register(b0, space)
#else
#define PUSH_CONSTANT(Type, name, space)                                                            \
    [[vk::push_constant]] ConstantBuffer<Type> name : register(b0, space)
#endif

#endif // PUSH_CONSTANT_HLSLI
