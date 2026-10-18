using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// Effects drawn under text (VGContext.SetTextEffects), in the text's own pixels: a shadow, then
/// a glow, then an outline, then the glyphs. The glow and the outline, and a shadow's blur, read
/// a distance-field font's true distance; a coverage font draws a shadow's offset copy only. They
/// reach as far past the edge as the field holds: half the atlas's distance range, in its bake's
/// pixels (2 px for the default 4-texel range at the bake size), and what asks for more is scaled
/// down to fit.
struct TextEffects
{
	/// Pixels past the edge; 0 for none.
	public float OutlineWidth = 0.0f;
	public Color OutlineColor = .(0.0f, 0.0f, 0.0f, 1.0f);
	/// The shadow's offset from the text, in pixels.
	public Float2 ShadowOffset = .Zero;
	/// The width of the shadow's soft edge, in pixels; 0 for hard.
	public float ShadowBlur = 0.0f;
	/// Transparent: no shadow.
	public Color ShadowColor = .(0.0f, 0.0f, 0.0f, 0.0f);
	/// How far the glow fades out past the edge; 0 for none.
	public float GlowRadius = 0.0f;
	public Color GlowColor = .(1.0f, 1.0f, 1.0f, 1.0f);

	public this() {}

	public bool HasOutline => (OutlineWidth > 0.0f) && (OutlineColor.A > 0.0f);
	public bool HasShadow => (ShadowColor.A > 0.0f) && ((ShadowOffset.X != 0.0f) || (ShadowOffset.Y != 0.0f) || (ShadowBlur > 0.0f));
	public bool HasGlow => (GlowRadius > 0.0f) && (GlowColor.A > 0.0f);
	public bool Any => HasOutline || HasShadow || HasGlow;

	public static bool operator==(TextEffects a, TextEffects b)
		=> (a.OutlineWidth == b.OutlineWidth) && (a.OutlineColor == b.OutlineColor) && (a.ShadowOffset == b.ShadowOffset)
			&& (a.ShadowBlur == b.ShadowBlur) && (a.ShadowColor == b.ShadowColor) && (a.GlowRadius == b.GlowRadius)
			&& (a.GlowColor == b.GlowColor);
}
