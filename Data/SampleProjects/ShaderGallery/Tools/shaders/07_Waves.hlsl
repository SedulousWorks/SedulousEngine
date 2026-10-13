// Lesson 7: Waves. Moving the vertices.
//
// Builds on lesson 3. New here: Vertex(), which runs on each of the mesh's vertices before it is
// drawn and may move it (v.position, in world space) and turn it (v.normal). Everything that draws
// the surface runs it, so its shadow and its depth move with it. A few sine waves travelling
// different ways make the sea; the normal comes from how steeply they slope, so the light rolls
// over the crests.
// surface: lit

properties
{
    Color DeepColour    = (0.02, 0.10, 0.18, 1);
    Color ShallowColour = (0.10, 0.45, 0.50, 1);
    float Height        = 0.06 [0, 0.3];   // metres from trough to crest, about
    float Length        = 0.9  [0.2, 4];   // metres from crest to crest of the longest wave
    float Speed         = 1.0  [0, 4];
}

// One wave's height at p (world x, z), and its slope along x and z.
float3 Wave(float2 p, float2 direction, float length, float height, float speed)
{
    float k = 6.2832 / length;
    float phase = dot(normalize(direction), p) * k - Time() * speed * k * 0.5;
    float slope = height * k * cos(phase);
    return float3(height * sin(phase), normalize(direction) * slope);
}

// The sea at p: three waves; .x the height, .yz the slope.
float3 Sea(float2 p)
{
    return Wave(p, float2(1.0, 0.3), Length, Height * 0.5, Speed)
         + Wave(p, float2(-0.4, 1.0), Length * 0.61, Height * 0.3, Speed)
         + Wave(p, float2(0.7, -0.8), Length * 0.37, Height * 0.2, Speed);
}

void Vertex(inout VertexInput v)
{
    float3 sea = Sea(v.position.xz);
    v.position.y += sea.x;
    // A surface of height h(x, z) has the normal (-dh/dx, 1, -dh/dz), normalised.
    v.normal = normalize(float3(-sea.y, 1.0, -sea.z));
    v.tangent = normalize(float3(1.0, sea.y, 0.0));
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    // Crests catch the shallow colour; the rest is deep. Recompute the height here: Surface() is
    // given the moved point, so the same function says where on the wave it is.
    float crest = saturate(Sea(input.worldPos.xz).x / max(Height, 1e-4) + 0.5);
    surface.albedo = lerp(DeepColour.rgb, ShallowColour.rgb, crest);
    surface.roughness = 0.08;
    surface.metallic = 0.0;
}
