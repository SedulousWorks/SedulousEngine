using System;

namespace Sedulous.Core;

/// How a content box is placed inside an outer Region, and the maps between Region
/// space and content space.
///
/// Pure geometry: the outer rect is in the caller's coordinate space and is not
/// inherently a window. The renderer places the image with DstRect and SrcRect; input
/// remaps points with ToContent and FromContent. Both read the same computation, so the
/// two can never drift apart.
struct ContentFit
{
	/// The outer rect, in Region space.
	public Rectangle Region = .(0, 0, 0, 0);
	/// The logical content resolution.
	public Float2 ContentSize = .(0, 0);
	public FitMode Mode = .Stretch;

	public this() { }
	public this(Rectangle region, Float2 contentSize, FitMode mode = .Stretch)
	{
		this.Region = region;
		this.ContentSize = contentSize;
		this.Mode = mode;
	}

	/// Where the content is drawn within the Region, in Region space. For Letterbox and
	/// IntegerScale this is the centred, aspect-preserved sub-rect and the rest is bars;
	/// for Stretch and Crop it is the whole Region.
	public Rectangle DstRect() => Compute().dst;

	/// Which content texels are sampled, within [0, ContentSize]. For Crop this is the
	/// centred, aspect-preserved slice; otherwise the whole content.
	public Rectangle SrcRect() => Compute().src;

	/// Region space to content space. Returns false when the point is outside the drawn
	/// content, such as on a letterbox bar, which is the no-hit contract for input.
	public bool ToContent(Float2 pt, out Float2 result)
	{
		result = default;

		let p = Compute();
		if ((p.dst.Width <= 0.0f) || (p.dst.Height <= 0.0f))
			return false;
		if (!p.dst.Contains(pt))
			return false;

		let rx = (pt.X - p.dst.X) / p.dst.Width;
		let ry = (pt.Y - p.dst.Y) / p.dst.Height;
		result = .(p.src.X + rx * p.src.Width, p.src.Y + ry * p.src.Height);
		return true;
	}

	/// Content space to Region space, the inverse of ToContent. Used to place an IME
	/// caret rect in window space for a text field inside a fitted surface.
	public Float2 FromContent(Float2 pt)
	{
		let p = Compute();
		let rx = (p.src.Width != 0.0f) ? (pt.X - p.src.X) / p.src.Width : 0.0f;
		let ry = (p.src.Height != 0.0f) ? (pt.Y - p.src.Y) / p.src.Height : 0.0f;
		return .(p.dst.X + rx * p.dst.Width, p.dst.Y + ry * p.dst.Height);
	}

	/// Content units per Region unit, for scaling relative input such as a mouse delta
	/// so that sensitivity does not depend on Region size. Per axis, and equal on both
	/// for the aspect-preserving modes.
	public Float2 Scale()
	{
		let p = Compute();
		return .(
			(p.dst.Width != 0.0f) ? p.src.Width / p.dst.Width : 0.0f,
			(p.dst.Height != 0.0f) ? p.src.Height / p.dst.Height : 0.0f);
	}

	private struct Placement
	{
		public Rectangle dst;
		public Rectangle src;

		public this(Rectangle dst, Rectangle src) { this.dst = dst; this.src = src; }
	}

	private Placement Compute()
	{
		let cw = ContentSize.X;
		let ch = ContentSize.Y;
		let fullSrc = Rectangle(0.0f, 0.0f, cw, ch);

		if ((cw <= 0.0f) || (ch <= 0.0f) || (Region.Width <= 0.0f) || (Region.Height <= 0.0f))
			return .(Region, fullSrc);

		let sx = Region.Width / cw;
		let sy = Region.Height / ch;

		switch (Mode)
		{
		case .Letterbox, .IntegerScale:
			var s = (sx < sy) ? sx : sy;   // fit inside
			if (Mode == .IntegerScale)
			{
				s = (float)(int32)s;       // floor, since s is positive here
				if (s < 1.0f)
					s = 1.0f;
			}
			let dw = cw * s;
			let dh = ch * s;
			let dx = Region.X + (Region.Width - dw) * 0.5f;
			let dy = Region.Y + (Region.Height - dh) * 0.5f;
			return .(Rectangle(dx, dy, dw, dh), fullSrc);

		case .Crop:
			let s = (sx > sy) ? sx : sy;                 // fill, cropping the overflow
			let vw = Region.Width / s;                   // the visible content size
			let vh = Region.Height / s;
			let sxo = (cw - vw) * 0.5f;                  // a centred slice
			let syo = (ch - vh) * 0.5f;
			return .(Region, Rectangle(sxo, syo, vw, vh));

		case .Stretch:
			return .(Region, fullSrc);
		}
	}
}
