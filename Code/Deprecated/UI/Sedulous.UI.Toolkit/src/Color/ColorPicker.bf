using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The colour dialog: a saturation and value square, a hue strip, an alpha strip, two preview
/// swatches, a hex field and three channel fields.
///
/// HUE, SATURATION AND VALUE are the state, not RGB, because hue has to survive the round trip.
/// Dragging value down to black and back up in RGB would lose which colour it was; holding HSV
/// means black remembers its hue.
///
/// Every control writes into that one state and then every control is rewritten from it, under
/// a guard so the rewrite is not read back as another edit.
class ColorPicker : ViewGroup, IHSVSource
{
	public Event<delegate void(ColorPicker, Color)> OnColorChanged ~ _.Dispose();

	private float mHue = 0.0f;        // degrees, 0 to 360
	private float mSaturation = 1.0f; // 0 to 1
	private float mValue = 1.0f;      // 0 to 1
	private float mAlpha = 1.0f;      // 0 to 1
	private Color mOriginalColor = Color.White;
	private bool mSyncing = false;

	/// BORROWED: the child tree owns them all.
	private SVSquareView mSVSquare = null;
	private HueStripView mHueStrip = null;
	private AlphaStripView mAlphaStrip = null;
	private EditText mHexInput = null;
	private NumericField mRField = null;
	private NumericField mGField = null;
	private NumericField mBField = null;
	private ColorView mPreviewCurrent = null;
	private ColorView mPreviewOriginal = null;

	private float mSquareSize = 180.0f;
	private float mStripWidth = 20.0f;
	private float mGap = 8.0f;

	public this()
	{
		mSVSquare = new SVSquareView(this);
		AddView(mSVSquare);

		mHueStrip = new HueStripView(this);
		AddView(mHueStrip);

		mAlphaStrip = new AlphaStripView(this);
		AddView(mAlphaStrip);

		mPreviewCurrent = new ColorView();
		mPreviewCurrent.Color.Value = Color.White;
		AddView(mPreviewCurrent);

		mPreviewOriginal = new ColorView();
		mPreviewOriginal.Color.Value = Color.White;
		AddView(mPreviewOriginal);

		mHexInput = new EditText();
		mHexInput.SetPlaceholder("#RRGGBB");
		mHexInput.MaxLength.Value = 7;
		// COMMIT, not text changed: Return and typing then clicking away both apply, while a
		// half typed hex does not repaint the dialog on every keystroke.
		mHexInput.OnCommit.Add(new (sender) => { OnHexSubmit(); });
		AddView(mHexInput);

		mRField = MakeChannelField();
		mGField = MakeChannelField();
		mBField = MakeChannelField();

		mOriginalColor = CurrentColor;
		SyncViewsFromHSV();
	}

	private NumericField MakeChannelField()
	{
		let field = new NumericField();
		field.SetMin(0);
		field.SetMax(255);
		field.SetStep(1);
		field.SetValue(255);
		field.OnValueChanged.Add(new (sender, value) => { SyncFromRGB(); });
		AddView(field);
		return field;
	}

	// ---- IHSVSource, EXPLICIT so the components stay off the picker's public surface ---------

	float IHSVSource.Hue { get => mHue; set => mHue = value; }
	float IHSVSource.Saturation { get => mSaturation; set => mSaturation = value; }
	float IHSVSource.Value { get => mValue; set => mValue = value; }
	float IHSVSource.Alpha { get => mAlpha; set => mAlpha = value; }

	void IHSVSource.OnHSVChangedBySurface() => SyncFromHSV();

	// ---------------------------------------------------------------------------------------------

	public Color CurrentColor => HSVToRGB(mHue, mSaturation, mValue, mAlpha);

	public void SetColor(Color color)
	{
		if (mSyncing)
			return;

		mSyncing = true;
		mAlpha = color.A;
		RGBToHSV(color.R, color.G, color.B, out mHue, out mSaturation, out mValue);
		SyncViewsFromHSV();
		mSyncing = false;
	}

	/// What the swatch on the right shows: where the colour started, so a long fiddle can be
	/// compared against it.
	public void SetOriginalColor(Color color)
	{
		mOriginalColor = color;
		mPreviewOriginal.Color.Value = color;
	}

	public Color OriginalColor => mOriginalColor;

	// ---- Colour space ---------------------------------------------------------------------------

	public static Color HSVToRGB(float h, float s, float v, float a = 1.0f)
	{
		let chroma = v * s;
		let sector = h / 60.0f;
		// The C uses fmod here; hue is never negative, so a floor based remainder is the same
		// thing and Core carries no fmod.
		let withinPair = sector - (2.0f * Floor(sector / 2.0f));
		let secondary = chroma * (1.0f - Abs(withinPair - 1.0f));
		let match = v - chroma;

		var r = 0.0f;
		var g = 0.0f;
		var b = 0.0f;

		if (sector < 1) { r = chroma; g = secondary; }
		else if (sector < 2) { r = secondary; g = chroma; }
		else if (sector < 3) { g = chroma; b = secondary; }
		else if (sector < 4) { g = secondary; b = chroma; }
		else if (sector < 5) { r = secondary; b = chroma; }
		else { r = chroma; b = secondary; }

		return .(r + match, g + match, b + match, a);
	}

	public static void RGBToHSV(float r, float g, float b, out float h, out float s, out float v)
	{
		let cMax = Max(r, Max(g, b));
		let cMin = Min(r, Min(g, b));
		let delta = cMax - cMin;

		v = cMax;
		s = (cMax == 0.0f) ? 0.0f : (delta / cMax);

		// Each ratio below is bounded by one, because the numerator is a difference of two
		// channels and the denominator is the whole spread. The C wraps them in fmod against
		// six, which can never do anything, so it is left out.
		if (delta == 0.0f)
			h = 0.0f;
		else if (cMax == r)
			h = 60.0f * ((g - b) / delta);
		else if (cMax == g)
			h = 60.0f * (((b - r) / delta) + 2.0f);
		else
			h = 60.0f * (((r - g) / delta) + 4.0f);

		if (h < 0.0f)
			h += 360.0f;
	}

	// ---- Drawing and layout ---------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color.Rgb(42, 44, 54));

		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let inputsWidth = 80.0f;
		let totalWidth = mSquareSize + mGap + mStripWidth + mGap + mStripWidth + mGap + inputsWidth;
		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(mSquareSize));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// The square is SQUARE, so a short dialog shrinks it rather than stretching it.
		let squareSize = Min(mSquareSize, height);
		var x = 0.0f;

		PlaceTight(mSVSquare, x, 0, squareSize, squareSize);
		x += squareSize + mGap;

		PlaceTight(mHueStrip, x, 0, mStripWidth, squareSize);
		x += mStripWidth + mGap;

		PlaceTight(mAlphaStrip, x, 0, mStripWidth, squareSize);
		x += mStripWidth + mGap;

		let inputWidth = Max(width - x, 70.0f);
		let inputHeight = 24.0f;
		var y = 0.0f;

		let previewHeight = 28.0f;
		let halfWidth = (inputWidth - 4.0f) * 0.5f;
		PlaceTight(mPreviewCurrent, x, y, halfWidth, previewHeight);
		PlaceTight(mPreviewOriginal, x + halfWidth + 4.0f, y, halfWidth, previewHeight);
		y += previewHeight + 8.0f;

		PlaceTight(mHexInput, x, y, inputWidth, inputHeight);
		y += inputHeight + 6.0f;

		PlaceTight(mRField, x, y, inputWidth, inputHeight);
		y += inputHeight + 4.0f;

		PlaceTight(mGField, x, y, inputWidth, inputHeight);
		y += inputHeight + 4.0f;

		PlaceTight(mBField, x, y, inputWidth, inputHeight);
	}

	private static void PlaceTight(View view, float x, float y, float width, float height)
	{
		view.Measure(BoxConstraints.Tight(width, height));
		view.Layout(x, y, width, height);
	}

	// ---- Synchronisation ------------------------------------------------------------------------

	/// A change made through the picker's own surfaces: rewrite the controls and tell the world.
	private void SyncFromHSV()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		SyncViewsFromHSV();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	/// Rewrites every control from the state. Does NOT fire the event, so the callers that only
	/// want the display refreshed, such as SetColor, do not report a change nobody made.
	private void SyncViewsFromHSV()
	{
		let color = HSVToRGB(mHue, mSaturation, mValue, mAlpha);
		let r = (int32)Round(color.R * 255.0f);
		let g = (int32)Round(color.G * 255.0f);
		let b = (int32)Round(color.B * 255.0f);

		mRField.SetValue(r);
		mGField.SetValue(g);
		mBField.SetValue(b);
		mHexInput.SetText(scope $"#{r:X2}{g:X2}{b:X2}");
		mPreviewCurrent.Color.Value = color;
	}

	private void SyncFromRGB()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		RGBToHSV((float)mRField.Value / 255.0f, (float)mGField.Value / 255.0f,
			(float)mBField.Value / 255.0f, out mHue, out mSaturation, out mValue);
		SyncViewsFromHSV();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	/// A malformed hex is IGNORED rather than half applied, so a partly typed value never
	/// repaints the dialog to something the user did not ask for.
	private void OnHexSubmit()
	{
		if (mSyncing)
			return;

		var text = mHexInput.Text;
		if (!text.IsEmpty && (text[0] == '#'))
			text = text.Substring(1);

		if (text.Length != 6)
			return;

		var packed = 0u;
		for (int i < 6)
		{
			let digit = HexDigit(text[i]);
			if (digit < 0)
				return;

			packed = (packed << 4) | (uint32)digit;
		}

		mSyncing = true;
		RGBToHSV(((packed >> 16) & 0xFF) / 255.0f, ((packed >> 8) & 0xFF) / 255.0f,
			(packed & 0xFF) / 255.0f, out mHue, out mSaturation, out mValue);
		SyncViewsFromHSV();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private static int32 HexDigit(char8 c)
	{
		if ((c >= '0') && (c <= '9'))
			return (int32)(c - '0');
		if ((c >= 'a') && (c <= 'f'))
			return 10 + (int32)(c - 'a');
		if ((c >= 'A') && (c <= 'F'))
			return 10 + (int32)(c - 'A');
		return -1;
	}
}
