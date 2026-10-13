// Lesson 8: Wind. Moving vertices by where they are on the mesh.
//
// Builds on lesson 7. New here: v.localPosition, the vertex's place on the mesh itself, before the
// object is placed in the world. The flag's hoist (the pole side) is at x = 0 on its mesh, so the
// further along x a point is, the more it may move: the hoist stays on the pole, the fly end
// flaps. Moving by the world position instead would make every flag in a row sway the same.
// The material draws both faces (Cull Mode: None), so the flag shows from behind too.
// surface: lit

properties
{
    Color Field   = (0.70, 0.08, 0.10, 1);
    Color Stripe  = (0.95, 0.92, 0.85, 1);
    float Strength = 0.18 [0, 0.6];   // metres the fly end swings, about
    float Ripples  = 2.5  [0.5, 6];   // waves along the flag
    float Speed    = 2.5  [0, 8];
    float Length   = 1.6  [0.1, 4];   // the flag's length on its mesh: where the sway is full
}

// How far the flag moves out of its plane at local x, y: a wave along it, growing from the pole.
float Sway(float3 local)
{
    float along = saturate(local.x / Length);
    float wave = sin(local.x * Ripples * 3.1416 - Time() * Speed) +
                 0.35 * sin(local.x * Ripples * 6.0 + local.y * 2.0 - Time() * Speed * 1.7);
    return wave * Strength * along * along;
}

void Vertex(inout VertexInput v)
{
    float offset = Sway(v.localPosition);
    // Out of the flag's plane: along its normal.
    v.position += v.normal * offset;
    // The new normal: tilted by the sway's slope along the flag (a small step to measure it).
    float step = 0.01;
    float slope = (Sway(v.localPosition + float3(step, 0, 0)) - offset) / step;
    v.normal = normalize(v.normal - v.tangent * slope);
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    // Three stripes across the uv.
    float stripe = step(0.5, frac(input.uv.y * 3.0 / 2.0 + 0.25));
    surface.albedo = lerp(Field.rgb, Stripe.rgb, stripe);
    surface.roughness = 0.8;
}
