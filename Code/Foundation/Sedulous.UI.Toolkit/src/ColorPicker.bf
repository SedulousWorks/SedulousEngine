namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Interactive HSV color picker with SV square, hue strip, alpha strip,
/// RGB number fields, hex input, and current/original preview swatches.
public class ColorPicker : ViewGroup
{
	private float mHue;           // 0-360
	private float mSaturation = 1; // 0-1
	private float mValue = 1;     // 0-1
	private float mAlpha = 1;     // 0-1
	private Color mOriginalColor = .White;
	private bool mSyncing;

	// Inner views.
	private SVSquare mSVSquare;
	private HueStripView mHueStrip;
	private AlphaStripView mAlphaStrip;
	private EditText mHexInput;
	private NumericField mRField;
	private NumericField mGField;
	private NumericField mBField;
	private ColorView mPreviewCurrent;
	private ColorView mPreviewOriginal;

	// Layout constants.
	private float mSquareSize = 180;
	private float mStripWidth = 20;
	private float mGap = 8;

	public Event<delegate void(ColorPicker, Color)> OnColorChanged ~ _.Dispose();

	/// Get or set the current color.
	public Color CurrentColor
	{
		get => HSVToRGB(mHue, mSaturation, mValue, mAlpha);
		set => SetColor(value);
	}

	public this()
	{
		// SV Square.
		mSVSquare = new SVSquare(this);
		AddView(mSVSquare);

		// Hue strip.
		mHueStrip = new HueStripView(this);
		AddView(mHueStrip);

		// Alpha strip.
		mAlphaStrip = new AlphaStripView(this);
		AddView(mAlphaStrip);

		// Preview swatches.
		mPreviewCurrent = new ColorView();
		mPreviewCurrent.Color = .White;
		AddView(mPreviewCurrent);

		mPreviewOriginal = new ColorView();
		mPreviewOriginal.Color = .White;
		AddView(mPreviewOriginal);

		// Hex input.
		mHexInput = new EditText();
		mHexInput.SetPlaceholder("#RRGGBB");
		mHexInput.MaxLength = 7;
		mHexInput.OnSubmit.Add(new (e) => OnHexSubmit());
		AddView(mHexInput);

		// RGB number fields.
		mRField = new NumericField();
		mRField.Min = 0; mRField.Max = 255; mRField.Step = 1; mRField.Value = 255;
		mRField.OnValueChanged.Add(new (nf, val) => SyncFromRGB());
		AddView(mRField);

		mGField = new NumericField();
		mGField.Min = 0; mGField.Max = 255; mGField.Step = 1; mGField.Value = 255;
		mGField.OnValueChanged.Add(new (nf, val) => SyncFromRGB());
		AddView(mGField);

		mBField = new NumericField();
		mBField.Min = 0; mBField.Max = 255; mBField.Step = 1; mBField.Value = 255;
		mBField.OnValueChanged.Add(new (nf, val) => SyncFromRGB());
		AddView(mBField);

		mOriginalColor = CurrentColor;
		SyncViewsFromHSV();
	}

	/// Set the current color and update all sub-views.
	public void SetColor(Color color)
	{
		if (mSyncing) return;
		mSyncing = true;

		float r = color.R / 255.0f;
		float g = color.G / 255.0f;
		float b = color.B / 255.0f;
		mAlpha = color.A / 255.0f;

		RGBToHSV(r, g, b, ref mHue, ref mSaturation, ref mValue);
		SyncViewsFromHSV();
		mSyncing = false;
	}

	/// Set the original color (shown in the "original" preview swatch).
	public void SetOriginalColor(Color color)
	{
		mOriginalColor = color;
		mPreviewOriginal.Color = color;
	}

	// === Internal sync ===

	private void SyncFromHSV()
	{
		if (mSyncing) return;
		mSyncing = true;
		SyncViewsFromHSV();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void SyncViewsFromHSV()
	{
		let color = HSVToRGB(mHue, mSaturation, mValue, mAlpha);

		mRField.Value = color.R;
		mGField.Value = color.G;
		mBField.Value = color.B;

		let hex = scope String();
		hex.AppendF("#{0:X2}{1:X2}{2:X2}", (int)color.R, (int)color.G, (int)color.B);
		mHexInput.SetText(hex);

		mPreviewCurrent.Color = color;
	}

	private void SyncFromRGB()
	{
		if (mSyncing) return;
		mSyncing = true;

		float r = (float)mRField.Value / 255.0f;
		float g = (float)mGField.Value / 255.0f;
		float b = (float)mBField.Value / 255.0f;

		RGBToHSV(r, g, b, ref mHue, ref mSaturation, ref mValue);
		SyncViewsFromHSV();
		OnColorChanged(this, CurrentColor);
		mSyncing = false;
	}

	private void OnHexSubmit()
	{
		if (mSyncing) return;

		let text = scope String(mHexInput.Text);
		if (text.StartsWith('#'))
			text.Remove(0, 1);

		if (text.Length == 6)
		{
			if (uint32.Parse(text, .HexNumber) case .Ok(let hexVal))
			{
				float r = ((hexVal >> 16) & 0xFF) / 255.0f;
				float g = ((hexVal >> 8) & 0xFF) / 255.0f;
				float b = (hexVal & 0xFF) / 255.0f;

				mSyncing = true;
				RGBToHSV(r, g, b, ref mHue, ref mSaturation, ref mValue);
				SyncViewsFromHSV();
				OnColorChanged(this, CurrentColor);
				mSyncing = false;
			}
		}
	}

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float inputsW = 80;
		float totalW = mSquareSize + mGap + mStripWidth + mGap + mStripWidth + mGap + inputsW;
		MeasuredSize = .(wSpec.Resolve(totalW), hSpec.Resolve(mSquareSize));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let h = bottom - top;
		let w = right - left;
		float sqSize = Math.Min(mSquareSize, h);
		float x = 0;

		// SV Square.
		mSVSquare.Measure(.Exactly(sqSize), .Exactly(sqSize));
		mSVSquare.Layout(x, 0, sqSize, sqSize);
		x += sqSize + mGap;

		// Hue strip.
		mHueStrip.Measure(.Exactly(mStripWidth), .Exactly(sqSize));
		mHueStrip.Layout(x, 0, mStripWidth, sqSize);
		x += mStripWidth + mGap;

		// Alpha strip.
		mAlphaStrip.Measure(.Exactly(mStripWidth), .Exactly(sqSize));
		mAlphaStrip.Layout(x, 0, mStripWidth, sqSize);
		x += mStripWidth + mGap;

		// Input column.
		float inputW = Math.Max(w - x, 70);
		float inputH = 24;
		float y = 0;

		// Preview swatches.
		float previewH = 28;
		float halfW = (inputW - 4) * 0.5f;
		mPreviewCurrent.Measure(.Exactly(halfW), .Exactly(previewH));
		mPreviewCurrent.Layout(x, y, halfW, previewH);
		mPreviewOriginal.Measure(.Exactly(halfW), .Exactly(previewH));
		mPreviewOriginal.Layout(x + halfW + 4, y, halfW, previewH);
		y += previewH + 8;

		// Hex input.
		mHexInput.Measure(.Exactly(inputW), .Exactly(inputH));
		mHexInput.Layout(x, y, inputW, inputH);
		y += inputH + 6;

		// R/G/B fields with labels.
		mRField.Measure(.Exactly(inputW), .Exactly(inputH));
		mRField.Layout(x, y, inputW, inputH);
		y += inputH + 4;

		mGField.Measure(.Exactly(inputW), .Exactly(inputH));
		mGField.Layout(x, y, inputW, inputH);
		y += inputH + 4;

		mBField.Measure(.Exactly(inputW), .Exactly(inputH));
		mBField.Layout(x, y, inputW, inputH);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (!ctx.TryDrawDrawable("ColorPicker.Background", .(0, 0, Width, Height), .Normal))
		{
			let bgColor = ctx.Theme?.GetColor("ColorPicker.Background") ?? ctx.Theme?.Palette.Surface ?? .(42, 44, 54, 255);
			ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 4, bgColor);
		}

		DrawChildren(ctx);
	}

	// === HSV Helpers ===

	public static Color HSVToRGB(float h, float s, float v, float a = 1.0f)
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

		return .((uint8)((r1 + m) * 255), (uint8)((g1 + m) * 255), (uint8)((b1 + m) * 255), (uint8)(a * 255));
	}

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

	// === Inner Views ===

	/// Saturation/Value square: S on X-axis, V on Y-axis (inverted).
	private class SVSquare : View
	{
		private ColorPicker mPicker;
		private bool mDragging;

		public this(ColorPicker picker) { mPicker = picker; }

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
					let color = HSVToRGB(mPicker.mHue, s, v);
					ctx.VG.FillRect(.(ix * cellW, iy * cellH, cellW + 1, cellH + 1), color);
				}
			}

			// Circle indicator.
			float cx = mPicker.mSaturation * Width;
			float cy = (1.0f - mPicker.mValue) * Height;
			let indicatorColor = (mPicker.mValue > 0.5f) ? Color(0, 0, 0, 255) : Color(255, 255, 255, 255);
			ctx.VG.StrokeCircle(.(cx, cy), 5, indicatorColor, 2);

			// Border.
			let border = ctx.Theme?.GetColor("ColorPicker.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255);
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

	/// Vertical hue rainbow strip.
	private class HueStripView : View
	{
		private ColorPicker mPicker;
		private bool mDragging;

		public this(ColorPicker picker) { mPicker = picker; }

		public override void OnDraw(UIDrawContext ctx)
		{
			int steps = 36;
			float cellH = Height / steps;

			for (int i = 0; i < steps; i++)
			{
				float hue = (float)i / (steps - 1) * 360.0f;
				let color = HSVToRGB(hue, 1, 1);
				ctx.VG.FillRect(.(0, i * cellH, Width, cellH + 1), color);
			}

			// Line indicator.
			float iy = (mPicker.mHue / 360.0f) * Height;
			ctx.VG.FillRect(.(0, iy - 1, Width, 3), .(255, 255, 255, 230));
			ctx.VG.StrokeRect(.(0, iy - 1, Width, 3), .(0, 0, 0, 128), 1);

			// Border.
			let border = ctx.Theme?.GetColor("ColorPicker.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255);
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

	/// Vertical alpha strip with checkerboard background.
	private class AlphaStripView : View
	{
		private ColorPicker mPicker;
		private bool mDragging;

		public this(ColorPicker picker) { mPicker = picker; }

		public override void OnDraw(UIDrawContext ctx)
		{
			// Checkerboard background.
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

			// Color gradient from opaque (top) to transparent (bottom).
			let baseColor = HSVToRGB(mPicker.mHue, mPicker.mSaturation, mPicker.mValue);
			int steps = 20;
			float cellH = Height / steps;
			for (int i = 0; i < steps; i++)
			{
				float alpha = 1.0f - (float)i / (steps - 1);
				let c = Color(baseColor.R, baseColor.G, baseColor.B, (uint8)(alpha * 255));
				ctx.VG.FillRect(.(0, i * cellH, Width, cellH + 1), c);
			}

			// Line indicator.
			float iy = (1.0f - mPicker.mAlpha) * Height;
			ctx.VG.FillRect(.(0, iy - 1, Width, 3), .(255, 255, 255, 230));
			ctx.VG.StrokeRect(.(0, iy - 1, Width, 3), .(0, 0, 0, 128), 1);

			// Border.
			let border = ctx.Theme?.GetColor("ColorPicker.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255);
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
