using System;

namespace Sedulous.Editor.Scene;

/// A round length at the focus and the pixels it spans on screen.
struct ScaleBar
{
	public float Metres = 0.0f;
	public float Pixels = 0.0f;

	public this() {}

	public this(float metres, float pixels)
	{
		Metres = metres;
		Pixels = pixels;
	}
}

/// The scene view's measurement overlay while zooming: a wheel dolly shows, for a moment, how
/// far the camera is from its focus, what a grid cell measures, and a scale bar of a round
/// length at the focus, then fades once the zoom stops. The pure parts live here (when it
/// shows, the bar's length, the words for a length) so they are testable without a viewport;
/// the page draws them.
class ZoomReadout
{
	/// Shown whole for this long after the last notch.
	public const float cHoldSeconds = 1.0f;
	/// Then gone over this long.
	public const float cFadeSeconds = 0.5f;

	private bool mShown = false;
	private float mSinceZoom = 0.0f;

	/// The longest round length (1, 2 or 5 times a power of ten) that spans at most
	/// `targetPixels` at `distance` in front of a perspective camera of vertical field of view
	/// `fovY` (radians) drawn `viewportHeight` pixels tall. Zero for a degenerate view.
	public static ScaleBar ScaleBarAt(float distance, float fovY, float viewportHeight,
		float targetPixels = 120.0f)
	{
		if ((distance <= 0.0f) || (fovY <= 0.0f) || (viewportHeight <= 0.0f) || (targetPixels <= 0.0f))
			return .();
		// The height of the view at the focus, spread over the viewport's pixels.
		let metresPerPixel = 2.0f * distance * Math.Tan(0.5f * fovY) / viewportHeight;
		let target = targetPixels * metresPerPixel;
		var decade = 1.0f;
		while (decade * 10.0f <= target)
			decade *= 10.0f;
		while (decade > target)
			decade *= 0.1f;
		var metres = decade;
		if (decade * 5.0f <= target)
			metres = decade * 5.0f;
		else if (decade * 2.0f <= target)
			metres = decade * 2.0f;
		return .(metres, metres / metresPerPixel);
	}

	/// A length in words: millimetres and centimetres below a metre, metres (one decimal below
	/// ten) below a kilometre, kilometres (one decimal) above. "5 cm", "2.5 m", "12 m", "1.2 km".
	public static void FormatMetres(float metres, String outText)
	{
		void OneDecimal(float value, StringView unit)
		{
			let tenths = (int64)(value * 10.0f + 0.5f);
			if (tenths % 10 == 0)
				outText.AppendF("{} {}", tenths / 10, unit);
			else
				outText.AppendF("{}.{} {}", tenths / 10, tenths % 10, unit);
		}

		if (metres < 0.01f)
			outText.AppendF("{} mm", (int64)(metres * 1000.0f + 0.5f));
		else if (metres < 1.0f)
			outText.AppendF("{} cm", (int64)(metres * 100.0f + 0.5f));
		else if (metres < 10.0f)
			OneDecimal(metres, "m");
		else if (metres < 1000.0f)
			outText.AppendF("{} m", (int64)(metres + 0.5f));
		else
			OneDecimal(metres * 0.001f, "km");
	}

	/// A zoom happened this frame: show it (again) from the start.
	public void Zoomed()
	{
		mShown = true;
		mSinceZoom = 0.0f;
	}

	public void Advance(float dt)
	{
		if (!mShown)
			return;
		mSinceZoom += dt;
		mShown = mSinceZoom < cHoldSeconds + cFadeSeconds;
	}

	/// One while held, falling to nought over the fade, nought when hidden.
	public float Opacity
	{
		get
		{
			if (!mShown)
				return 0.0f;
			if (mSinceZoom <= cHoldSeconds)
				return 1.0f;
			return Math.Clamp(1.0f - (mSinceZoom - cHoldSeconds) / cFadeSeconds, 0.0f, 1.0f);
		}
	}
}
