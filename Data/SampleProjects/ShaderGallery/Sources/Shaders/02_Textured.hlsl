// Lesson 2: Textured. A texture on a lit surface.
//
// Builds on lesson 1. New here: a texture and the sampler that reads it, the mesh's uv coordinates,
// its vertex colour, and lighting: `lit` shades the surface with every light, shadow and
// reflection probe in the scene, so it only has to say what the surface is made of.
// surface: lit

properties
{
    Color   Paint     = (1, 1, 1, 1);
    float   Tiling    = 2   [0.25, 8];   // how many times the texture repeats across the mesh
    float   Roughness = 0.6 [0, 1];      // 0 is a mirror, 1 is matte
    Texture Albedo;                      // a texture slot on the material page
    Sampler MainSampler;                 // how textures are read: declare one to sample with
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    // input.uv is the mesh's texture coordinate here; scaling it repeats the texture.
    float4 texel = Albedo.Sample(MainSampler, input.uv * Tiling);
    // input.color is the vertex colour times the mesh's tint (white unless the mesh says).
    surface.albedo = texel.rgb * Paint.rgb * input.color.rgb;
    surface.roughness = Roughness;
}
