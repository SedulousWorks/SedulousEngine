// Masquerade's masks: lacquered metal leaf whose colour shifts with the angle to the eye, as gilt
// and enamel do under candlelight, so the crowd glints as the camera moves; and the flare, a glow
// the round lights on a hunter's mask by its instance's tint (Ball.as: alpha below 1 is the glow,
// so the costume's cloth, drawn with the same tint, keeps its colour).
// surface: lit

properties
{
    Color BaseColor    = (0.85, 0.66, 0.25, 1);  // the mask's own colour (each costume's, from its model)
    float Shift        = 0.35 [0, 1];            // how far the hue turns at a grazing angle
    float ShiftPower   = 2.0 [0.5, 6];           // how near the edge the turn gathers
    float Metallic     = 0.85 [0, 1];
    float Roughness    = 0.22 [0.02, 1];
    ColorHdr GlowColor = (1.0, 0.45, 0.15, 1);   // the flare
    float GlowStrength = 6.0 [0, 20];
}

// A thin film's colour over the mask: a hue turned by `t` (0 none, 1 a full turn) around the colour.
float3 TurnHue(float3 c, float t)
{
    // Rodrigues' rotation about the grey axis: the hue turns, the brightness stays.
    const float3 k = float3(0.57735, 0.57735, 0.57735);
    float a = t * 6.2831853;
    float cs = cos(a);
    return c * cs + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - cs);
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    float facing = saturate(dot(input.normal, input.viewDir));
    float edge = pow(1.0 - facing, ShiftPower);
    float3 film = saturate(TurnHue(BaseColor.rgb, Shift * edge));
    surface.albedo = lerp(BaseColor.rgb, film, edge);
    surface.metallic = Metallic;
    surface.roughness = Roughness;

    // The flare: the tint's alpha below 1, pulsing a little, brightest at the mask's rim.
    float glow = saturate(1.0 - input.color.a);
    float pulse = 0.75 + 0.25 * sin(Time() * 12.0);
    surface.emissive = GlowColor.rgb * GlowStrength * glow * pulse * (0.4 + 0.6 * edge + 0.3 * facing);
}
