// Lesson 3: Lava. Time, and light the surface gives off.
//
// Builds on lesson 2. New here: Time(), the scene's clock in seconds, which makes a surface move;
// emission, light the surface gives off whatever lights it (above 1 it glows, and bloom spreads
// it); and a pattern made from maths instead of a texture.
// surface: lit

properties
{
    Color CrackColour = (1.0, 0.35, 0.05, 1.0);
    float Speed       = 0.2 [0, 2];    // how fast the cracks scroll
    float Glow        = 4.0 [0, 20];   // how bright they burn
    float Scale       = 3.0 [1, 10];   // how many cracks across the mesh
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    // Scroll the coordinates with time: the cracks drift across the rock.
    float2 uv = input.uv * Scale * 6.2832 + float2(0.0, Time() * Speed * 6.0);
    // Two wavy sine fields; where either crosses zero is a crack (0 in the rock, 1 in a crack).
    float a = abs(sin(uv.x + sin(uv.y * 0.73) * 1.7));
    float b = abs(sin(uv.y * 0.91 + sin(uv.x * 0.61) * 1.3));
    float crack = saturate(1.0 - min(a, b) * 5.0);
    surface.albedo = lerp(float3(0.08, 0.05, 0.04), CrackColour.rgb, crack);
    surface.roughness = 0.9;
    surface.emissive = CrackColour.rgb * crack * Glow;
}
