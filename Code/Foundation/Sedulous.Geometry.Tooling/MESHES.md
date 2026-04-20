# Static vs Skinned Meshes - Import Pipeline

## Vertex Layouts

### StaticMesh (48-byte common layout via `SetupCommonVertexFormat`)

| Field    | Type    | Size  | Offset |
|----------|---------|-------|--------|
| Position | Vector3 | 12 B  | 0      |
| Normal   | Vector3 | 12 B  | 12     |
| UV       | Vector2 | 8 B   | 24     |
| Color    | uint32  | 4 B   | 32     |
| Tangent  | Vector3 | 12 B  | 36     |

Uses `VertexBuffer` with dynamic attribute definitions. The first 48 bytes of layout are identical to SkinnedVertex.

### SkinnedMesh (72-byte fixed `SkinnedVertex` struct)

| Field    | Type      | Size  | Offset |
|----------|-----------|-------|--------|
| Position | Vector3   | 12 B  | 0      |
| Normal   | Vector3   | 12 B  | 12     |
| TexCoord | Vector2   | 8 B   | 24     |
| Color    | uint32    | 4 B   | 32     |
| Tangent  | Vector3   | 12 B  | 36     |
| Joints   | uint16[4] | 8 B   | 48     |
| Weights  | Vector4   | 16 B  | 56     |

Fixed-size `[CRepr]` struct. Adds 24 bytes of skinning data (bone indices + weights) to the common layout.

## Transform Handling - The Key Difference

### Static Meshes: Transforms Are Baked Into Vertices

`ImportStaticMeshes` (ModelImporter.bf) does the following for each mesh:

1. `ComputeMeshNodeWorldTransform(model, meshIndex)` - walks the bone hierarchy from the mesh's owner node up to the root, accumulating the full world transform matrix.
2. `ApplyTransform(mesh, worldTransform)` - **bakes** that transform directly into vertex data:
   - **Positions**: `Vector3.Transform(pos, worldMatrix)` - full affine transform including translation, rotation, scale.
   - **Normals/Tangents**: Uses **normal matrix** (inverse-transpose of upper 3x3) via `Vector3.TransformNormal()`, then normalizes. This correctly handles non-uniform scale.

After baking, vertex positions are in world space. The StaticModel component needs only a simple node transform (identity for origin-placed models, or user-applied position/scale).

This is critical for FBX models where the bone hierarchy often contains coordinate system conversion rotations (e.g., Y-up to Z-up). Without baking, models appear rotated (face-down, sideways, etc.).

### Skinned Meshes: Transforms Are NOT Baked

`ImportSkinnedMeshes` does **not** call `ApplyTransform`. Vertex positions remain in **local bone space** (bind pose). Only `ApplyScaleSkinned` is called if `options.Scale != 1.0`, which directly multiplies positions without applying any rotation.

This is correct because the skinning formula at render time is:
```
final_pos = sum(weight[i] * (position * InverseBindPose[joint[i]] * WorldBoneMatrix[joint[i]]))
```

Baking a world transform into the positions would **double-transform** during skinning.

### Recentering (when `RecenterMeshes = true`)

- **Static**: Simply shifts all vertex positions by `-center`.
- **Skinned**: Shifts vertex positions by `-center` AND adjusts the skeleton:
  - `InverseBindPose[i] = Translation(+center) * InverseBindPose[i]` for all bones
  - `RootCorrection = RootCorrection * Translation(-center)` for root bones only

  This compensates in the skinning math so the final rendered position is still correct.

## Practical Implications

### When loading models in the engine:

1. **For StaticModel**: Use `result.StaticMeshes[i].Mesh` directly. The importer has already baked node transforms, so the mesh is correctly oriented without any extra work. Do NOT convert from SkinnedMesh to StaticMesh - this bypasses the transform baking and produces incorrectly oriented models.

2. **For AnimatedModel**: Use `result.SkinnedMeshes[i].Mesh` with the corresponding skeleton from `result.Skeletons`. The AnimatedModel component handles skinning via bone matrices at render time.

3. **The importer produces BOTH static and skinned versions** of the same geometry. Static meshes have baked transforms; skinned meshes have bone-local positions. They are not interchangeable.

### FBX-specific notes:

- FBX files often have unit scaling issues. The ufbx loader uses `target_unit_meters = 1.0` but some models still appear at centimeter scale (100x smaller than expected). The `options.Scale` parameter or node scale can compensate.
- FBX coordinate system conversion (Z-up to Y-up) creates rotation nodes in the hierarchy. `ComputeMeshNodeWorldTransform` accumulates these, which is why static mesh transform baking is essential for FBX.

## Import Order

```
0a. PreprocessRigidAttachments()  - promote rigid bone-attached meshes to skinned
0b. MergeRelatedSkins()           - consolidate multi-skin hierarchies
1.  Skeletons                     - needed by skinned meshes for ResourceRef
2.  Textures                      - needed by materials
3.  Materials                     - reference textures via ResourceRef
4.  Static Meshes                 - transform baked, standalone
5.  Skinned Meshes                - reference skeletons, bone-local positions
6.  Animations                    - reference skeletons for channel mapping
```

## Summary Table

| Aspect              | StaticMesh                        | SkinnedMesh                       |
|---------------------|-----------------------------------|-----------------------------------|
| Vertex size         | 48 bytes (common layout)          | 72 bytes (+joints, +weights)      |
| Position space      | World (after transform baking)    | Local to bind pose                |
| Transform handling  | Baked via ApplyTransform          | Not baked; skeleton handles it    |
| Rendering           | Vertex -> world -> clip           | Vertex -> bone -> world -> clip   |
| Scale application   | Via full ApplyTransform           | Direct position multiply only     |
| Recentering         | Shift vertices                    | Shift vertices + adjust skeleton  |
| Merge strategy      | All meshes into one resource      | Grouped by skin (one per skeleton)|
