// Sample017_MultiQueue: Compute, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: compute CSMain

cbuffer Params : register(b0, space0) { float Time; uint NumPoints; float Spacing; float Padding; };
struct Vertex { float PosX, PosY, PosZ, ColR, ColG, ColB; };
RWStructuredBuffer<Vertex> gVertices : register(u0, space0);
[numthreads(64, 1, 1)]
void CSMain(uint3 dtid : SV_DispatchThreadID) {
    uint idx = dtid.x; if (idx >= NumPoints) return;
    uint gridSize = (uint)sqrt((float)NumPoints);
    uint row = idx / gridSize, col = idx % gridSize;
    float fx = ((float)col / (float)(gridSize-1))*2.0 - 1.0;
    float fz = ((float)row / (float)(gridSize-1))*2.0 - 1.0;
    float dist = sqrt(fx*fx + fz*fz);
    float fy = sin(dist*8.0 - Time*3.0) * 0.2;
    gVertices[idx].PosX = fx; gVertices[idx].PosY = fy; gVertices[idx].PosZ = fz;
    gVertices[idx].ColR = 0.5 + 0.5*sin(Time + fx*3.0);
    gVertices[idx].ColG = 0.5 + 0.5*cos(Time + fz*3.0);
    gVertices[idx].ColB = 0.5 + 0.5*sin(Time*0.7 + dist*4.0);
}
