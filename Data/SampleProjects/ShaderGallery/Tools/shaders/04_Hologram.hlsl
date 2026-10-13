// Lesson 4: Hologram. A see-through surface that answers to the camera.
//
// Builds on lesson 3. New here: input.viewDir, the direction from the point to the camera, which
// makes a fresnel rim (bright where the surface turns edge-on); input.screenPos, the pixel being
// drawn, which makes scanlines that stay still on the screen however the object turns; and alpha,
// how much of the surface shows. Alpha only blends when the MATERIAL is blended: this lesson's
// material is set to Alpha Blend on the material page (Blend Mode).
// surface: unlit

properties
{
    Color Beam       = (0.25, 0.85, 1.0, 1);
    float RimPower   = 2.5 [0.5, 8];   // how tight the rim is: higher is thinner
    float RimGlow    = 3.0 [0, 10];    // how bright the rim burns
    float LineSpacing = 4 [2, 16];     // pixels from one scanline to the next
    float Opacity    = 0.25 [0, 1];    // how much of the face-on surface shows
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    // 1 where the surface faces the camera, 0 where it turns edge-on; the rim is the opposite.
    float facing = saturate(dot(input.normal, input.viewDir));
    float rim = pow(1.0 - facing, RimPower);

    // screenPos.xy is in pixels: every LineSpacing pixels a dark line, scrolling slowly down.
    float band = frac((input.screenPos.y + Time() * 20.0) / LineSpacing);
    float scan = band < 0.5 ? 1.0 : 0.55;

    // A faint flicker, as a projection does.
    float flicker = 0.92 + 0.08 * sin(Time() * 23.0) * sin(Time() * 7.0);

    surface.albedo = Beam.rgb * (scan * flicker + rim * RimGlow);
    // Unlit: albedo is the colour shown. Alpha: faint face-on, solid at the rim.
    surface.alpha = saturate((Opacity + rim) * scan);
}
