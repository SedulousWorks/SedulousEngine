// Masquerade's silk and cloth: a soft sheen that runs along the fabric and brightens where it
// turns from the eye, so a gown under the lanterns reads as silk and a coat as fine wool, rather
// than as plastic.
// surface: lit

properties
{
    Color BaseColor     = (0.55, 0.06, 0.12, 1); // the fabric's colour (each costume's, from its model)
    Color SheenColor    = (1.0, 0.92, 0.85, 1);  // the sheen's tint, a warm white under candles
    float Sheen         = 0.6 [0, 2];            // how bright the grazing sheen is
    float SheenPower    = 3.0 [1, 8];            // how near the edge it gathers
    float Roughness     = 0.45 [0.05, 1];
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    float facing = saturate(dot(input.normal, input.viewDir));
    float grazing = pow(1.0 - facing, SheenPower);
    // A gentle ripple along the fabric (the cloth's own coordinates), so the sheen is not one flat
    // band: folds that catch the light.
    float ripple = 0.85 + 0.15 * sin(input.uv.y * 40.0 + input.uv.x * 7.0);
    float3 sheen = SheenColor.rgb * Sheen * grazing * ripple;
    surface.albedo = BaseColor.rgb + sheen * BaseColor.rgb * 2.0 + sheen * 0.15;
    surface.metallic = 0.0;
    surface.roughness = Roughness;
}
