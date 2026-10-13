// Lesson 6: Dissolve. Cutting holes in a surface, and its shadow.
//
// Builds on lesson 3. New here: alpha on a MASKED material (Blend Mode: Masked on the material
// page): wherever alpha falls below the cut-off the surface is not drawn at all, and because the
// engine runs the same Surface() for the shadow and the depth, the shadow has the holes too. A
// float property named AlphaCutoff sets the cut-off (without one it is a half). A noise texture
// says where the surface goes first, and a glowing rim follows the edge as it moves.
// surface: lit

properties
{
    Color   Paint       = (0.75, 0.78, 0.85, 1);
    Color   EdgeColour  = (1.0, 0.45, 0.1, 1);
    float   Speed       = 0.35 [0, 2];     // dissolve cycles per second, about
    float   EdgeWidth   = 0.06 [0, 0.3];   // how wide the burning rim is, in noise
    float   EdgeGlow    = 6   [0, 20];
    float   Tiling      = 1   [0.25, 4];
    float   AlphaCutoff = 0.5 [0, 1];      // the masked material's cut-off, by name
    Texture Pattern;                       // grey: dark goes first
    Sampler MainSampler;
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    float n = Pattern.Sample(MainSampler, input.uv * Tiling).r;
    // How much has gone: 0 to 1 and back, easing at each end.
    float amount = 0.5 - 0.5 * cos(Time() * Speed * 3.0);
    // Above the cut-off where the noise is above `amount`: those points stay.
    float left = n - amount * 1.1 + 0.05;
    surface.alpha = AlphaCutoff + left;

    surface.albedo = Paint.rgb;
    surface.roughness = 0.4;
    surface.metallic = 0.6;
    // The rim: just inside the edge, fading over EdgeWidth.
    float rim = 1.0 - smoothstep(0.0, max(EdgeWidth, 1e-4), left);
    surface.emissive = EdgeColour.rgb * rim * EdgeGlow;
}
