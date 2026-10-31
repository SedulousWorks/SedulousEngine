// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// variants: SKINNED INSTANCED ALPHA_TEST WIND
// preserve-interface
// (Keeps every vertex input in the interface: the pipeline binds the full mesh layout, and an input
// stripped as unread is an attribute the vertex stage does not consume, a validation warning.)
#include "shadow_depth_vs.hlsli"
