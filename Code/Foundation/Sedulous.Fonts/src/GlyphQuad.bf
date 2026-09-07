namespace Sedulous.Fonts;

/// Where to draw a glyph and where to sample it from: screen corners and atlas UVs.
struct GlyphQuad
{
	public float X0, Y0, X1, Y1;
	public float U0, V0, U1, V1;

	public this() { X0 = 0; Y0 = 0; X1 = 0; Y1 = 0; U0 = 0; V0 = 0; U1 = 0; V1 = 0; }

	public this(float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1)
	{
		X0 = x0; Y0 = y0; X1 = x1; Y1 = y1; U0 = u0; V0 = v0; U1 = u1; V1 = v1;
	}

	public float Width => X1 - X0;
	public float Height => Y1 - Y0;
}
