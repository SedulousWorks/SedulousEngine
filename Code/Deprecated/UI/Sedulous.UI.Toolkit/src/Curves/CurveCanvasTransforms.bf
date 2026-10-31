using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CurveCanvas]]: the mapping between data space and the screen, the auto fit that chooses the
/// value frame, and the hit tests built on both.
extension CurveCanvas
{
	/// Pixels per SECOND. The shared mapping is handed it; the standalone one derives it by
	/// fitting the span to the width.
	private float PixelsPerTime()
	{
		if (UseSharedTimeTransform)
			return PixelsPerSecond;

		return Width / ((TimeSpan > 1e-6f) ? TimeSpan : 1e-6f);
	}

	private float TimeToX(float t) =>
		(t - (UseSharedTimeTransform ? ScrollSeconds : 0.0f)) * PixelsPerTime();

	private float XToTime(float x)
	{
		if (UseSharedTimeTransform)
		{
			let t = ScrollSeconds + ((PixelsPerSecond > 1e-6f) ? (x / PixelsPerSecond) : 0.0f);
			// No negative time: a key cannot sit before the start of the clip.
			return (t > 0.0f) ? t : 0.0f;
		}

		return Clamp(x / Width, 0.0f, 1.0f) * TimeSpan;
	}

	private float ValueToY(float v)
	{
		let span = ValueMax - ValueMin;
		if (span < 0.0001f)
			return Height * 0.5f;

		return Height * (1.0f - ((v - ValueMin) / span));
	}

	/// UNCLAMPED on purpose. The value frame is a viewport, not a limit, so a drag past the top
	/// or bottom edge extrapolates; clamping here once made every value outside the current auto
	/// fit unreachable by dragging. The per channel clamps still apply, at the call sites.
	private float YToValue(float y)
	{
		let ratio = (Height > 0.0f) ? (y / Height) : 0.0f;
		return ValueMax - (ratio * (ValueMax - ValueMin));
	}

	private float ClampToChannel(int32 channelIndex, float v)
	{
		let channel = mChannels[channelIndex];
		// Min not below max, the zero initialised case included, means no clamp was configured.
		if (channel.MinValue >= channel.MaxValue)
			return v;

		return Clamp(v, channel.MinValue, channel.MaxValue);
	}

	// ---- The value frame ------------------------------------------------------------------------

	/// Chooses the value range from what is on screen.
	///
	/// FROZEN during a gesture. Refitting while a key is being dragged moves the very axis the
	/// drag is measured against, and the key chases the cursor without catching it.
	private void UpdateAutoFit()
	{
		if (!AutoFitValueRange || mInGesture)
			return;

		var keyLow = FloatMax;
		var keyHigh = -FloatMax;
		var anyKeys = false;

		var nominalLow = FloatMax;
		var nominalHigh = -FloatMax;
		var anyNominal = false;

		for (let channel in mChannels)
		{
			if (channel.Hidden)
				continue;

			if (channel.DisplayMin < channel.DisplayMax)
			{
				nominalLow = Min(nominalLow, channel.DisplayMin);
				nominalHigh = Max(nominalHigh, channel.DisplayMax);
				anyNominal = true;
			}

			for (let key in channel.Keys)
			{
				keyLow = Min(keyLow, key.Value);
				keyHigh = Max(keyHigh, key.Value);
				anyKeys = true;
			}
		}

		// A channel that declared what it means is FRAMED TO THAT, and the frame only grows to
		// admit keys outside it. An opacity channel stays showing zero to one rather than
		// rescaling around whatever happens to be keyed.
		if (anyNominal)
		{
			var low = nominalLow;
			var high = nominalHigh;

			if (anyKeys)
			{
				let pad = (nominalHigh - nominalLow) * 0.05f;
				if (keyLow < low)
					low = keyLow - pad;
				if (keyHigh > high)
					high = keyHigh + pad;
			}

			ValueMin = low;
			ValueMax = high;
			return;
		}

		if (!anyKeys)
		{
			ValueMin = 0.0f;
			ValueMax = 1.0f;
			return;
		}

		let center = (keyLow + keyHigh) * 0.5f;
		let span = keyHigh - keyLow;

		// A FLOOR on the span, so keys that happen to cluster do not collapse the axis onto
		// them and turn every small difference into a full height swing.
		let minimumSpan = Max(0.5f, Abs(center) * 0.5f);
		if (span < minimumSpan)
		{
			ValueMin = center - (minimumSpan * 0.5f);
			ValueMax = center + (minimumSpan * 0.5f);
			return;
		}

		let margin = span * 0.1f;
		ValueMin = keyLow - margin;
		ValueMax = keyHigh + margin;
	}

	// ---- Tangent handles ------------------------------------------------------------------------

	/// Where a tangent handle sits on screen: a FIXED length along the direction the slope
	/// points, so a handle is the same size to grab whatever the zoom.
	private void ComputeHandlePos(int32 channelIndex, int32 keyIndex, bool outgoing,
		out float hx, out float hy)
	{
		let key = mChannels[channelIndex].Keys[keyIndex];
		let kx = TimeToX(key.Time);
		let ky = ValueToY(key.Value);

		let pixelsPerValue = (ValueMax > (ValueMin + 0.0001f)) ? (Height / (ValueMax - ValueMin))
			: 0.0f;
		// Pixels per SECOND, not per full width. The slopes are value per second, so a
		// direction built from anything else lies by a factor of the span.
		let pixelsPerSecond = PixelsPerTime();
		let slope = outgoing ? key.TangentOut : key.TangentIn;

		let dx = outgoing ? pixelsPerSecond : -pixelsPerSecond;
		let dy = outgoing ? (-slope * pixelsPerValue) : (slope * pixelsPerValue);
		let norm = Sqrt((dx * dx) + (dy * dy));

		if (norm < 0.0001f)
		{
			hx = kx + (outgoing ? HandleScreenLength : -HandleScreenLength);
			hy = ky;
			return;
		}

		hx = kx + (HandleScreenLength * dx / norm);
		hy = ky + (HandleScreenLength * dy / norm);
	}

	/// The inverse of the projection above: a screen direction back to a slope in value per
	/// second.
	private float HandleScreenToDataSlope(float screenDx, float screenDy)
	{
		if (Abs(screenDx) < 0.0001f)
			return 0.0f;

		let pixelsPerValue = (ValueMax > (ValueMin + 0.0001f)) ? (Height / (ValueMax - ValueMin))
			: 1.0f;
		if (pixelsPerValue < 0.0001f)
			return 0.0f;

		return -(screenDy / screenDx) * PixelsPerTime() / pixelsPerValue;
	}

	// ---- Hit testing ----------------------------------------------------------------------------

	/// Whether the point is on one of the SELECTED key's handles, and which. Only the selected
	/// key has handles drawn, so only it can have them hit.
	private bool HitHandle(float x, float y, out bool outgoing)
	{
		outgoing = false;

		if ((mSelectedChannel < 0) || (mSelectedKey < 0)
			|| (mSelectedChannel >= mChannels.Count))
			return false;

		let channel = mChannels[mSelectedChannel];
		if (channel.Hidden || channel.Locked || (channel.Interpolation != .Hermite)
			|| (mSelectedKey >= channel.Keys.Count))
			return false;

		ComputeHandlePos(mSelectedChannel, mSelectedKey, true, let ox, let oy);
		if (WithinRadius(x - ox, y - oy, HandleHitRadius))
		{
			outgoing = true;
			return true;
		}

		ComputeHandlePos(mSelectedChannel, mSelectedKey, false, let ix, let iy);
		return WithinRadius(x - ix, y - iy, HandleHitRadius);
	}

	/// The key under the point, if any.
	///
	/// The SELECTED channel is tried first, so overlapping keys resolve in favour of the one the
	/// user is already working on rather than by channel order.
	private bool HitKey(float x, float y, out int32 channelIndex, out int32 keyIndex)
	{
		channelIndex = -1;
		keyIndex = -1;
		UpdateAutoFit();

		if ((mSelectedChannel >= 0) && (mSelectedChannel < mChannels.Count)
			&& HitKeyInChannel(mSelectedChannel, x, y, out keyIndex))
		{
			channelIndex = mSelectedChannel;
			return true;
		}

		for (int32 c = 0; c < mChannels.Count; c++)
		{
			if (c == mSelectedChannel)
				continue;

			if (HitKeyInChannel(c, x, y, out keyIndex))
			{
				channelIndex = c;
				return true;
			}
		}

		return false;
	}

	private bool HitKeyInChannel(int32 channelIndex, float x, float y, out int32 keyIndex)
	{
		keyIndex = -1;

		let channel = mChannels[channelIndex];
		if (channel.Hidden)
			return false;

		for (int32 i = 0; i < channel.Keys.Count; i++)
		{
			if (WithinRadius(x - TimeToX(channel.Keys[i].Time),
				y - ValueToY(channel.Keys[i].Value), KeyHitRadius))
			{
				keyIndex = i;
				return true;
			}
		}

		return false;
	}

	private static bool WithinRadius(float dx, float dy, float radius) =>
		((dx * dx) + (dy * dy)) <= (radius * radius);
}
