// Lesson 5: Triplanar Rock. A texture with no uv, and a normal map.
//
// Builds on lesson 2. New here: mapping by input.worldPos instead of the mesh's uv. The texture is
// projected three times, along each world axis, and the three are blended by how much the surface
// faces each axis; a lumpy rock has no good uv, and this needs none. And a normal map: the surface's
// bumps as normals, which `surface.normal` takes in TANGENT space (x along the uv's u, y along v, z
// out of the surface), so the world-space bumps the projections give are turned into it at the end.
// surface: lit

properties
{
    Color   Paint       = (1, 1, 1, 1);
    float   Scale       = 0.8 [0.1, 4];   // texture repeats per metre
    float   Sharpness   = 4   [1, 16];    // how quickly one projection gives way to the next
    float   BumpStrength = 1  [0, 2];
    float   Roughness   = 0.85 [0, 1];
    Texture RockColour;
    Texture RockNormal;                   // named "...Normal": unbound, it reads as flat
    Sampler MainSampler;
}

// A tangent-space normal from the map (0..1 in the texture) as -1..1, its bumps scaled.
float3 ReadNormal(float2 uv)
{
    float3 n = RockNormal.Sample(MainSampler, uv).xyz * 2.0 - 1.0;
    return normalize(float3(n.xy * BumpStrength, n.z));
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    float3 N = input.normal;
    // How much each axis' projection counts: the normal's share of it, sharpened, summing to 1.
    float3 w = pow(abs(N), Sharpness);
    w /= (w.x + w.y + w.z);

    // The three projections: looking along x (the yz plane), along y (xz) and along z (xy).
    float3 p = input.worldPos * Scale;
    float2 uvX = p.zy, uvY = p.xz, uvZ = p.xy;
    float3 colour = RockColour.Sample(MainSampler, uvX).rgb * w.x
                  + RockColour.Sample(MainSampler, uvY).rgb * w.y
                  + RockColour.Sample(MainSampler, uvZ).rgb * w.z;
    surface.albedo = colour * Paint.rgb;
    surface.roughness = Roughness;

    // Each projection's normal map, swizzled into world space (its plane's two axes plus the axis
    // it looks along, flipped to the side the surface faces), then blended like the colour.
    float3 nX = ReadNormal(uvX), nY = ReadNormal(uvY), nZ = ReadNormal(uvZ);
    float3 s = sign(N);
    float3 worldX = float3(nX.z * s.x, nX.y, nX.x);
    float3 worldY = float3(nY.x, nY.z * s.y, nY.y);
    float3 worldZ = float3(nZ.x, nZ.y, nZ.z * s.z);
    float3 bumped = normalize(worldX * w.x + worldY * w.y + worldZ * w.z);

    // World space into tangent space: the surface's own frame from its tangent and normal.
    float3 T = normalize(input.tangent.xyz - N * dot(input.tangent.xyz, N));
    float3 B = cross(N, T) * input.tangent.w;
    surface.normal = float3(dot(bumped, T), dot(bumped, B), dot(bumped, N));
}
