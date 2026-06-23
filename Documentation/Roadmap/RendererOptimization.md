# Renderer Optimization Plan

Current performance baseline (Release, no shadows, all objects visible):
- **56k spheres @ 26.3ms** (38 FPS)
- CPU work: 14.6ms | GPU wait: 11.7ms

Old engine comparison (Debug, no shadows, 48k):
- Old engine: 26.5ms | New engine: 22.4ms - **new engine is 15% faster**

With shadows (Debug, 48k):
- Old engine: 74ms | New engine: 48ms - **new engine is 35% faster**

---

## Phase 1: Dirty Transform Flags - **DONE**

**Target:** SceneSubsystem.Update (3.4ms -> ~0ms for static scenes)

**Problem:** Transform hierarchy was recalculated for all 56k entities every frame, even when nothing had moved.

**Implementation:**
- `TransformData.Dirty` per-entity flag in `Scene.mTransforms`. Set by
  `MarkDirty` (called from `SetLocalTransform` / `SetParent`), cleared
  by `UpdateTransformRecursive` immediately after recompute.
- `MarkDirty` cascades to all descendants AND ancestors so
  `UpdateTransforms` only needs to scan for dirty *roots* before
  recursing.
- Companion flag `TransformData.UpdatedThisFrame` exposes "did this
  entity's world matrix change this frame?" to PostTransform-phase
  consumers (bounds caches, physics sync, etc.). Set by
  `UpdateTransformRecursive`, cleared at the start of the next
  `UpdateTransforms` via `mTransformsUpdatedThisFrame` (an entity-index
  list that doubles as the iterate-what-moved API).
- Two flags rather than one: keeping "needs recompute" and "moved this
  frame" disjoint avoids a clearing race where the next frame's
  Update-phase `SetLocalTransform` would otherwise be clobbered by the
  end-of-last-frame clear pass.

**Public API on Scene:**
- `IsTransformUpdatedThisFrame(EntityHandle) -> bool`
- `TransformsUpdatedThisFrame -> List<int32>` (indices, read-only; iterators must check `Alive` to skip entities destroyed this frame)

**Actual savings:** ~3ms CPU on static stress test (as predicted).

---

## Phase 2: Extraction Pre-allocation

**Target:** SceneExtraction (6.3ms -> ~4ms)

**Problem:** 56k individual `new:frameAlloc MeshRenderData()` calls + per-entity bounds transform + separate O(n log n) sort pass.

**Approach:**
- Pre-allocate a contiguous `MeshRenderData[]` array from the frame allocator sized to the expected entity count (one bulk allocation instead of 56k individual ones)
- Compute sort keys inline during extraction (avoid the separate `SortAndBatch` iteration)
- Consider SOA (Structure of Arrays) layout for better cache utilization during sort

**Expected savings:** ~2ms CPU

**Complexity:** Low

---

## Phase 3: LOD System

**Target:** GPU wait (11.7ms) - reduce triangle count for distant objects

**Problem:** All 56k spheres use the same high-poly mesh regardless of distance from camera. The GPU rasterizes the same triangle count for a sphere 1 unit away and one 200 units away.

**Approach:**
- Define 3-4 LOD levels per mesh asset (e.g., 480 / 120 / 32 triangles for spheres)
- During extraction, select LOD based on screen-space projected size or distance
- Group instances by LOD level in the batch cache (each LOD = separate batch group since different mesh)
- LOD selection is per-instance, stored in `MeshRenderData`

**Expected savings:** 30-50% GPU vertex processing reduction (scene-dependent)

**Complexity:** Medium

---

## Phase 4: Shadow Cascade Culling

**Target:** ShadowRender with cascaded shadows - reduce per-cascade GPU work

**Problem:** All meshes are copied into every shadow view via `CopyShadowData`, regardless of whether they intersect the cascade's frustum. Cascade 0 covers near objects, cascade 3 covers far objects - most meshes are outside any given cascade.

**Approach:**
- During `CopyShadowData`, test each mesh's bounding sphere against the cascade's view-projection frustum
- Only copy entries that intersect the cascade frustum
- Use the 6-plane frustum test (extract planes from the cascade ViewProj matrix)
- Also applies to point light faces and spot light frustums

**Expected savings:** ~60-80% reduction in shadow GPU work (most meshes are outside any single cascade)

**Complexity:** Medium

---

## Phase 5: Main View Frustum Culling

**Target:** Reduce GPU work when not all objects are visible

**Problem:** All extracted meshes are rendered regardless of whether they're in the camera frustum. Scenes with large worlds waste GPU time on off-screen geometry.

**Approach:**
- Extract frustum planes from the main view's ViewProjectionMatrix
- During extraction, test each mesh's bounding sphere against the 6 frustum planes
- Skip entries that are fully outside the frustum
- Optional: spatial acceleration structure (BVH / grid) for large scenes to avoid O(n) per-entity frustum tests

**Expected savings:** Scene-dependent. With half the scene behind the camera: ~50% GPU reduction.

**Complexity:** Medium (basic) / High (with spatial acceleration)

---

## Phase 6: GPU-Driven Rendering

**Target:** Move culling and LOD selection to the GPU for best scaling

**Problem:** CPU-side culling and LOD are O(n) per entity per frame. At 100k+ entities, this becomes the bottleneck regardless of optimizations.

**Approach:**
- Upload all instance data to a GPU buffer unconditionally
- Compute shader performs frustum culling + LOD selection + compaction
- Output to an indirect draw argument buffer (`DrawIndexedIndirect`)
- CPU issues a single indirect draw per mesh type - no per-entity CPU work
- Integrates with Hi-Z occlusion culling (use depth from previous frame)

**Expected savings:** CPU extraction + culling -> near-zero. GPU culling is massively parallel.

**Complexity:** High

---

## Phase 7: Compute Skinning Mega-Dispatch - **A.1-A.4 done, A.5 deferred**

**Target:** EngineAnimationSandbox herd-scale skinning (5632 dispatches per frame)

**Problem:** Compute skinning bound a fresh descriptor set + dispatched
once per character. At 5632 dispatches, `vkCmdBindDescriptorSets` cost
~2.3 µs each = **~13ms/frame** of pure CPU-side Vulkan validation.

**Landed (A.1-A.4):**
- **A.1** — One shared `SkinnedVertexPool` (Storage|Vertex, 256MB) with
  sub-alloc + per-size free list. Every skinned instance gets a
  sub-range; consumers (forward / depth / shadow / pick) bind the pool
  buffer with the per-instance offset.
- **A.2** — One shared `BoneMatrixPool` (StorageRead|CpuToGpu, 64MB)
  for all per-skeleton bone matrices. `GPUResources.BonePoolBuffer` is
  the single descriptor target; animation writes hit `(pool, offset +
  localOff)`.
- **A.3** — Skinned-mesh source verts live in
  `SkinnedSourceVertexPool` (StorageRead|CopyDst, 64MB). Non-skinned
  meshes still get dedicated buffers (per-mesh `ExtraVertexUsage` flags
  are honored). `GPUMesh.VertexOffset` carries the sub-range location.
- **A.4** — Per-instance bind groups collapsed into ONE frame-scoped
  mega bind group: `t0 bones, t1 sources, t2 SkinningRecords, u0
  outputs` all bound at offset 0 of the pool buffers. Per-character
  state lives in a `StructuredBuffer<SkinningRecord>` written once per
  frame. Per dispatch: 4-byte push constant (`RecordIndex`) +
  `Dispatch`. Shader reads its record and uses absolute offsets into
  each pool. Push-constant declaration mirrors RHI Sample003 /
  Sample018 convention (`ConstantBuffer<PushData>` +
  `[[vk::push_constant]]`).

**Measured (5632 herd):** total skinning **~15ms → ~3ms** (**-12ms**).
`setBindGroup` line: 13ms → 0.01ms. `vkCmdDispatch` is now the
bottleneck at ~2.5ms (~450ns per call).

**Deferred (A.5): single mega-dispatch via record table**

Collapse the remaining 5632 `vkCmdDispatch` calls into **one** by
building a workgroup→record lookup table on the CPU each frame and
issuing a single `Dispatch(totalWorkgroupCount, 1, 1)`. Each workgroup
reads `RecordTable[SV_GroupID.x]` to find which character it belongs
to, computes its local vertex index from a cumulative workgroup-start
field on the record, then transforms as before.

- Expected savings: dispatch line 2.5ms → ~50µs. Total skinning ~3ms →
  ~0.5ms.
- Cost: shader rewrite to consume `SV_GroupID.x` + cumulative
  workgroup offsets; per-frame `RecordTable` build (cheap, ~80k uint32
  entries for the herd).
- Skipped for now because A.1-A.4 already brought skinning under the
  frame budget; the additional ~2ms isn't load-bearing for the current
  stress test. Revisit if a workload appears where per-frame skinning
  dispatch overhead is the next bottleneck.

---

## Summary

| Phase | Target | Savings | Complexity |
|-------|--------|---------|------------|
| 1. Dirty transforms **(done)** | CPU 3.4ms -> ~0ms | ~3ms | Low |
| 2. Extraction pre-alloc | CPU 6.3ms -> ~4ms | ~2ms | Low |
| 3. LOD system | GPU vertex cost | 30-50% GPU | Medium |
| 4. Shadow cascade cull | Shadow GPU cost | 60-80% shadow GPU | Medium |
| 5. Main view frustum cull | GPU (off-screen) | Scene-dependent | Medium |
| 6. GPU-driven rendering | CPU + GPU at scale | Best scaling | High |
| 7. Compute skinning A.1-A.4 **(done)** | Skinning 15ms -> 3ms | ~12ms | Medium |
| 7. Compute skinning A.5 (deferred) | Skinning 3ms -> 0.5ms | ~2ms | Medium |
