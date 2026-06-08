namespace Sedulous.GUI.Toolkit;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Interactive HDR-allowed color picker. Mirrors the 8-bit ColorPicker
/// layout (SV square + hue strip + alpha strip) but the picker drives a
/// normalized [0, 1] LDR color while a separate intensity multiplier scales
/// RGB into HDR. The output is a Vector4 with HDR-allowed channels and an
/// alpha clamped to [0, 1].
///
/// Authoring flow:
///   - SV square / hue strip pick the saturated normalized color
///   - Alpha strip picks the alpha
///   - Intensity field (or future strip) multiplies RGB
///   - R / G / B fields accept float values; entering values > 1
///     re-decomposes into (normalized, intensity) so the SV square stays
///     usable for further authoring without losing the HDR magnitude
///
/// Wrap with Dialog + OK/Cancel for transactional editing. SetOriginalColor
/// stamps the right-hand preview swatch so the user can compare against
/// the value they started with.
public class HDRColorPicker : ViewGroup
{
	// Normalized HSV/A drive the picker widgets; intensity multiplies RGB.
	private float mHue;            // 0 - 360
	private float mSaturation = 1; // 0 - 1
	private float mValue = 1;      // 0 - 1
	private float mAlpha = 1;      // 0 - 1
	private float mIntensity = 1;  // 0 - 8 (HDR range; not hard-capped)
	private Vector4 mOriginalColor = .(1, 1, 1, 1);
	private bool mSyncing;

	// Inner views.
	private SVSquare mSVSquare;
	private HueStripView mHueStrip;
	private AlphaStripView mAlphaStrip;
	private NumericField mIntensityField;
	private NumericField mRField;
	private NumericField mGField;
	private NumericField mBField;
	private NumericField mAField;
	private ColorView mPreviewCurrent;
	private ColorView mPreviewOriginal;

	// Layout constants.
	private float mSquareSize = 180;
	private float mStripWidth = 20;
	private float mGap = 8;

	public Event<delegate void(HDRColorPicker, Vector4)> OnColorChanged ~ _.Dispose();

	/// Get or set the current color (HDR-allowed Vector4 RGBA).
	public Vector4 CurrentColor
	{
		get => HSVIToVec4(mHue, mSaturation, mValue, mIntensity, mAlpha);
		set => SetColor(value);
	}

	public this()
	{
		mSVSquare = new SVSquare(this);
		AddView(mSVSquare);

		mHueStrip = new HueStripView(this);
		AddView(mHueStrip);

		mAlphaStrip = new AlphaStripView(this);
		AddView(mAlphaStrip);

		mPreviewCurrent = new ColorView();
		mPreviewCurrent.Color.Value = .White;
		AddView(mPreviewCurrent);

		mPreviewOriginal = new ColorView();
		mPreviewOriginal.Color.Value = .White;
		AddView(mPreviewOriginal);

		mIntensityField = new NumericField();
		mIntensityField.Min = 0; mIntensityField.Max = 64; mIntensityField.Step = 0.1;
		mIntensityField.DecimalPlaces = 3;
		mIntensityField.Value = 1;
		mIntensityField.SetPrefix("Int");
		mIntensityField.OnValueChanged.Add(new (nf, val) => SyncFromIntensity());
		AddView(mIntensityField);

		mRField = MakeHDRField("R");
		mRField.OnValueChanged.Add(new (nf, val) => SyncFromRGB());
		AddView(mRField);

		mGField = MakeHDRField("G");
		mGField.OnValueChanged.Add(new (nf, val) => SyncFromRGB());
		AddView(mGField);

		mBField = MakeHDRField("B");
		mBField.OnValueChanged.Add(new (nf, val) => SyncFromRGB());
		AddView(mBField);

		mAField = new NumericField();
		mAField.Min = 0; mAField.Max = 1; mAField.Step = 0.01;
		mAField.DecimalPlaces = 3;
		mAField.Value = 1;
		mAField.SetPrefix("A");
		mAField.OnValueChanged.Add(new (nf, val) => SyncFromAlpha());
		AddView(mAField);

		mOriginalColor = CurrentColor;
		SyncViewsFromState();
	}

	private NumericField MakeHDRField(StringView prefix)
	{
		let f = new NumericField();
		f.Min = 0; f.Max = 64; f.Step = 0.01;
		f.DecimalPlaces = 3;
		f.Value = 1;
		f.SetPrefix(prefix);
		return f;
	}

	/// Set the current color (HDR Vector4) and update all sub-views.
	public void SetColor(Vector4 color)
	{
		if (mSyncing) return;
		mSyncing = true;
		Vec4ToHSVI(color, ref mHue, ref mSaturation, ref mValue, ref mIntensity, ref mAlpha);
		SyncViewsFromState();
		mSyncing = false;
	}

	public void SetOriginalColor(Vector4 color)
	{
		mOriginalColor = color;
		mPreviewOriginal.Color.Value = ClampToLDRColor(color);
	}

	// === Internal sync ===

	private void SyncFromHSV()
	{
		if (mSyncing) return;
		mSyncing = true;
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void SyncViewsFromState()
	{
		let color = HSVIToVec4(mHue, mSaturation, mValue, mIntensity, mAlpha);

		mRField.Value = color.X;
		mGField.Value = color.Y;
		mBField.Value = color.Z;
		mAField.Value = color.W;
		mIntensityField.Value = mIntensity;

		mPreviewCurrent.Color.Value = ClampToLDRColor(color);
	}

	private void SyncFromRGB()
	{
		if (mSyncing) return;
		mSyncing = true;
		let r = (float)mRField.Value;
		let g = (float)mGField.Value;
		let b = (float)mBField.Value;
		Vec4ToHSVI(.(r, g, b, mAlpha),
			ref mHue, ref mSaturation, ref mValue, ref mIntensity, ref mAlpha);
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void SyncFromIntensity()
	{
		if (mSyncing) return;
		mSyncing = true;
		mIntensity = (float)mIntensityField.Value;
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void SyncFromAlpha()
	{
		if (mSyncing) return;
		mSyncing = true;
		mAlpha = (float)mAField.Value;
		SyncViewsFromState();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float inputsW = 100;
		float totalW = mSquareSize + mGap + mStripWidth + mGap + mStripWidth + mGap + inputsW;
		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(mSquareSize));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let h = height;
		let w = width;
		float sqSize = Math.Min(mSquareSize, h);
		float x = 0;

		mSVSquare.Measure(BoxConstraints.Tight(sqSize, sqSize));
		mSVSquare.Layout(x, 0, sqSize, sqSize);
		x += sqSize + mGap;

		mHueStrip.Measure(BoxConstraints.Tight(mStripWidth, sqSize));
		mHueStrip.Layout(x, 0, mStripWidth, sqSize);
		x += mStripWidth + mGap;

		mAlphaStrip.Measure(BoxConstraints.Tight(mStripWidth, sqSize));
		mAlphaStrip.Layout(x, 0, mStripWidth, sqSize);
		x += mStripWidth + mGap;

		float inputW = Math.Max(w - x, 80);
		float inputH = 22;
		float y = 0;

		// Preview swatches.
		float previewH = 28;
		float halfW = (inputW - 4) * 0.5f;
		mPreviewCurrent.Measure(BoxConstraints.Tight(halfW, previewH));
		mPreviewCurrent.Layout(x, y, halfW, previewH);
		mPreviewOriginal.Measure(BoxConstraints.Tight(halfW, previewH));
		mPreviewOriginal.Layout(x + halfW + 4, y, halfW, previewH);
		y += previewH + 8;

		mIntensityField.Measure(BoxConstraints.Tight(inputW, inputH));
		mIntensityField.Layout(x, y, inputW, inputH);
		y += inputH + 6;

		mRField.Measure(BoxConstraints.Tight(inputW, inputH));
		mRField.Layout(x, y, inputW, inputH);
		y += inputH + 4;

		mGField.Measure(BoxConstraints.Tight(inputW, inputH));
		mGField.Layout(x, y, inputW, inputH);
		y += inputH + 4;

		mBField.Measure(BoxConstraints.Tight(inputW, inputH));
		mBField.Layout(x, y, inputW, inputH);
		y += inputH + 4;

		mAField.Measure(BoxConstraints.Tight(inputW, inputH));
		mAField.Layout(x, y, inputW, inputH);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, .(0, 0, Width, Height));
		else
		{
			let bgColor = Color(42, 44, 54, 255);
			ctx.VG.FillRect(.(0, 0, Width, Height), bgColor);
		}
		DrawChildren(ctx);
	}

	// === HSV + intensity decomposition helpers ===

	/// Combine HSV + intensity + alpha into an HDR Vector4. RGB are
	/// `HSVToRGB(h, s, v) * intensity`; alpha is unchanged.
	public static Vector4 HSVIToVec4(float h, float s, float v, float i, float a)
	{
		float r, g, b;
		HSVToRGB(h, s, v, out r, out g, out b);
		return .(r * i, g * i, b * i, a);
	}

	/// Decompose an HDR Vector4 into HSV + intensity + alpha. Intensity is
	/// taken as max(R, G, B); the normalized color is RGB/intensity. When
	/// intensity is zero (true black), HSV is left untouched so the picker
	/// preserves whatever hue the user had selected.
	public static void Vec4ToHSVI(Vector4 color,
		ref float h, ref float s, ref float v, ref float i, ref float a)
	{
		a = Math.Clamp(color.W, 0, 1);
		let maxChan = Math.Max(color.X, Math.Max(color.Y, color.Z));
		if (maxChan <= 0.0001f)
		{
			i = 0;
			// Keep h/s/v as-is so the SV indicator does not snap on black.
			return;
		}
		i = maxChan;
		let inv = 1.0f / maxChan;
		let r = Math.Clamp(color.X * inv, 0, 1);
		let g = Math.Clamp(color.Y * inv, 0, 1);
		let b = Math.Clamp(color.Z * inv, 0, 1);
		RGBToHSV(r, g, b, ref h, ref s, ref v);
	}

	/// Standard HSV -> linear RGB in [0, 1]^3.
	public static void HSVToRGB(float h, float s, float v, out float r, out float g, out float b)
	{
		float c = v * s;
		float hPrime = h / 60.0f;
		float x = c * (1.0f - Math.Abs(hPrime % 2.0f - 1.0f));
		float m = v - c;

		float r1 = 0, g1 = 0, b1 = 0;
		if (hPrime < 1) { r1 = c; g1 = x; }
		else if (hPrime < 2) { r1 = x; g1 = c; }
		else if (hPrime < 3) { g1 = c; b1 = x; }
		else if (hPrime < 4) { g1 = x; b1 = c; }
		else if (hPrime < 5) { r1 = x; b1 = c; }
		else { r1 = c; b1 = x; }

		r = r1 + m;
		g = g1 + m;
		b = b1 + m;
	}

	/// Linear RGB in [0, 1]^3 -> HSV.
	public static void RGBToHSV(float r, float g, float b, ref float h, ref float s, ref float v)
	{
		float cMax = Math.Max(r, Math.Max(g, b));
		float cMin = Math.Min(r, Math.Min(g, b));
		float delta = cMax - cMin;

		v = cMax;
		s = (cMax == 0) ? 0 : delta / cMax;

		if (delta == 0)
			h = 0;
		else if (cMax == r)
			h = 60.0f * (((g - b) / delta) % 6.0f);
		else if (cMax == g)
			h = 60.0f * (((b - r) / delta) + 2.0f);
		else
			h = 60.0f * (((r - g) / delta) + 4.0f);

		if (h < 0) h += 360.0f;
	}

	/// Clamp + quantize an HDR Vector4 to a uint8 Color for preview display
	/// (monitors are LDR anyway; HDR portions saturate visually).
	private static Color ClampToLDRColor(Vector4 c)
	{
		let r = (uint8)Math.Clamp((int32)(c.X * 255), 0, 255);
		let g = (uint8)Math.Clamp((int32)(c.Y * 255), 0, 255);
		let b = (uint8)Math.Clamp((int32)(c.Z * 255), 0, 255);
		let a = (uint8)Math.Clamp((int32)(c.W * 255), 0, 255);
		return .(r, g, b, a);
	}

	// === Inner views (mirror ColorPicker's SVSquare / HueStripView /
	// AlphaStripView, but display the normalized [0, 1] color so they stay
	// usable for HDR authoring - intensity is edited separately). ===

	private class SVSquare : View
	{
		private HDRColorPicker mPicker;
		private bool mDragging;

		public this(HDRColorPicker picker) { mPicker = picker; }

		public override void OnDraw(UIDrawContext ctx)
		{
			int steps = 30;
			float cellW = Width / steps;
			float cellH = Height / steps;

			for (int iy = 0; iy < steps; iy++)
			{
				float v = 1.0f - (float)iy / (steps - 1);
				for (int ix = 0; ix < steps; ix++)
				{
					float s = (float)ix / (steps - 1);
					float r, g, b;
					HSVToRGB(mPicker.mHue, s, v, out r, out g, out b);
					let color = Color((uint8)(r * 255), (uint8)(g * 255), (uint8)(b * 255), 255);
					ctx.VG.FillRect(.(ix * cellW, iy * cellH, cellW + 1, cellH + 1), color);
				}
			}

			float cx = mPicker.mSaturation * Width;
			float cy = (1.0f - mPicker.mValue) * Height;
			let indicatorColor = (mPicker.mValue > 0.5f) ? Color(0, 0, 0, 255) : Color(255, 255, 255, 255);
			ctx.VG.StrokeCircle(.(cx, cy), 5, indicatorColor, 2);

			let border = ResolveStyleColor(.BorderColor, .(80, 85, 100, 255));
			ctx.VG.StrokeRect(.(0, 0, Width, Height), border, 1);
		}

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left) return;
			mDragging = true;
			Context?.FocusManager.SetCapture(this);
			UpdateFromMouse(e.X, e.Y);
			e.Handled = true;
		}

		public override void OnMouseMove(MouseEventArgs e)
		{
			if (mDragging) UpdateFromMouse(e.X, e.Y);
		}

		public override void OnMouseUp(MouseEventArgs e)
		{
			if (mDragging && e.Button == .Left)
			{
				mDragging = false;
				Context?.FocusManager.ReleaseCapture();
				e.Handled = true;
			}
		}

		private void UpdateFromMouse(float x, float y)
		{
			mPicker.mSaturation = Math.Clamp(x / Width, 0, 1);
			mPicker.mValue = Math.Clamp(1.0f - y / Height, 0, 1);
			mPicker.SyncFromHSV();
		}
	}

	private class HueStripView : View
	{
		private HDRColorPicker mPicker;
		private bool mDragging;

		public this(HDRColorPicker picker) { mPicker = picker; }

		public override void OnDraw(UIDrawContext ctx)
		{
			int steps = 36;
			float cellH = Height / steps;

			for (int i = 0; i < steps; i++)
			{
				float hue = (float)i / (steps - 1) * 360.0f;
				float r, g, b;
				HSVToRGB(hue, 1, 1, out r, out g, out b);
				let color = Color((uint8)(r * 255), (uint8)(g * 255), (uint8)(b * 255), 255);
				ctx.VG.FillRect(.(0, i * cellH, Width, cellH + 1), color);
			}

			float iy = (mPicker.mHue / 360.0f) * Height;
			ctx.VG.FillRect(.(0, iy - 1, Width, 3), .(255, 255, 255, 230));
			ctx.VG.StrokeRect(.(0, iy - 1, Width, 3), .(0, 0, 0, 128), 1);

			let border = ResolveStyleColor(.BorderColor, .(80, 85, 100, 255));
			ctx.VG.StrokeRect(.(0, 0, Width, Height), border, 1);
		}

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left) return;
			mDragging = true;
			Context?.FocusManager.SetCapture(this);
			UpdateFromMouse(e.Y);
			e.Handled = true;
		}

		public override void OnMouseMove(MouseEventArgs e)
		{
			if (mDragging) UpdateFromMouse(e.Y);
		}

		public override void OnMouseUp(MouseEventArgs e)
		{
			if (mDragging && e.Button == .Left)
			{
				mDragging = false;
				Context?.FocusManager.ReleaseCapture();
				e.Handled = true;
			}
		}

		private void UpdateFromMouse(float y)
		{
			mPicker.mHue = Math.Clamp(y / Height, 0, 1) * 360.0f;
			mPicker.SyncFromHSV();
		}
	}

	private class AlphaStripView : View
	{
		private HDRColorPicker mPicker;
		private bool mDragging;

		public this(HDRColorPicker picker) { mPicker = picker; }

		public override void OnDraw(UIDrawContext ctx)
		{
			// Checkerboard background so the alpha gradient is readable.
			float checkSize = 5;
			let light = Color(200, 200, 200, 255);
			let dark = Color(128, 128, 128, 255);

			int cols = (int)Math.Ceiling(Width / checkSize);
			int rows = (int)Math.Ceiling(Height / checkSize);
			for (int ry = 0; ry < rows; ry++)
			{
				for (int cx = 0; cx < cols; cx++)
				{
					let c = ((ry + cx) % 2 == 0) ? light : dark;
					ctx.VG.FillRect(.(cx * checkSize, ry * checkSize,
						Math.Min(checkSize, Width - cx * checkSize),
						Math.Min(checkSize, Height - ry * checkSize)), c);
				}
			}

			// Gradient from opaque (top) to transparent (bottom) of the
			// current LDR-clamped color.
			float r, g, b;
			HSVToRGB(mPicker.mHue, mPicker.mSaturation, mPicker.mValue, out r, out g, out b);
			int steps = 20;
			float cellH = Height / steps;
			for (int i = 0; i < steps; i++)
			{
				float alpha = 1.0f - (float)i / (steps - 1);
				let c = Color((uint8)(r * 255), (uint8)(g * 255), (uint8)(b * 255), (uint8)(alpha * 255));
				ctx.VG.FillRect(.(0, i * cellH, Width, cellH + 1), c);
			}

			float iy = (1.0f - mPicker.mAlpha) * Height;
			ctx.VG.FillRect(.(0, iy - 1, Width, 3), .(255, 255, 255, 230));
			ctx.VG.StrokeRect(.(0, iy - 1, Width, 3), .(0, 0, 0, 128), 1);

			let border = ResolveStyleColor(.BorderColor, .(80, 85, 100, 255));
			ctx.VG.StrokeRect(.(0, 0, Width, Height), border, 1);
		}

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left) return;
			mDragging = true;
			Context?.FocusManager.SetCapture(this);
			UpdateFromMouse(e.Y);
			e.Handled = true;
		}

		public override void OnMouseMove(MouseEventArgs e)
		{
			if (mDragging) UpdateFromMouse(e.Y);
		}

		public override void OnMouseUp(MouseEventArgs e)
		{
			if (mDragging && e.Button == .Left)
			{
				mDragging = false;
				Context?.FocusManager.ReleaseCapture();
				e.Handled = true;
			}
		}

		private void UpdateFromMouse(float y)
		{
			mPicker.mAlpha = Math.Clamp(1.0f - y / Height, 0, 1);
			mPicker.SyncFromHSV();
		}
	}
}
