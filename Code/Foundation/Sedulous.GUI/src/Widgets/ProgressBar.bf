using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// ProgressBar: a display-only fill bar over a range: a RangeWidget (min, max, step and value; no
// page), its fill the value's share of the range. An indeterminate one (work of unknown length)
// sweeps a segment along the track on the GUI's clock instead. Modeled on eepp's UIProgressBar
// (role only).

[GuiReflect(true)]
class ProgressBar : RangeWidget
{
	private const float cSweepSeconds = 1.4f;

	private bool mIndeterminate = false;
	private bool mSweeping = false;
	private float mPhase = 0.0f;
	private Color mTrackColor = .(0.24f, 0.26f, 0.30f, 1.0f);
	private Color mFillColor = .(0.31f, 0.63f, 0.85f, 1.0f);

	public this()
	{
		Tag = "progressbar";
		AccessRoleName = "progress"; // what a screen reader takes it for
	}

	/// Work of unknown length: a segment sweeps along the track.
	[GuiProperty("indeterminate")]
	public bool Indeterminate
	{
		get => mIndeterminate;
		set
		{
			if (value == mIndeterminate)
				return;
			mIndeterminate = value;
			mPhase = 0.0f;
			Invalidate();
		}
	}

	/// Where the sweep is, 0 to 1 (a test reads it).
	public float SweepPhase => mPhase;

	public Color TrackColor
	{
		get => mTrackColor;
		set
		{
			mTrackColor = value;
			Invalidate();
		}
	}

	public Color FillColor
	{
		get => mFillColor;
		set
		{
			mFillColor = value;
			Invalidate();
		}
	}

	// Theming parts: progressbar::track / ::fill.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("track");
		outParts.Add("fill");
	}

	/// A bar's length and thickness when nothing sizes it.
	public override Float2 MeasureContent(Float2 available) => .(160.0f, 10.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let b = ContentBounds;
		let rtl = IsRightToLeft; // it fills from the inline start
		let radius = b.Height * 0.5f;
		GetPartStyle("track").Draw(ctx, b, FilledBox(mTrackColor, CornerRadii(radius), scope NodeBox()));
		if (mIndeterminate)
		{
			Sweep();
			// A third of the track, entering at the inline start and leaving at the end, clipped to it.
			let segment = b.Width / 3.0f;
			let x = b.X - segment + (b.Width + segment) * mPhase;
			let left = Math.Max(b.X, x);
			let right = Math.Min(b.X + b.Width, x + segment);
			if (right > left)
				GetPartStyle("fill").Draw(ctx, Rect.MirroredIn(.(left, b.Y, right - left, b.Height), b, rtl),
					FilledBox(mFillColor, CornerRadii(radius), scope NodeBox()));
			return;
		}
		let ratio = (float)Ratio;
		if (ratio > 0.0f)
			GetPartStyle("fill").Draw(ctx, Rect.MirroredIn(.(b.X, b.Y, b.Width * ratio, b.Height), b, rtl),
				FilledBox(mFillColor, CornerRadii(radius), scope NodeBox()));
	}

	// The sweep runs on the GUI's clock while it is indeterminate and shown.
	private void Sweep()
	{
		if (mSweeping || (ActionManager == null))
			return;
		mSweeping = true;
		let tick = new TickAction(new (elapsed) =>
			{
				if (!mIndeterminate)
				{
					mSweeping = false;
					return false;
				}
				mPhase += (float)elapsed.TotalSeconds / cSweepSeconds;
				while (mPhase >= 1.0f)
					mPhase -= 1.0f;
				Invalidate();
				return true;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}
}
