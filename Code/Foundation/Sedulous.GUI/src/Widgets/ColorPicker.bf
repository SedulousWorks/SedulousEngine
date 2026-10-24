using System;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Colour widgets. They edit the values an authored Color holds, which are sRGB (the engine's rule:
// what a picker and a hex code show; the renderer decodes to linear), so HSV here is over sRGB
// values and linear is never stored.
//   - ColorSwatch: a colour over a checkerboard (its alpha seen), or hatched when mixed (several
//     objects' colours differing); a click, Return or Space reports it.
//   - ColorPicker: a saturation and value plane, a hue strip, an alpha strip, a hex field (any CSS
//     colour typed: #rgb, #rrggbb, #rrggbbaa, rgb(), a name) and, on the row below it, 0-255 fields
//     for each channel. A drag reports each step (`input`) and its end (`change`); a field reports
//     its commit. The hue is kept where a grey or black has none, so dragging back out of the
//     corner keeps it.

/// A colour as hue (0-360), saturation, value and alpha, each of 0-1 but the hue.
struct ColorHsv
{
	public float H = 0.0f;
	public float S = 0.0f;
	public float V = 0.0f;
	public float A = 1.0f;

	public this() { }

	public this(float h, float s, float v, float a)
	{
		H = h;
		S = s;
		V = v;
		A = a;
	}
}

static
{
	/// `color` as HSV of its (sRGB) values; `hue` is kept where it has none (a grey).
	public static ColorHsv ToHsv(Color color, float hue = 0.0f)
	{
		let r = Math.Clamp(color.R, 0.0f, 1.0f);
		let g = Math.Clamp(color.G, 0.0f, 1.0f);
		let b = Math.Clamp(color.B, 0.0f, 1.0f);
		let high = Math.Max(r, Math.Max(g, b));
		let low = Math.Min(r, Math.Min(g, b));
		let span = high - low;
		var outHsv = ColorHsv();
		outHsv.V = high;
		outHsv.S = (high > 0.0f) ? span / high : 0.0f;
		outHsv.A = color.A;
		if (span <= 0.0f)
			outHsv.H = hue;
		else if (high == r)
			outHsv.H = 60.0f * ((g - b) / span) + ((g < b) ? 360.0f : 0.0f);
		else if (high == g)
			outHsv.H = 60.0f * ((b - r) / span + 2.0f);
		else
			outHsv.H = 60.0f * ((r - g) / span + 4.0f);
		return outHsv;
	}

	public static Color FromHsv(ColorHsv hsv)
	{
		let h = hsv.H - 360.0f * Math.Floor(hsv.H / 360.0f);
		let c = hsv.V * hsv.S;
		let sector = h / 60.0f;
		let x = c * (1.0f - Math.Abs(sector - 2.0f * Math.Floor(sector / 2.0f) - 1.0f));
		let m = hsv.V - c;
		float r = 0.0f;
		float g = 0.0f;
		float b = 0.0f;
		switch ((int32)sector % 6)
		{
		case 0:
			r = c;
			g = x;
		case 1:
			r = x;
			g = c;
		case 2:
			g = c;
			b = x;
		case 3:
			g = x;
			b = c;
		case 4:
			r = x;
			b = c;
		default:
			r = c;
			b = x;
		}
		return .(r + m, g + m, b + m, hsv.A);
	}

	/// "#RRGGBB", with "AA" after when `alpha` and it is not opaque, appended to `outText`.
	public static void FormatHexColor(Color color, bool alpha, String outText)
	{
		let packed = color.ToRGBA8();
		let digits = (alpha && ((packed & 0xFF) != 0xFF)) ? 8 : 6;
		let value = (digits == 8) ? packed : packed >> 8;
		outText.Append('#');
		for (int32 i = 0; i < digits; ++i)
		{
			let shift = (int32)((digits - 1 - i) * 4);
			let nibble = (value >> shift) & 0xF;
			outText.Append((nibble < 10) ? (char8)((uint32)'0' + nibble) : (char8)((uint32)'A' + nibble - 10));
		}
	}
}

/// What ColorPicker.bf keeps out of the public surface.
internal static class ColorPickerDetail
{
	/// A checkerboard behind a colour with alpha.
	public static void DrawChecker(DrawContext ctx, Rect @box, float cell = 6.0f)
	{
		ctx.VG.FillRect(@box.ToRectangle(), .(0.85f, 0.85f, 0.85f, 1.0f));
		let dark = Color(0.6f, 0.6f, 0.6f, 1.0f);
		for (float y = 0.0f; y < @box.Height; y += cell)
		{
			for (float x = (((int32)(y / cell) % 2) == 0) ? 0.0f : cell; x < @box.Width; x += cell * 2.0f)
				ctx.VG.FillRect(.(@box.X + x, @box.Y + y, Math.Min(cell, @box.Width - x), Math.Min(cell, @box.Height - y)), dark);
		}
	}

	/// `box` as a path, which the caller deletes.
	public static Path RectPath(Rect @box)
	{
		let pb = scope PathBuilder();
		pb.MoveTo(@box.X, @box.Y);
		pb.LineTo(@box.Right, @box.Y);
		pb.LineTo(@box.Right, @box.Bottom);
		pb.LineTo(@box.X, @box.Bottom);
		pb.Close();
		return pb.ToPath();
	}
}

/// A colour shown: over a checkerboard, or hatched when mixed. Clicked, it says so.
[GuiReflect(true)]
class ColorSwatch : UIWidget
{
	private Color mColor = .(1.0f, 1.0f, 1.0f, 1.0f);
	private bool mMixed = false;
	private bool mShowsAlpha = true;
	private delegate void() mOnClick ~ delete _;

	public this()
	{
		Tag = "colorswatch";
		AccessRoleName = "button"; // a screen reader may press it
		TabFocusable = true;
	}

	/// A screen reader may press it.
	public override bool AccessActivates => true;

	/// Its colour (markup's and a sheet's `color-value`: `color` is its text's).
	[GuiProperty("color-value")]
	public Color ColorValue
	{
		get => mColor;
		set
		{
			mColor = value;
			Invalidate();
		}
	}

	/// Several colours stand behind it that differ: hatched, no colour shown.
	public bool IsMixed
	{
		get => mMixed;
		set
		{
			mMixed = value;
			Invalidate();
		}
	}

	/// Whether its alpha shows (else drawn opaque).
	public bool ShowsAlpha
	{
		get => mShowsAlpha;
		set
		{
			mShowsAlpha = value;
			Invalidate();
		}
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnClick(delegate void() callback)
	{
		delete mOnClick;
		mOnClick = callback;
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		Click();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((e.Target == this) && (e.Modifiers == 0) && ((key == .Return) || (key == .Space)))
		{
			e.Handled = true;
			Click();
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let @box = ContentBounds;
		if (mMixed)
		{
			ctx.VG.FillRect(@box.ToRectangle(), .(0.3f, 0.32f, 0.36f, 1.0f));
			ctx.PushClip(@box);
			let lines = scope PathBuilder();
			for (float x = -@box.Height; x < @box.Width; x += 6.0f)
			{
				lines.MoveTo(@box.X + x, @box.Bottom);
				lines.LineTo(@box.X + x + @box.Height, @box.Y);
			}
			let path = lines.ToPath();
			ctx.VG.StrokePath(path, TextColor, StrokeStyle(1.0f));
			delete path;
			ctx.PopClip();
			return;
		}
		var color = mColor;
		if (mShowsAlpha && (color.A < 1.0f))
			ColorPickerDetail.DrawChecker(ctx, @box);
		else
			color.A = 1.0f;
		ctx.VG.FillRect(@box.ToRectangle(), color);
	}

	private void Click()
	{
		if ((mOnClick != null) && IsTreeEnabled)
			mOnClick();
	}
}

/// A picker's draggable area: the saturation and value plane, or a hue or alpha strip.
class ColorPickerArea : UIWidget
{
	public enum Kind : uint8
	{
		Plane,
		Hue,
		Alpha,
	}

	// Its picker, which holds it.
	private ColorPicker mPicker;
	private ColorPickerArea.Kind mKind;
	private bool mDragging = false;

	public this(ColorPicker picker, ColorPickerArea.Kind kind)
	{
		mPicker = picker;
		mKind = kind;
		Tag = (kind == .Plane) ? "colorplane" : ((kind == .Hue) ? "huestrip" : "alphastrip");
	}

	/// Which area it is.
	public ColorPickerArea.Kind AreaKind => mKind;

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		mDragging = true;
		At(e.Position);
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (mDragging)
			At(e.Position);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (!mDragging)
			return;
		mDragging = false;
		let local = ConvertToNodeSpace(e.Position); // events come in screen space
		let @box = ContentBounds;
		float x = (@box.Width > 0.0f) ? (local.X - @box.X) / @box.Width : 0.0f;
		if ((mKind != .Plane) && IsRightToLeft)
			x = 1.0f - x; // a strip runs from the inline start
		mPicker.[Friend]Dragged(mKind, x, (@box.Height > 0.0f) ? (local.Y - @box.Y) / @box.Height : 0.0f, true);
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mDragging = false;
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let @box = ContentBounds;
		let hsv = mPicker.Hsv;
		let rtl = IsRightToLeft && (mKind != .Plane);
		let marker = Color(1.0f, 1.0f, 1.0f, 1.0f);
		let edge = Color(0.0f, 0.0f, 0.0f, 0.6f);
		if (mKind == .Plane)
		{
			// The hue at full, white across from the left, black up from the bottom.
			ctx.VG.FillRect(@box.ToRectangle(), FromHsv(.(hsv.H, 1.0f, 1.0f, 1.0f)));
			let planePath = ColorPickerDetail.RectPath(@box);
			defer delete planePath;
			let white = scope VGLinearGradientFill(.(@box.X, @box.Y), .(@box.Right, @box.Y));
			white.AddStop(0.0f, .(1.0f, 1.0f, 1.0f, 1.0f));
			white.AddStop(1.0f, .(1.0f, 1.0f, 1.0f, 0.0f));
			ctx.VG.FillPath(planePath, white);
			let black = scope VGLinearGradientFill(.(@box.X, @box.Y), .(@box.X, @box.Bottom));
			black.AddStop(0.0f, .(0.0f, 0.0f, 0.0f, 0.0f));
			black.AddStop(1.0f, .(0.0f, 0.0f, 0.0f, 1.0f));
			ctx.VG.FillPath(planePath, black);
			let spot = Float2(@box.X + hsv.S * @box.Width, @box.Y + (1.0f - hsv.V) * @box.Height);
			let ring = scope PathBuilder();
			ShapeBuilder.BuildCircle(spot, 5.0f, ring);
			let ringPath = ring.ToPath();
			defer delete ringPath;
			ctx.VG.StrokePath(ringPath, edge, StrokeStyle(3.0f));
			ctx.VG.StrokePath(ringPath, marker, StrokeStyle(1.5f));
			return;
		}
		let from = Float2(rtl ? @box.Right : @box.X, @box.Y);
		let to = Float2(rtl ? @box.X : @box.Right, @box.Y);
		float at = 0.0f;
		let rect = ColorPickerDetail.RectPath(@box);
		defer delete rect;
		if (mKind == .Hue)
		{
			let hues = scope VGLinearGradientFill(from, to);
			for (int32 i = 0; i <= 6; ++i)
				hues.AddStop((float)i / 6.0f, FromHsv(.((float)i * 60.0f, 1.0f, 1.0f, 1.0f)));
			ctx.VG.FillPath(rect, hues);
			at = hsv.H / 360.0f;
		}
		else
		{
			ColorPickerDetail.DrawChecker(ctx, @box, 7.0f);
			var opaque = FromHsv(hsv);
			opaque.A = 1.0f;
			var clear = opaque;
			clear.A = 0.0f;
			let alpha = scope VGLinearGradientFill(from, to);
			alpha.AddStop(0.0f, clear);
			alpha.AddStop(1.0f, opaque);
			ctx.VG.FillPath(rect, alpha);
			at = hsv.A;
		}
		let x = rtl ? @box.Right - at * @box.Width : @box.X + at * @box.Width;
		let handle = Rect(x - 2.0f, @box.Y - 1.0f, 4.0f, @box.Height + 2.0f);
		ctx.VG.FillRect(.(handle.X - 1.0f, handle.Y - 1.0f, handle.Width + 2.0f, handle.Height + 2.0f), edge);
		ctx.VG.FillRect(handle.ToRectangle(), marker);
	}

	private void At(Float2 screen)
	{
		let local = ConvertToNodeSpace(screen);
		let @box = ContentBounds;
		float x = (@box.Width > 0.0f) ? (local.X - @box.X) / @box.Width : 0.0f;
		if ((mKind != .Plane) && IsRightToLeft)
			x = 1.0f - x;
		mPicker.[Friend]Dragged(mKind, x, (@box.Height > 0.0f) ? (local.Y - @box.Y) / @box.Height : 0.0f, false);
	}
}

[GuiReflect(true)]
class ColorPicker : UIWidget
{
	private ColorHsv mHsv = .(0.0f, 0.0f, 1.0f, 1.0f);
	private bool mShowsAlpha = true;
	// The fields are being set from the colour.
	private bool mShowing = false;
	// Its parts, its children; a reference held to each.
	private ColorPickerArea mPlane = null ~ _?.ReleaseRef();
	private ColorPickerArea mHueStrip = null ~ _?.ReleaseRef();
	private ColorPickerArea mAlphaStrip = null ~ _?.ReleaseRef();
	private UIWidget mFields = null ~ _?.ReleaseRef();
	private TextField mHex = null ~ _?.ReleaseRef();
	private NumberField[4] mChannels;
	private Label[4] mChannelLabels;
	private delegate void(Color color) mOnChanging ~ delete _;
	private delegate void(Color color) mOnChanged ~ delete _;

	public this()
	{
		Tag = "colorpicker";
		AccessRoleName = "group"; // what a screen reader takes it for
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.RowGap = 8.0f;
			});
		mPlane = new ColorPickerArea(this, .Plane);
		mPlane.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(140.0f); });
		AddChild(mPlane);
		mHueStrip = new ColorPickerArea(this, .Hue);
		mHueStrip.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(14.0f); });
		AddChild(mHueStrip);
		mAlphaStrip = new ColorPickerArea(this, .Alpha);
		mAlphaStrip.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(14.0f); });
		AddChild(mAlphaStrip);

		// The hex code on a row of its own, the channels on the next: each field wide enough to
		// show its number beside its arrows.
		mHex = new TextField();
		mHex.AddClass("hex");
		mHex.SetOnTextChanged(new (text) => { TypedHex(text); });
		AddChild(mHex);
		mFields = new UIWidget();
		mFields.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.ColumnGap = 4.0f;
				s.AlignItems = .Center;
			});
		AddChild(mFields);
		String[4] names = .("R", "G", "B", "A");
		for (int32 i = 0; i < 4; i++)
		{
			let label = new Label();
			label.Text = names[i];
			label.HitTestVisible = false;
			mFields.AddChild(label);
			mChannelLabels[i] = label;
			let field = new NumberField();
			field.IsInteger = true;
			field.Min = 0.0;
			field.Max = 255.0;
			field.Step = 1.0;
			field.EditLayoutStyle(scope (s) =>
				{
					s.Grow = 1.0f;
					s.Basis = LayoutLength.Px(0.0f);
					s.MinWidth = LayoutLength.Px(0.0f);
				});
			let channel = i;
			field.SetOnValueChanging(new (value) => { TypedChannel(channel, value, false); });
			field.SetOnValueChanged(new (value) => { TypedChannel(channel, value, true); });
			mFields.AddChild(field);
			mChannels[i] = field;
		}
		ShowFields();
	}

	public ~this()
	{
		for (int i = 0; i < 4; i++)
		{
			mChannels[i]?.ReleaseRef();
			mChannelLabels[i]?.ReleaseRef();
		}
	}

	// === The colour ===

	/// The colour. Set from code: shown, nothing reported (markup's and a sheet's `color-value`:
	/// `color` is its text's).
	[GuiProperty("color-value", .TwoWay)]
	public Color ColorValue
	{
		get => FromHsv(mHsv);
		set
		{
			mHsv = ToHsv(value, mHsv.H);
			ShowFields();
			Invalidate();
		}
	}

	public ColorHsv Hsv => mHsv;

	/// Whether it edits alpha (its strip and field show).
	[GuiProperty("shows-alpha")]
	public bool ShowsAlpha
	{
		get => mShowsAlpha;
		set
		{
			mShowsAlpha = value;
			mAlphaStrip.Displayed = value;
			mChannels[3].Displayed = value;
			mChannelLabels[3].Displayed = value;
			if (!value)
				mHsv.A = 1.0f;
			ShowFields();
		}
	}

	/// Each step of a drag (or a field's scrub), as it goes. OWNERSHIP of `callback` transfers.
	public void SetOnColorChanging(delegate void(Color color) callback)
	{
		delete mOnChanging;
		mOnChanging = callback;
	}

	/// A change made: a drag let go, a field committed. OWNERSHIP of `callback` transfers.
	public void SetOnColorChanged(delegate void(Color color) callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	public ColorPickerArea Plane => mPlane;
	public ColorPickerArea HueStrip => mHueStrip;
	public ColorPickerArea AlphaStrip => mAlphaStrip;
	public TextField HexField => mHex;
	public NumberField GetChannelField(int32 channel) => ((channel >= 0) && (channel < 4)) ? mChannels[channel] : null;

	// A drag's step in an area: `x` and `y` across it, 0-1.
	private void Dragged(ColorPickerArea.Kind kind, float x, float y, bool done)
	{
		let cx = Math.Clamp(x, 0.0f, 1.0f);
		let cy = Math.Clamp(y, 0.0f, 1.0f);
		if (kind == .Plane)
		{
			mHsv.S = cx;
			mHsv.V = 1.0f - cy;
		}
		else if (kind == .Hue)
		{
			mHsv.H = cx * 360.0f;
		}
		else
		{
			mHsv.A = cx;
		}
		ShowFields();
		Invalidate();
		Report(done);
	}

	private void TypedHex(StringView text)
	{
		let parsed = ParseColor(ParseUtil.Trim(text));
		if (!parsed.HasValue)
		{
			ShowFields(); // not a colour: what it was
			return;
		}
		var color = parsed.Value;
		if (!mShowsAlpha)
			color.A = 1.0f;
		mHsv = ToHsv(color, mHsv.H);
		ShowFields();
		Invalidate();
		Report(true);
	}

	private void TypedChannel(int32 channel, double value, bool done)
	{
		if (mShowing)
			return;
		var color = FromHsv(mHsv);
		let typed = (float)(value / 255.0);
		switch (channel)
		{
		case 0: color.R = typed;
		case 1: color.G = typed;
		case 2: color.B = typed;
		default: color.A = typed;
		}
		mHsv = ToHsv(color, mHsv.H);
		ShowFields(channel);
		Invalidate();
		Report(done);
	}

	private void Report(bool done)
	{
		let color = FromHsv(mHsv);
		if (done)
		{
			if (mOnChanged != null)
				mOnChanged(color);
			SendEvent(scope Event(.Changed, this));
		}
		else
		{
			if (mOnChanging != null)
				mOnChanging(color);
			SendEvent(scope Event(.Input, this));
		}
	}

	// The fields show the colour (all but `except`, being typed into).
	private void ShowFields(int32 except = -1)
	{
		mShowing = true;
		let color = FromHsv(mHsv);
		let hex = scope String();
		FormatHexColor(color, mShowsAlpha, hex);
		mHex.Text = hex;
		float[4] channels = .(color.R, color.G, color.B, color.A);
		for (int32 i = 0; i < 4; i++)
		{
			if (i != except)
				mChannels[i].Value = (double)(Math.Clamp(channels[i], 0.0f, 1.0f) * 255.0f + 0.5f);
		}
		mShowing = false;
		mPlane.Invalidate();
		mHueStrip.Invalidate();
		mAlphaStrip.Invalidate();
	}
}
