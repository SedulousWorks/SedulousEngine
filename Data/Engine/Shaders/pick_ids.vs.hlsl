// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GPU picking VS: the depth-only caster path (shadow_depth.vs's layouts, bindings and skinning)
// that also carries the draw's entity id to the fragment. The pass renders with a CROPPED camera
// projection into a rect-sized RG32Uint target (PickSystem); the id is (entity index + 1,
// generation) - 0 = nothing. Sources, by draw kind:
//   - single object:   cbuffer Object's PickIndex/PickGeneration (the pads of the forward layout);
//   - instanced run:   the instance-stepped dataOffsets (.w = index + 1, .z = generation - the
//                      pick pass fills its own ramp, so these never collide with the forward's);
//   - MultiMesh set:   cbuffer PickView's SetPickId (one entity for the whole set; its instance
//                      buffer is persistent and its ramp shared, so the id rides the view slot).
// variants: SKINNED INSTANCED ALPHA_TEST WIND
// preserve-interface
// (Keeps every vertex input in the interface: the pipeline binds the full mesh layout, and an input
// stripped as unread is an attribute the vertex stage does not consume, a validation warning.)
#include "pick_ids_vs.hlsli"
