// Sprite Vertex Shader
// Billboarded sprites using instanced rendering

cbuffer CameraBuffer : register(b0)
{
    float4x4 viewProjection;
    float4x4 view;
    float4x4 projection;
    float3 cameraPosition;
    float _pad0;
};

struct VSInput
{
    // Per-instance data
    float3 position : TEXCOORD0;     // World position
    float2 size : TEXCOORD1;         // Width, height
    float4 uvRect : TEXCOORD2;       // minU, minV, maxU, maxV
    float4 color : COLOR;            // RGBA
    uint vertexID : SV_VertexID;     // 0-5 for quad
};

struct PSInput
{
    float4 position : SV_Position;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
};

PSInput main(VSInput input)
{
    PSInput output;

    // Billboard quad vertices (facing camera)
    // Vertex order: 0-1-2, 2-1-3 (two triangles)
    float2 cornerOffsets[4] = {
        float2(-0.5, 0.5),   // 0: top-left
        float2(0.5, 0.5),    // 1: top-right
        float2(-0.5, -0.5),  // 2: bottom-left
        float2(0.5, -0.5)    // 3: bottom-right
    };

    uint vertexIndex = input.vertexID % 6;
    uint cornerIndex;
    if (vertexIndex == 0) cornerIndex = 0;
    else if (vertexIndex == 1) cornerIndex = 1;
    else if (vertexIndex == 2) cornerIndex = 2;
    else if (vertexIndex == 3) cornerIndex = 2;
    else if (vertexIndex == 4) cornerIndex = 1;
    else cornerIndex = 3;

    float2 corner = cornerOffsets[cornerIndex];

    // Get camera right and up vectors from view matrix (row-major layout)
    // Row 0 = right, Row 1 = up, Row 2 = forward
    float3 right = float3(view[0][0], view[0][1], view[0][2]);
    float3 up = float3(view[1][0], view[1][1], view[1][2]);

    // Calculate world position with billboard offset
    float3 worldPos = input.position;
    worldPos += right * corner.x * input.size.x;
    worldPos += up * corner.y * input.size.y;

    output.position = mul(viewProjection, float4(worldPos, 1.0));

    // UV from rect
    float2 uvCorners[4] = {
        float2(input.uvRect.x, input.uvRect.y),   // 0: top-left (minU, minV)
        float2(input.uvRect.z, input.uvRect.y),   // 1: top-right (maxU, minV)
        float2(input.uvRect.x, input.uvRect.w),   // 2: bottom-left (minU, maxV)
        float2(input.uvRect.z, input.uvRect.w)    // 3: bottom-right (maxU, maxV)
    };
    output.uv = uvCorners[cornerIndex];

    output.color = input.color;

    return output;
}
