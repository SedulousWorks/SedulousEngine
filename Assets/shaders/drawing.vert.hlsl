// 2D Drawing Vertex Shader
// Supports both per-vertex and instanced sprite rendering modes
#pragma pack_matrix(row_major)

// Projection matrix
cbuffer DrawingUniforms : register(b0)
{
    float4x4 Projection;
};

struct VSOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

#ifdef INSTANCED

// Instanced sprite mode: one instance per sprite, 6 vertices per quad via SV_VertexID

// Per-instance data (matches DrawingSpriteInstance in DrawingRenderer.bf)
struct InstanceInput
{
    float2 Position : ATTRIB0;      // Screen position (top-left)
    float2 Size : ATTRIB1;          // Width, height in pixels
    float4 UVRect : ATTRIB2;        // minU, minV, maxU, maxV
    float4 Color : ATTRIB3;         // RGBA (unorm8x4)
    float Rotation : ATTRIB4;       // Rotation in radians
    float _Pad0 : ATTRIB5;          // Padding
    float _Pad1 : ATTRIB6;          // Padding
    float _Pad2 : ATTRIB7;          // Padding
};

VSOutput main(uint vertexID : SV_VertexID, InstanceInput inst)
{
    VSOutput output;

    // Quad vertex offsets (2 triangles, 6 vertices)
    // Origin at top-left, Y increases downward (screen space)
    static const float2 quadOffsets[6] = {
        float2(0.0, 0.0),  // TL
        float2(1.0, 0.0),  // TR
        float2(0.0, 1.0),  // BL
        float2(0.0, 1.0),  // BL
        float2(1.0, 0.0),  // TR
        float2(1.0, 1.0)   // BR
    };

    static const float2 quadUVs[6] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(0.0, 1.0),
        float2(1.0, 0.0),
        float2(1.0, 1.0)
    };

    float2 offset = quadOffsets[vertexID];

    // Apply rotation around center
    if (abs(inst.Rotation) > 0.0001)
    {
        float2 center = float2(0.5, 0.5);
        float2 centered = offset - center;
        float c = cos(inst.Rotation);
        float s = sin(inst.Rotation);
        offset = float2(
            centered.x * c - centered.y * s,
            centered.x * s + centered.y * c
        ) + center;
    }

    // Scale by size and translate to position
    float2 screenPos = inst.Position + offset * inst.Size;

    output.Position = mul(float4(screenPos, 0.0, 1.0), Projection);

    // Map UV using UVRect (minU, minV, maxU, maxV)
    float2 baseUV = quadUVs[vertexID];
    output.TexCoord = float2(
        lerp(inst.UVRect.x, inst.UVRect.z, baseUV.x),
        lerp(inst.UVRect.y, inst.UVRect.w, baseUV.y)
    );

    output.Color = inst.Color;

    return output;
}

#else

// Standard per-vertex mode (used for shapes, text, etc.)

struct VSInput
{
    float2 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

VSOutput main(VSInput input)
{
    VSOutput output;
    output.Position = mul(float4(input.Position, 0.0, 1.0), Projection);
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;
    return output;
}

#endif
