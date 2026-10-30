using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.Audio;

/// A clip's peak waveform, a widget of the editor's on the GUI (Raptor's editor-gui spec, 5.4,
/// layer 5): symmetric bars per bucket about the middle line, and a playhead at a fraction of the
/// clip while it plays. Its colours are the sheet's (`waveform` the tag, its background its own box,
/// its parts `wave` and `playhead`), so it follows the theme.
class WaveformView : UIWidget
{
	private List<float> mPeaks = new .() ~ delete _;
	/// A fraction of the clip; below zero: none (stopped).
	private float mPlayhead = -1.0f;

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

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("wave");
		outParts.Add("playhead");
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
			let half = Math.Max(1.0f, mPeaks[i] * (localBounds.Height * 0.5f - 2.0f));
			wave.Draw(ctx, Rect(localBounds.X + (float)i * bar, mid - half, Math.Max(1.0f, bar - 1.0f), half * 2.0f), FilledBox(waveColor, scope NodeBox()));
		}
		if ((mPlayhead >= 0.0f) && (mPlayhead <= 1.0f))
			GetPartStyle("playhead").Draw(ctx, Rect(localBounds.X + mPlayhead * localBounds.Width - 1.0f, localBounds.Y, 2.0f, localBounds.Height),
				FilledBox(Color(0.95f, 0.85f, 0.4f, 1.0f), scope NodeBox()));
	}
}
