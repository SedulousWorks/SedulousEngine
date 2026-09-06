using System;

namespace Sedulous.Core;

/// How a content box is placed inside an outer region, and the maps between region
/// space and content space.
///
/// Pure geometry: the outer rect is in the caller's coordinate space and is not
/// inherently a window. The renderer places the image with DstRect and SrcRect; input
/// remaps points with ToContent and FromContent. Both read the same computation, so the
/// two can never drift apart.
struct ContentFit
{
	/// The outer rect, in region space.
	public Rectangle region = .(0, 0, 0, 0);
	/// The logical content resolution.
	public Float2 contentSize = .(0, 0);
	public FitMode mode = .Stretch;

	public this() { }
	public this(Rectangle region, Float2 contentSize, FitMode mode = .Stretch)
	{
		this.region = region;
		this.contentSize = contentSize;
		this.mode = mode;
	}

	/// Where the content is drawn within the region, in region space. For Letterbox and
	/// IntegerScale this is the centred, aspect-preserved sub-rect and the rest is bars;
	/// for Stretch and Crop it is the whole region.
	public Rectangle DstRect() => Compute().dst;

	/// Which content texels are sampled, within [0, contentSize]. For Crop this is the
	/// centred, aspect-preserved slice; otherwise the whole content.
	public Rectangle SrcRect() => Compute().src;

	/// Region space to content space. Returns false when the point is outside the drawn
	/// content, such as on a letterbox bar, which is the no-hit contract for input.
	public bool ToContent(Float2 pt, out Float2 result)
	{
		result = default;

		let p = Compute();
		if ((p.dst.width <= 0.0f) || (p.dst.height <= 0.0f))
			return false;
		if (!p.dst.Contains(pt))
			return false;

		let rx = (pt.x - p.dst.x) / p.dst.width;
		let ry = (pt.y - p.dst.y) / p.dst.height;
		result = .(p.src.x + rx * p.src.width, p.src.y + ry * p.src.height);
		return true;
	}

	/// Content space to region space, the inverse of ToContent. Used to place an IME
	/// caret rect in window space for a text field inside a fitted surface.
	public Float2 FromContent(Float2 pt)
	{
		let p = Compute();
		let rx = (p.src.width != 0.0f) ? (pt.x - p.src.x) / p.src.width : 0.0f;
		let ry = (p.src.height != 0.0f) ? (pt.y - p.src.y) / p.src.height : 0.0f;
		return .(p.dst.x + rx * p.dst.width, p.dst.y + ry * p.dst.height);
	}

	/// Content units per region unit, for scaling relative input such as a mouse delta
	/// so that sensitivity does not depend on region size. Per axis, and equal on both
	/// for the aspect-preserving modes.
	public Float2 Scale()
	{
		let p = Compute();
		return .(
			(p.dst.width != 0.0f) ? p.src.width / p.dst.width : 0.0f,
			(p.dst.height != 0.0f) ? p.src.height / p.dst.height : 0.0f);
	}

	private struct Placement
	{
		public Rectangle dst;
		public Rectangle src;

		public this(Rectangle dst, Rectangle src) { this.dst = dst; this.src = src; }
	}

	private Placement Compute()
	{
		let cw = contentSize.x;
		let ch = contentSize.y;
		let fullSrc = Rectangle(0.0f, 0.0f, cw, ch);

		if ((cw <= 0.0f) || (ch <= 0.0f) || (region.width <= 0.0f) || (region.height <= 0.0f))
			return .(region, fullSrc);

		let sx = region.width / cw;
		let sy = region.height / ch;

		switch (mode)
		{
		case .Letterbox, .IntegerScale:
			var s = (sx < sy) ? sx : sy;   // fit inside
			if (mode == .IntegerScale)
			{
				s = (float)(int32)s;       // floor, since s is positive here
				if (s < 1.0f)
					s = 1.0f;
			}
			let dw = cw * s;
			let dh = ch * s;
			let dx = region.x + (region.width - dw) * 0.5f;
			let dy = region.y + (region.height - dh) * 0.5f;
			return .(Rectangle(dx, dy, dw, dh), fullSrc);

		case .Crop:
			let s = (sx > sy) ? sx : sy;                 // fill, cropping the overflow
			let vw = region.width / s;                   // the visible content size
			let vh = region.height / s;
			let sxo = (cw - vw) * 0.5f;                  // a centred slice
			let syo = (ch - vh) * 0.5f;
			return .(region, Rectangle(sxo, syo, vw, vh));

		case .Stretch:
			return .(region, fullSrc);
		}
	}
}
