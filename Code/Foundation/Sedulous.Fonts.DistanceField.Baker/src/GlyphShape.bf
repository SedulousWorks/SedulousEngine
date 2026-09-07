using System;
using Sedulous.Fonts.TrueType;
using stb_truetype;
using msdfgen_Beef;

namespace Sedulous.Fonts.DistanceField.Baker;

/// Turns a stb_truetype glyph outline into an msdfgen shape.
static class GlyphShape
{
	/// Builds the outline for one glyph, in NATIVE font units.
	///
	/// Y is not negated. Negating it reverses every contour's winding, and msdfgen reads
	/// winding as inside against outside, so a flipped shape fills the whole cell instead
	/// of the glyph. The Y-up outline to Y-down atlas mapping is done in the PROJECTION and
	/// the row flip on readback, never here.
	///
	/// Returns false when the glyph has no outline, which is a blank such as a space, and
	/// is the caller's cue to record an advance-only region.
	/// Edges go in WHITE, which is a placeholder: msdf_edge_coloring_by_distance overwrites
	/// every colour before generation, and that assignment is what makes a multi-channel
	/// field reconstruct sharp corners.
	public static bool Build(stbtt_fontinfo* info, int32 glyphIndex, msdf_Shape shape)
	{
		stbtt_vertex* vertices = null;
		let count = stbtt_GetGlyphShape(info, glyphIndex, &vertices);
		if ((count <= 0) || (vertices == null))
			return false;
		defer stbtt_FreeShape(info, vertices);

		msdf_Contour contour = null;
		double cursorX = 0;
		double cursorY = 0;

		for (int32 i < count)
		{
			let vertex = vertices[i];
			let x = (double)vertex.x;
			let y = (double)vertex.y;

			switch ((STBTT_v)vertex.type)
			{
			case .STBTT_vmove:
				contour = msdf_shape_add_contour(shape);
				cursorX = x;
				cursorY = y;

			case .STBTT_vline:
				if (contour != null)
					msdf_contour_add_linear_edge(contour, cursorX, cursorY, x, y, .White);
				cursorX = x;
				cursorY = y;

			case .STBTT_vcurve:
				if (contour != null)
					msdf_contour_add_quadratic_edge(contour, cursorX, cursorY,
						(double)vertex.cx, (double)vertex.cy, x, y, .White);
				cursorX = x;
				cursorY = y;

			case .STBTT_vcubic:
				if (contour != null)
					msdf_contour_add_cubic_edge(contour, cursorX, cursorY,
						(double)vertex.cx, (double)vertex.cy,
						(double)vertex.cx1, (double)vertex.cy1, x, y, .White);
				cursorX = x;
				cursorY = y;

			default:
			}
		}

		return msdf_shape_contour_count(shape) > 0;
	}
}
