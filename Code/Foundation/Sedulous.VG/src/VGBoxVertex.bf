using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// One corner of an analytic box (VGContext.DrawBox, VGDrawMode.Box).
///
/// Every vertex carries the whole box, so the fragment shader evaluates its fill and border from
/// one signed distance with no tessellation. Local is the point relative to the box's centre in
/// the box's own units, which interpolated stays exact under any affine transform; the rest is
/// the same at every corner.
[CRepr]
struct VGBoxVertex
{
	/// The device position: the box's quad, grown for the antialiasing ramp.
	public Float2 Position = .Zero;
	/// Relative to the box's centre, in box units.
	public Float2 Local = .Zero;
	/// Half the box's size, in box units.
	public Float2 HalfSize = .Zero;
	/// The corner radii: top left, top right, bottom right, bottom left.
	public Float4 Radii = .Zero;
	/// The border widths: top, right, bottom, left.
	public Float4 Borders = .Zero;
	/// The fill, authored sRGB with the opacity applied.
	public Color Fill = .(0, 0, 0, 0);
	/// The border's colour, drawn over the fill.
	public Color BorderColor = .(0, 0, 0, 0);

	/// The stride the box pipeline's vertex layout declares: 8 + 8 + 8 + 16 + 16 + 16 + 16.
	public const int32 SizeInBytes = 88;

	public this() {}
}
