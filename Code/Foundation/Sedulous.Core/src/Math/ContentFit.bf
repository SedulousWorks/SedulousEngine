using System;

namespace Sedulous.Core;

/// How a content box is placed inside an outer Region, and the maps between Region
/// space and content space.
///
/// Pure geometry: the outer rect is in the caller's coordinate space and is not
/// inherently a window. The renderer places the image with DstRect and SrcRect; input
/// remaps points with ToContent and FromContent. Both read the same computation, so the
/// two can never drift apart.
///
/// The content may be presented TURNED (Rotation, clockwise in quarters): a landscape game on a
/// portrait screen is shown turned a quarter. The fit is computed in the region turned back (a
/// quarter turn swaps its sides), so a 1080 x 1920 region fits 1920 x 1080 content exactly;
/// DstRect is the axis-aligned rectangle the turned content covers, and the point maps turn
/// through it. None is the unturned behaviour, unchanged.
struct ContentFit
{
	/// The outer rect, in Region space.
	public Rectangle Region = .(0, 0, 0, 0);
	/// The logical content resolution.
	public Float2 ContentSize = .(0, 0);
	public FitMode Mode = .Stretch;
	public ContentRotation Rotation = .None;

	public this() { }
	public this(Rectangle region, Float2 contentSize, FitMode mode = .Stretch, ContentRotation rotation = .None)
	{
		this.Region = region;
		this.ContentSize = contentSize;
		this.Mode = mode;
		this.Rotation = rotation;
	}

	/// The turn a game of `orientation` takes on a `width` x `height` window: none when it
	/// matches (or takes any shape), else three quarters, the game's top on the window's left (a
	/// phone held upright shows a landscape game as it shows on the phone turned
	/// counter-clockwise, Android's primary landscape).
	public static ContentRotation TurnFor(ScreenOrientation orientation, float width, float height)
	{
		let tall = height > width;
		let wide = width > height;
		if (((orientation == .Landscape) && tall) || ((orientation == .Portrait) && wide))
			return .ThreeQuarter;
		return .None;
	}

	/// Where the content is drawn within the Region, in Region space. For Letterbox and
	/// IntegerScale this is the centred, aspect-preserved sub-rect and the rest is bars;
	/// for Stretch and Crop it is the whole Region.
	public Rectangle DstRect()
	{
		// The placement's rectangle in the turned-back frame, its corners turned onto the Region.
		let d = Compute().dst;
		let a = FromLocal(.(d.X, d.Y));
		let b = FromLocal(.(d.X + d.Width, d.Y + d.Height));
		let x0 = Math.Min(a.X, b.X);
		let y0 = Math.Min(a.Y, b.Y);
		return .(x0, y0, Math.Max(a.X, b.X) - x0, Math.Max(a.Y, b.Y) - y0);
	}

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
		let local = ToLocal(pt);
		if (!p.dst.Contains(local))
			return false;

		let rx = (local.X - p.dst.X) / p.dst.Width;
		let ry = (local.Y - p.dst.Y) / p.dst.Height;
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
		return FromLocal(.(p.dst.X + rx * p.dst.Width, p.dst.Y + ry * p.dst.Height));
	}

	/// Content units per Region unit, per CONTENT axis, and equal on both for the
	/// aspect-preserving modes. For a relative movement (a mouse delta) use ToContentDelta,
	/// which turns it as well.
	public Float2 Scale()
	{
		let p = Compute();
		return .(
			(p.dst.Width != 0.0f) ? p.src.Width / p.dst.Width : 0.0f,
			(p.dst.Height != 0.0f) ? p.src.Height / p.dst.Height : 0.0f);
	}

	/// A Region space movement (a mouse delta) in the content's units and frame: turned back
	/// with the content, then scaled, so a look speed keeps its direction and does not depend
	/// on the Region's size.
	public Float2 ToContentDelta(Float2 delta)
	{
		let turned = TurnBack(delta);
		let scale = Scale();
		return .(turned.X * scale.X, turned.Y * scale.Y);
	}

	/// Whether the turn swaps the Region's sides (a quarter either way).
	private bool SidesSwap => (Rotation == .Quarter) || (Rotation == .ThreeQuarter);

	/// The Region turned back: the frame the content is fitted in, its origin at (0, 0).
	private Float2 LocalSize => SidesSwap ? .(Region.Height, Region.Width) : .(Region.Width, Region.Height);

	/// A direction in the Region turned back into the local frame (no translation).
	private Float2 TurnBack(Float2 d)
	{
		switch (Rotation)
		{
		case .Quarter: return .(d.Y, -d.X);
		case .Half: return .(-d.X, -d.Y);
		case .ThreeQuarter: return .(-d.Y, d.X);
		case .None: return d;
		}
	}

	/// A Region space point in the local frame (the Region turned back).
	private Float2 ToLocal(Float2 pt)
	{
		let x = pt.X - Region.X;
		let y = pt.Y - Region.Y;
		let size = LocalSize;
		switch (Rotation)
		{
		case .Quarter: return .(y, size.Y - x);
		case .Half: return .(size.X - x, size.Y - y);
		case .ThreeQuarter: return .(size.X - y, x);
		case .None: return .(x, y);
		}
	}

	/// A local frame point in Region space, the inverse of ToLocal.
	private Float2 FromLocal(Float2 pt)
	{
		let size = LocalSize;
		switch (Rotation)
		{
		case .Quarter: return .(Region.X + size.Y - pt.Y, Region.Y + pt.X);
		case .Half: return .(Region.X + size.X - pt.X, Region.Y + size.Y - pt.Y);
		case .ThreeQuarter: return .(Region.X + pt.Y, Region.Y + size.X - pt.X);
		case .None: return .(Region.X + pt.X, Region.Y + pt.Y);
		}
	}

	private struct Placement
	{
		public Rectangle dst;
		public Rectangle src;

		public this(Rectangle dst, Rectangle src) { this.dst = dst; this.src = src; }
	}

	/// The placement in the local frame (the Region turned back, at the origin).
	private Placement Compute()
	{
		let size = LocalSize;
		let frame = Rectangle(0.0f, 0.0f, size.X, size.Y);
		let cw = ContentSize.X;
		let ch = ContentSize.Y;
		let fullSrc = Rectangle(0.0f, 0.0f, cw, ch);

		if ((cw <= 0.0f) || (ch <= 0.0f) || (frame.Width <= 0.0f) || (frame.Height <= 0.0f))
			return .(frame, fullSrc);

		let sx = frame.Width / cw;
		let sy = frame.Height / ch;

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
			let dx = (frame.Width - dw) * 0.5f;
			let dy = (frame.Height - dh) * 0.5f;
			return .(Rectangle(dx, dy, dw, dh), fullSrc);

		case .Crop:
			let s = (sx > sy) ? sx : sy;                 // fill, cropping the overflow
			let vw = frame.Width / s;                    // the visible content size
			let vh = frame.Height / s;
			let sxo = (cw - vw) * 0.5f;                  // a centred slice
			let syo = (ch - vh) * 0.5f;
			return .(frame, Rectangle(sxo, syo, vw, vh));

		case .Stretch:
			return .(frame, fullSrc);
		}
	}
}
