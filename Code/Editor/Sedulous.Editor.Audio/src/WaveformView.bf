using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.Audio;

/// A clip's peak waveform, a widget of the editor's on the GUI: symmetric bars per bucket about the
/// middle line, and a playhead at a fraction of the
/// clip while it plays. It can draw the clip as an edit would make it: its bars scaled by a gain
/// (clamped to full scale), and the part from a fraction on shaded as cut. Its colours are the
/// sheet's (`waveform` the tag, its background its own box, its parts `wave`, `playhead` and `cut`),
/// so it follows the theme.
class WaveformView : UIWidget
{
	private List<float> mPeaks = new .() ~ delete _;
	/// A fraction of the clip; below zero: none (stopped).
	private float mPlayhead = -1.0f;
	private float mGain = 1.0f;
	/// A fraction of the clip; 1 or more: nothing cut.
	private float mCutFrom = 1.0f;

	public this()
	{
		Tag = "waveform";
		AddClass("waveform");
	}

	/// Each bucket's peak, 0 to 1, left to right; none draws only the background.
	public void SetPeaks(Span<float> peaks)
	{
		mPeaks.Clear();
		mPeaks.AddRange(peaks);
		Invalidate();
	}

	public Span<float> Peaks => mPeaks;

	/// Where the playhead is along the clip, 0 to 1; below 0 hides it (stopped).
	public void SetPlayhead(float fraction)
	{
		if (fraction == mPlayhead)
			return;
		mPlayhead = fraction;
		Invalidate();
	}

	public float Playhead => mPlayhead;

	/// Draws each bar times `gain` (1: as it is), none taller than full scale.
	public void SetGain(float gain)
	{
		if (gain == mGain)
			return;
		mGain = gain;
		Invalidate();
	}

	public float Gain => mGain;

	/// Shades the clip from `fraction` (0 to 1) to its end as cut; 1 or more shades nothing.
	public void SetCutFrom(float fraction)
	{
		if (fraction == mCutFrom)
			return;
		mCutFrom = fraction;
		Invalidate();
	}

	public float CutFrom => mCutFrom;

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("wave");
		outParts.Add("playhead");
		outParts.Add("cut");
	}

	public override Float2 MeasureContent(Float2 available) => .(240.0f, 120.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (mPeaks.IsEmpty || (localBounds.Width <= 2.0f) || (localBounds.Height <= 2.0f))
			return;
		let mid = localBounds.Y + localBounds.Height * 0.5f;
		let bar = localBounds.Width / (float)mPeaks.Count;
		let wave = GetPartStyle("wave");
		let waveColor = Color(0.25f, 0.78f, 0.75f, 0.9f); // without a sheet
		for (int i < mPeaks.Count)
		{
			let half = Math.Max(1.0f, Math.Min(mPeaks[i] * mGain, 1.0f) * (localBounds.Height * 0.5f - 2.0f));
			wave.Draw(ctx, Rect(localBounds.X + (float)i * bar, mid - half, Math.Max(1.0f, bar - 1.0f), half * 2.0f), FilledBox(waveColor, scope NodeBox()));
		}
		if (mCutFrom < 1.0f)
		{
			let from = localBounds.X + Math.Max(mCutFrom, 0.0f) * localBounds.Width;
			GetPartStyle("cut").Draw(ctx, Rect(from, localBounds.Y, localBounds.X + localBounds.Width - from, localBounds.Height),
				FilledBox(Color(0.0f, 0.0f, 0.0f, 0.45f), scope NodeBox()));
		}
		if ((mPlayhead >= 0.0f) && (mPlayhead <= 1.0f))
			GetPartStyle("playhead").Draw(ctx, Rect(localBounds.X + mPlayhead * localBounds.Width - 1.0f, localBounds.Y, 2.0f, localBounds.Height),
				FilledBox(Color(0.95f, 0.85f, 0.4f, 1.0f), scope NodeBox()));
	}
}
