using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.Audio;

/// A clip's peak envelope as a bar strip, with the audition playhead over it.
class WaveformView : View
{
	private List<float> mPeaks = new .() ~ delete _;
	/// A fraction of the strip, or below zero for none.
	private float mPlayhead = -1.0f;

	public void SetPeaks(Span<float> peaks)
	{
		mPeaks.Clear();
		mPeaks.AddRange(peaks);
		Invalidate();
	}

	public void SetPlayheadFraction(float fraction)
	{
		if (mPlayhead != fraction)
		{
			mPlayhead = fraction;
			Invalidate();
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0.0f, 0.0f, Width, Height);
		ctx.VG.FillRect(bounds, .(0.10f, 0.11f, 0.13f, 1.0f));
		if (mPeaks.IsEmpty || (bounds.Width <= 2.0f) || (bounds.Height <= 2.0f))
			return;
		let mid = bounds.Height * 0.5f;
		let barWidth = bounds.Width / (float)mPeaks.Count;
		let barColor = Color(64.0f / 255.0f, 200.0f / 255.0f, 190.0f / 255.0f, 0.9f);
		for (int i < mPeaks.Count)
		{
			let half = Math.Max(1.0f, mPeaks[i] * (mid - 2.0f));
			ctx.VG.FillRect(.((float)i * barWidth, mid - half, Math.Max(1.0f, barWidth - 1.0f), half * 2.0f), barColor);
		}
		if ((mPlayhead >= 0.0f) && (mPlayhead <= 1.0f))
			ctx.VG.FillRect(.(mPlayhead * bounds.Width - 1.0f, 0.0f, 2.0f, bounds.Height), .(0.95f, 0.85f, 0.4f, 1.0f));
	}
}
