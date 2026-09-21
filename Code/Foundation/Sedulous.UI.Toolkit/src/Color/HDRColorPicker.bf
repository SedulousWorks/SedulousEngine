using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The colour dialog for values that go past white: an emissive material, a light, a bloom
/// tint.
///
/// The state is a NORMALISED colour plus a separate INTENSITY multiplier, not three unbounded
/// channels. That split is what lets the square and the strips stay ordinary: they show the
/// colour at full brightness, and intensity scales it afterwards. Editing an eight times white
/// as raw channels would leave the saturation and value controls pinned and useless.
///
/// It shares its square and strips with [[ColorPicker]] through [[IHSVSource]] rather than
/// carrying a second copy of all three, identical but for which picker they point at.
class HDRColorPicker : ViewGroup, IHSVSource
{
	public Event<delegate void(HDRColorPicker, Float4)> OnColorChanged ~ _.Dispose();

	private float mHue = 0.0f;
	private float mSaturation = 1.0f;
	private float mValue = 1.0f;
	private float mAlpha = 1.0f;
	/// Not hard capped: the fields allow up to sixty four, and the model allows more.
	private float mIntensity = 1.0f;
	private Float4 mOriginalColor = .(1, 1, 1, 1);
	private bool mSyncing = false;

	/// BORROWED: the child tree owns them all.
	private SVSquareView mSVSquare = null;
	private HueStripView mHueStrip = null;
	private AlphaStripView mAlphaStrip = null;
	private NumericField mIntensityField = null;
	private NumericField mRField = null;
	private NumericField mGField = null;
	private NumericField mBField = null;
	private NumericField mAField = null;
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

		mIntensityField = MakeField("Int", 64.0, 0.1, new (field, value) => { SyncFromIntensity(); });
		mRField = MakeField("R", 64.0, 0.01, new (field, value) => { SyncFromRGB(); });
		mGField = MakeField("G", 64.0, 0.01, new (field, value) => { SyncFromRGB(); });
		mBField = MakeField("B", 64.0, 0.01, new (field, value) => { SyncFromRGB(); });
		mAField = MakeField("A", 1.0, 0.01, new (field, value) => { SyncFromAlpha(); });

		mOriginalColor = CurrentColor;
		SyncViewsFromState();
	}

	/// CONSUMES the handler: it goes straight onto the field's event, which owns it.
	private NumericField MakeField(StringView prefix, double max, double step,
		delegate void(NumericField, double) onChanged)
	{
		let field = new NumericField();
		field.SetMin(0);
		field.SetMax(max);
		field.SetStep(step);
		field.SetDecimalPlaces(3);
		field.SetValue(1);
		field.SetPrefix(prefix);
		field.OnValueChanged.Add(onChanged);
		AddView(field);
		return field;
	}

	// ---- IHSVSource, EXPLICIT so the components stay off the picker's public surface -----------

	float IHSVSource.Hue { get => mHue; set => mHue = value; }
	float IHSVSource.Saturation { get => mSaturation; set => mSaturation = value; }
	float IHSVSource.Value { get => mValue; set => mValue = value; }
	float IHSVSource.Alpha { get => mAlpha; set => mAlpha = value; }

	void IHSVSource.OnHSVChangedBySurface() => SyncFromHSV();

	// ---------------------------------------------------------------------------------------------

	public Float4 CurrentColor => HSVIToVec4(mHue, mSaturation, mValue, mIntensity, mAlpha);

	public void SetColor(Float4 color)
	{
		if (mSyncing)
			return;

		mSyncing = true;
		Vec4ToHSVI(color, ref mHue, ref mSaturation, ref mValue, out mIntensity, out mAlpha);
		SyncViewsFromState();
		mSyncing = false;
	}

	public void SetOriginalColor(Float4 color)
	{
		mOriginalColor = color;
		mPreviewOriginal.Color.Value = ClampToLDR(color);
	}

	public Float4 OriginalColor => mOriginalColor;

	// ---- The intensity split --------------------------------------------------------------------

	/// Colour times intensity, alpha untouched.
	public static Float4 HSVIToVec4(float h, float s, float v, float i, float a)
	{
		let rgb = ColorPicker.HSVToRGB(h, s, v);
		return .(rgb.R * i, rgb.G * i, rgb.B * i, a);
	}

	/// The other direction: intensity is the largest channel and the colour is what is left
	/// after dividing it out.
	///
	/// TRUE BLACK leaves hue, saturation and value ALONE, which is why they come in by
	/// reference. There is no colour to recover from all zeroes, and snapping the square's
	/// indicator to a corner every time a value passes through black would be maddening.
	public static void Vec4ToHSVI(Float4 color, ref float h, ref float s, ref float v,
		out float i, out float a)
	{
		a = Clamp(color.W, 0.0f, 1.0f);

		let maxChannel = Max(color.X, Max(color.Y, color.Z));
		if (maxChannel <= 0.0001f)
		{
			i = 0.0f;
			return;
		}

		i = maxChannel;
		let inverse = 1.0f / maxChannel;
		ColorPicker.RGBToHSV(Clamp(color.X * inverse, 0.0f, 1.0f),
			Clamp(color.Y * inverse, 0.0f, 1.0f), Clamp(color.Z * inverse, 0.0f, 1.0f),
			out h, out s, out v);
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
		let inputsWidth = 100.0f;
		let totalWidth = mSquareSize + mGap + mStripWidth + mGap + mStripWidth + mGap + inputsWidth;
		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(mSquareSize));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let squareSize = Min(mSquareSize, height);
		var x = 0.0f;

		PlaceTight(mSVSquare, x, 0, squareSize, squareSize);
		x += squareSize + mGap;

		PlaceTight(mHueStrip, x, 0, mStripWidth, squareSize);
		x += mStripWidth + mGap;

		PlaceTight(mAlphaStrip, x, 0, mStripWidth, squareSize);
		x += mStripWidth + mGap;

		let inputWidth = Max(width - x, 80.0f);
		let inputHeight = 22.0f;
		var y = 0.0f;

		let previewHeight = 28.0f;
		let halfWidth = (inputWidth - 4.0f) * 0.5f;
		PlaceTight(mPreviewCurrent, x, y, halfWidth, previewHeight);
		PlaceTight(mPreviewOriginal, x + halfWidth + 4.0f, y, halfWidth, previewHeight);
		y += previewHeight + 8.0f;

		PlaceTight(mIntensityField, x, y, inputWidth, inputHeight);
		y += inputHeight + 6.0f;

		for (let field in scope NumericField[](mRField, mGField, mBField, mAField))
		{
			PlaceTight(field, x, y, inputWidth, inputHeight);
			y += inputHeight + 4.0f;
		}
	}

	private static void PlaceTight(View view, float x, float y, float width, float height)
	{
		view.Measure(BoxConstraints.Tight(width, height));
		view.Layout(x, y, width, height);
	}

	// ---- Synchronisation ------------------------------------------------------------------------

	private void SyncFromHSV()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	/// Rewrites every control from the state WITHOUT reporting a change, so SetColor refreshes
	/// the display without telling the caller about an edit they made themselves.
	private void SyncViewsFromState()
	{
		let color = CurrentColor;
		mRField.SetValue(color.X);
		mGField.SetValue(color.Y);
		mBField.SetValue(color.Z);
		mAField.SetValue(color.W);
		mIntensityField.SetValue(mIntensity);
		// The preview is an ordinary swatch, so anything past white is CLIPPED for display.
		mPreviewCurrent.Color.Value = ClampToLDR(color);
	}

	private void SyncFromRGB()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		Vec4ToHSVI(.((float)mRField.Value, (float)mGField.Value, (float)mBField.Value, mAlpha),
			ref mHue, ref mSaturation, ref mValue, out mIntensity, out mAlpha);
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void SyncFromIntensity()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		mIntensity = (float)mIntensityField.Value;
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void SyncFromAlpha()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		mAlpha = (float)mAField.Value;
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private static Color ClampToLDR(Float4 color) =>
		.(Clamp(color.X, 0.0f, 1.0f), Clamp(color.Y, 0.0f, 1.0f), Clamp(color.Z, 0.0f, 1.0f),
			Clamp(color.W, 0.0f, 1.0f));
}
