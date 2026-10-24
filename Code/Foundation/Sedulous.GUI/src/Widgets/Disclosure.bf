using System;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// The disclosure chevron: the triangle that says whether something is open, pointing right when
// closed and down when open. An expander's header and a tree's rows draw the same one.

static
{
	/// Draws the chevron centred in `area`, as large as fits up to 8 pixels across; closed, it
	/// points toward the inline end (left in right to left).
	public static void DrawDisclosure(DrawContext ctx, Rect area, bool open, Color color, bool rightToLeft)
	{
		let s = Math.Min(4.0f, Math.Min(area.Width, area.Height) * 0.4f); // half its size
		let cx = area.X + area.Width * 0.5f;
		let cy = area.Y + area.Height * 0.5f;
		let pb = scope PathBuilder();
		if (open)
		{
			pb.MoveTo(cx - s, cy - s * 0.5f);
			pb.LineTo(cx + s, cy - s * 0.5f);
			pb.LineTo(cx, cy + s * 0.75f);
		}
		else
		{
			let way = rightToLeft ? -1.0f : 1.0f;
			pb.MoveTo(cx - way * s * 0.5f, cy - s);
			pb.LineTo(cx + way * s * 0.75f, cy);
			pb.LineTo(cx - way * s * 0.5f, cy + s);
		}
		pb.Close();
		let path = pb.ToPath();
		ctx.VG.FillPath(path, color);
		delete path;
	}
}
