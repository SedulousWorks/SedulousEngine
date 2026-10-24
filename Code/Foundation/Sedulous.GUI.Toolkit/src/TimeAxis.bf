using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// One time axis: the scale (pixels per second), the scroll (the time at a view's start), a frame rate
// (labels and snapping in frames) and the playhead, held once and read by every view on it (the
// ruler, a curve view, a dopesheet), none keeping a copy, so views stacked on one axis stay in step
// (foundation.ui's lesson: its curve canvas copied the timeline's). The views hold the axis, so it
// outlives them, and each leaves it as it goes.
//
// TimeRuler draws the axis: ticks at a step picked so labels never collide (the smallest of 1, 2 or 5
// times a power of ten, of seconds or of frames), labels, and the playhead. A drag on it scrubs the
// playhead, the wheel zooms about the pointer and a middle drag pans. Time runs left to right in
// either direction of the text, as a ruler's numbers do.

static
{
	/// `value` to the decimals of `step` (0.25 to two, 5 to none): a ruler's or a grid's label,
	/// appended to `outText`.
	public static void FormatStepped(float value, float step, String outText)
	{
		int32 decimals = 0;
		for (float s = step; (s < 0.999f) && (decimals < 6); s *= 10.0f)
			++decimals;
		double scale = 1.0;
		for (int32 d = 0; d < decimals; ++d)
			scale *= 10.0;
		let rounded = (double)(int64)((double)value * scale + ((value < 0.0f) ? -0.5 : 0.5)) / scale;
		if (decimals == 0)
		{
			((int64)rounded).ToString(outText);
			return;
		}
		rounded.ToString(outText);
	}
}

/// What a time axis tells the views on it.
interface ITimeAxisClient
{
	/// The scale, the scroll, the frame rate, the duration or the playhead changed: draw again.
	void OnTimeAxisChanged();
}

class TimeAxis : RefCounted
{
	public const float cMinPixelsPerSecond = 1.0f;
	public const float cMaxPixelsPerSecond = 20000.0f;

	private float mPixelsPerSecond = 100.0f;
	private float mScroll = 0.0f;
	private float mDuration = 10.0f;
	private float mFrameRate = 0.0f;
	private float mPlayhead = 0.0f;
	// Not owned: each leaves as it goes.
	private List<ITimeAxisClient> mClients = new .() ~ delete _;
	private delegate void(float seconds) mOnPlayhead ~ delete _;

	// === The scale and the scroll ===

	public float PixelsPerSecond
	{
		get => mPixelsPerSecond;
		set
		{
			let pixels = Clamp(value, cMinPixelsPerSecond, cMaxPixelsPerSecond);
			if (pixels == mPixelsPerSecond)
				return;
			mPixelsPerSecond = pixels;
			Changed();
		}
	}

	/// The time at a view's start.
	public float Scroll
	{
		get => mScroll;
		set
		{
			let seconds = ClampScroll(value);
			if (seconds == mScroll)
				return;
			mScroll = seconds;
			Changed();
		}
	}

	/// Scales by `factor` keeping `time` where it is in the view (the wheel's zoom about the
	/// pointer).
	public void ZoomAbout(float time, float factor)
	{
		let offset = TimeToOffset(time);
		let pixels = Clamp(mPixelsPerSecond * factor, cMinPixelsPerSecond, cMaxPixelsPerSecond);
		let scroll = ClampScroll(time - offset / pixels);
		if ((pixels == mPixelsPerSecond) && (scroll == mScroll))
			return;
		mPixelsPerSecond = pixels;
		mScroll = scroll;
		Changed();
	}

	/// Fits [start, end] into `width` pixels of a view.
	public void Frame(float start, float end, float width)
	{
		if (width <= 0.0f)
			return;
		let span = Max(end - start, 1.0f / cMaxPixelsPerSecond * width);
		mPixelsPerSecond = Clamp(width / span, cMinPixelsPerSecond, cMaxPixelsPerSecond);
		mScroll = ClampScroll(start);
		Changed();
	}

	/// Pixels from a view's start to `time`, and back.
	public float TimeToOffset(float time) => (time - mScroll) * mPixelsPerSecond;
	public float OffsetToTime(float offset) => mScroll + offset / mPixelsPerSecond;

	// === The clip ===

	/// How long what it shows lasts (seconds): where the scroll and the playhead stop.
	public float Duration
	{
		get => mDuration;
		set
		{
			let seconds = Max(value, 0.0f);
			if (seconds == mDuration)
				return;
			mDuration = seconds;
			mScroll = ClampScroll(mScroll);
			mPlayhead = Clamp(mPlayhead, 0.0f, mDuration);
			Changed();
		}
	}

	/// Frames per second, for labels and snapping in frames; 0: seconds, no snapping.
	public float FrameRate
	{
		get => mFrameRate;
		set
		{
			let framesPerSecond = Max(value, 0.0f);
			if (framesPerSecond == mFrameRate)
				return;
			mFrameRate = framesPerSecond;
			Changed();
		}
	}

	/// `time` on the nearest frame, with a frame rate; else as it is.
	public float Snap(float time)
	{
		if (mFrameRate <= 0.0f)
			return time;
		return Round(time * mFrameRate) / mFrameRate;
	}

	// === The playhead ===

	/// Moving it (kept in the clip) tells whoever plays it.
	public float Playhead
	{
		get => mPlayhead;
		set
		{
			let seconds = Clamp(value, 0.0f, mDuration);
			if (seconds == mPlayhead)
				return;
			mPlayhead = seconds;
			if (mOnPlayhead != null)
				mOnPlayhead(mPlayhead);
			Changed();
		}
	}

	/// The playhead moved (a scrub, or code): what samples the clip there. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnPlayheadChanged(delegate void(float seconds) callback)
	{
		delete mOnPlayhead;
		mOnPlayhead = callback;
	}

	// === Ticks ===

	/// The step between labelled ticks (seconds): of 1, 2 or 5 times a power of ten, of seconds, or
	/// of frames with a frame rate (one frame the least), the smallest at least `minPixels` wide.
	public float TickStep(float minPixels)
	{
		let least = minPixels / mPixelsPerSecond; // seconds
		if (mFrameRate > 0.0f)
			return PickStep(Max(least * mFrameRate, 1.0f)) / mFrameRate;
		return PickStep(least);
	}

	/// `time` as a label: seconds to the step's decimals, or a frame number with a frame rate;
	/// appended to `outText`.
	public void FormatTime(float time, float step, String outText)
	{
		if (mFrameRate > 0.0f)
		{
			((int64)Round(time * mFrameRate)).ToString(outText);
			return;
		}
		FormatStepped(time, step, outText);
	}

	// === Views ===

	public void Join(ITimeAxisClient client)
	{
		mClients.Add(client);
	}

	public void Leave(ITimeAxisClient client)
	{
		for (int i = 0; i < mClients.Count; ++i)
		{
			if (mClients[i] === client)
			{
				mClients.RemoveAt(i);
				return;
			}
		}
	}

	public int ClientCount => mClients.Count;

	// The smallest of 1, 2, 5 times a power of ten at least `least`.
	private static float PickStep(float least)
	{
		if (least <= 0.0f)
			return 1.0f;
		let magnitude = Pow(10.0f, Floor(Log(least) / Log(10.0f)));
		float[3] multiples = .(1.0f, 2.0f, 5.0f);
		for (let m in multiples)
		{
			if (m * magnitude >= least * 0.9999f)
				return m * magnitude;
		}
		return 10.0f * magnitude;
	}

	private float ClampScroll(float seconds) => Clamp(seconds, 0.0f, mDuration);

	private void Changed()
	{
		for (int i = 0; i < mClients.Count; ++i)
			mClients[i].OnTimeAxisChanged();
	}
}

/// A labelled tick of a ruler. A class: it owns its label.
class TimeTick
{
	public float Time = 0.0f;
	/// From the ruler's content start.
	public float Offset = 0.0f;
	/// Labelled.
	public bool Major = false;
	public String Label = new .() ~ delete _;
}

/// The axis drawn: ticks, labels and the playhead; a drag scrubs, the wheel zooms, a middle drag
/// pans.
[GuiReflect(true)]
class TimeRuler : UIWidget, ITimeAxisClient
{
	/// Labelled ticks at least this far apart (pixels).
	public const float cMinLabelSpacing = 60.0f;

	private Sedulous.GUI.TimeAxis mAxis = null;
	// Each label in turn.
	private Sedulous.GUI.Text mText = new .() ~ delete _;
	private bool mScrubbing = false;
	private bool mPanning = false;
	private float mPanFrom = 0.0f;
	private float mPanScroll = 0.0f;

	public this()
	{
		Tag = "timeruler";
		EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(22.0f); });
	}

	public ~this()
	{
		if (mAxis != null)
		{
			mAxis.Leave(this);
			mAxis.ReleaseRef();
		}
	}

	/// The axis it draws. It takes a reference of its own: the caller keeps its.
	public Sedulous.GUI.TimeAxis TimeAxis
	{
		get => mAxis;
		set
		{
			if (value != null)
				value.AddRef();
			if (mAxis != null)
			{
				mAxis.Leave(this);
				mAxis.ReleaseRef();
			}
			mAxis = value;
			if (mAxis != null)
				mAxis.Join(this);
			Invalidate();
		}
	}

	/// The ticks across its width now: every minor tick, the major ones labelled. `outTicks` is
	/// emptied first; the caller deletes what it holds.
	public void GetTicks(List<TimeTick> outTicks)
	{
		ClearAndDeleteItems!(outTicks);
		if (mAxis == null)
			return;
		let @box = ContentBounds;
		let step = mAxis.TickStep(cMinLabelSpacing);
		let minor = step / MinorDivisions(step);
		let end = mAxis.OffsetToTime(@box.Width);
		let first = (int64)Ceil(mAxis.Scroll / minor - 0.001f);
		for (int64 i = first;; ++i)
		{
			let time = (float)i * minor;
			if ((time > end + minor * 0.001f) || (time > mAxis.Duration + minor * 0.001f))
				break;
			let tick = new TimeTick();
			tick.Time = time;
			tick.Offset = mAxis.TimeToOffset(time);
			let steps = time / step;
			tick.Major = Abs(steps - Round(steps)) < 0.001f;
			if (tick.Major)
				mAxis.FormatTime(time, step, tick.Label);
			outTicks.Add(tick);
		}
	}

	public void OnTimeAxisChanged()
	{
		Invalidate();
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (mAxis == null)
			return;
		if (e.Button == .Left)
		{
			e.Handled = true;
			mScrubbing = true;
			ScrubTo(e.Position);
		}
		else if (e.Button == .Middle)
		{
			e.Handled = true;
			mPanning = true;
			mPanFrom = e.Position.X;
			mPanScroll = mAxis.Scroll;
		}
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (mAxis == null)
			return;
		if (mScrubbing)
			ScrubTo(e.Position);
		else if (mPanning)
			mAxis.Scroll = mPanScroll - (e.Position.X - mPanFrom) / mAxis.PixelsPerSecond;
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (mScrubbing && (e.Button == .Left))
			mScrubbing = false;
		if (mPanning && (e.Button == .Middle))
			mPanning = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mScrubbing = false;
		mPanning = false;
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		if ((mAxis == null) || (e.Delta.Y == 0.0f))
			return;
		e.Handled = true;
		mAxis.ZoomAbout(TimeAt(e.Position), Pow(1.2f, e.Delta.Y));
	}

	public override Sedulous.GUI.Cursor CursorNow => mPanning ? .Grabbing : base.CursorNow;

	protected override void OnTextStyleChange()
	{
		mText.Font = Font;
		mText.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
		mText.Color = TextColor;
		mText.SetAlignment(.Start, .Top);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (mAxis == null)
			return;
		let @box = ContentBounds;
		let tickPart = GetPartStyle("tick");
		var tickColor = tickPart.HasBackground ? tickPart.Box.BackgroundColor : TextColor;
		tickColor.A *= tickPart.Opacity;
		let ticks = scope List<TimeTick>();
		defer { ClearAndDeleteItems!(ticks); }
		GetTicks(ticks);
		ctx.PushClip(@box);
		for (let tick in ticks)
		{
			let x = @box.X + tick.Offset;
			let length = tick.Major ? @box.Height * 0.5f : @box.Height * 0.25f;
			ctx.VG.FillRect(.(Floor(x), @box.Bottom - length, 1.0f, length), tickColor);
			if (tick.Major && mText.HasFont)
			{
				mText.SetString(tick.Label);
				mText.Draw(ctx, Float2(x + 3.0f, @box.Y + 1.0f));
			}
		}
		let playheadPart = GetPartStyle("playhead");
		var playhead = playheadPart.HasBackground ? playheadPart.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 1.0f);
		playhead.A *= playheadPart.Opacity;
		let x = @box.X + mAxis.TimeToOffset(mAxis.Playhead);
		ctx.VG.FillRect(.(Floor(x) - 1.0f, @box.Y, 2.0f, @box.Height), playhead);
		let head = scope PathBuilder();
		head.MoveTo(x - 5.0f, @box.Y);
		head.LineTo(x + 5.0f, @box.Y);
		head.LineTo(x, @box.Y + 6.0f);
		head.Close();
		let path = head.ToPath();
		ctx.VG.FillPath(path, playhead);
		delete path;
		ctx.PopClip();
	}

	// A labelled step's minor ticks: fifths of a 1 or 5, halves of a 2; a frame's none.
	private float MinorDivisions(float step)
	{
		let units = (mAxis.FrameRate > 0.0f) ? step * mAxis.FrameRate : step;
		let lead = units / Pow(10.0f, Floor((Log(units) / Log(10.0f)) + 0.0001f));
		let divisions = (Abs(lead - 2.0f) < 0.01f) ? 2.0f : 5.0f;
		if ((mAxis.FrameRate > 0.0f) && (units / divisions < 1.0f))
			return Max(1.0f, Floor(units)); // never between frames
		return divisions;
	}

	private float TimeAt(Float2 screen)
	{
		let local = ConvertToNodeSpace(screen); // events come in screen space
		return mAxis.OffsetToTime(local.X - ContentBounds.X);
	}

	private void ScrubTo(Float2 screen)
	{
		mAxis.Playhead = mAxis.Snap(TimeAt(screen));
	}
}
