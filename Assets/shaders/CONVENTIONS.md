# Shader Conventions

## Matrix Layout (row_major)

All shaders use `#pragma pack_matrix(row_major)` so that `mul(vector, matrix)`
works with the row-major matrices uploaded from the CPU (Beef `Matrix` type).
This pragma correctly controls layout for **cbuffer** members on both DXIL
(DX12) and SPIR-V (Vulkan).

**However, `pack_matrix(row_major)` does NOT apply to StructuredBuffer members
on DXIL.** The DXIL compiler always reads `float4x4` inside a StructuredBuffer
as column-major, regardless of the pragma. SPIR-V (via DXC) does respect the
pragma for StructuredBuffer members.

To avoid this divergence, **never use `float4x4` inside StructuredBuffer
structs**. Instead, store matrices as 4x `float4` rows and reconstruct at the
load site:

```hlsl
struct MyData
{
    float4 MatrixRow0, MatrixRow1, MatrixRow2, MatrixRow3;
};
StructuredBuffer<MyData> Data : register(t0);

// Reconstruct:
MyData d = Data[index];
float4x4 m = float4x4(d.MatrixRow0, d.MatrixRow1, d.MatrixRow2, d.MatrixRow3);
```

`float4x4(r0, r1, r2, r3)` always treats arguments as rows in HLSL, on both
backends. The byte layout of 4x float4 is identical to float4x4/Matrix on the
CPU side, so no upload changes are needed.

cbuffer matrices are unaffected by this issue and can use `float4x4` directly.

## Vertex Input Semantics (TEXCOORD)

All vertex input semantics use `TEXCOORD{N}` where N matches the
`ShaderLocation` from the Beef `VertexAttribute` definition. The DX12 RHI
backend generates `TEXCOORD + ShaderLocation` for all input layout elements.
Vulkan is unaffected (DXC maps `TEXCOORD N` to `location N`).

Inter-stage semantics (VertexOutput -> FragmentInput) keep their descriptive
names (COLOR0, TEXCOORD0, etc.) since those are matched between shader stages,
not against the input layout.

## Instancing (DataOffsets vertex attribute)

DX12 `SV_InstanceID` is always 0-based regardless of `firstInstance`;
Vulkan `gl_InstanceIndex` includes `firstInstance`. To avoid both this
divergence and per-draw uniform-buffer juggling, instanced draws use a
per-instance vertex attribute (`uint4 DataOffsets` at TEXCOORD5, vertex
buffer slot 1, `.Instance` step rate). Each draw binds a slice of the
per-frame DataOffsets buffer via vertex-buffer byte offset; the GPU
delivers the right `DataOffsets` to each instance automatically.

```hlsl
StructuredBuffer<InstanceData> Instances : register(t0, space3);

struct VertexInput {
    // ... per-vertex mesh attributes ...
    uint4 DataOffsets : TEXCOORD5;   // .x = entity index into Instances[]
};

uint idx = input.DataOffsets.x;
InstanceData data = Instances[idx];
```

`DataOffsets.y/.z/.w` are reserved for future per-instance buffer
indices (custom data, material data, skinning offsets). Today they're
written as zero.
