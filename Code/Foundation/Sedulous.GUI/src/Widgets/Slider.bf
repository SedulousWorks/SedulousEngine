using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// Slider: a draggable value over a range: a RangeWidget, so min, max, step, page, exponential and
// the rest are its; horizontal or vertical (a vertical one's value grows upward). Pressing or
// dragging sets the value from the pointer, the dispatcher's capture keeping a drag that leaves
// it; a drag reports `input` as it goes and `change` on release. The arrows along it step it (and
// stay its own at its ends: holding the d-pad to reach an end must not throw focus off it), Page
// Up and Down step a page, Home and End go to the ends, and the wheel steps it while it is hovered
// or focused (unless told not to: in a scrolling list the wheel is the list's). Escape during a drag
// puts the value back as it was before it, and reports the drag cancelled. Ticks, when asked for,
// mark the track at even steps. Modeled on eepp's UISlider (role only).

[GuiReflect(true), Scriptable]
class Slider : RangeWidget
{
	private Sedulous.GUI.Orientation mOrientation = .Horizontal;
	private int32 mTicks = 0;
	private bool mDragging = false;
	// The value before the drag, what Escape puts back.
	private double mDragStart = 0.0;
	private bool mStepsOnWheel = true;
	private delegate void() mOnCancelled ~ delete _;
	private Color mTrackColor = .(0.28f, 0.30f, 0.35f, 1.0f);
	private Color mFillColor = .(0.31f, 0.63f, 0.85f, 1.0f);
	private Color mHandleColor = .(0.86f, 0.89f, 0.93f, 1.0f);
	private Color mFocusColor = .(0.31f, 0.61f, 1.0f, 1.0f);

	public this()
	{
		Tag = "slider";
		AccessRoleName = "slider"; // what a screen reader takes it for
		TabFocusable = true;
	}

	/// Whether the wheel steps it (on); off, the wheel goes on to what holds it.
	public bool StepsOnWheel
	{
		get => mStepsOnWheel;
		set => mStepsOnWheel = value;
	}

	/// A drag given up with Escape: the value is back as it was before it. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnValueCancelled(delegate void() callback)
	{
		delete mOnCancelled;
		mOnCancelled = callback;
	}

	public bool IsDragging => mDragging;

	/// A page key's step (0: a tenth of the range).
	[GuiProperty("page"), Scriptable]
	public double Page
	{
		get => PageSize;
		set => PageSize = value;
	}

	public Sedulous.GUI.Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (value == mOrientation)
				return;
			mOrientation = value;
			RequestLayout();
			Invalidate();
		}
	}

	/// "horizontal" or "vertical" (markup's and a sheet's `orientation`).
	[GuiProperty("orientation"), Scriptable]
	public StringView OrientationName
	{
		get => (mOrientation == .Vertical) ? "vertical" : "horizontal";
		set => Orientation = (value == "vertical") ? .Vertical : .Horizontal;
	}

	/// How many marks along the track (its ends included; 0 or 1: none).
	[GuiProperty("ticks"), Scriptable]
	public int32 Ticks
	{
		get => mTicks;
		set
		{
			mTicks = Math.Max(0, value);
			Invalidate();
		}
	}

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

	public Color HandleColor
	{
		get => mHandleColor;
		set
		{
			mHandleColor = value;
			Invalidate();
		}
	}

	/// The ring and halo around the thumb while it has keyboard or pad focus.
	public Color FocusColor
	{
		get => mFocusColor;
		set
		{
			mFocusColor = value;
			Invalidate();
		}
	}

	// Theming parts: slider::track / ::fill / ::thumb / ::focus (the thumb's ring) / ::tick.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("track");
		outParts.Add("fill");
		outParts.Add("thumb");
		outParts.Add("focus");
		outParts.Add("tick");
	}

	/// A track's length and a thumb's size when nothing sizes it.
	public override Float2 MeasureContent(Float2 available)
	{
		return (mOrientation == .Vertical) ? Float2(24.0f, 160.0f) : Float2(160.0f, 24.0f);
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if (e.Modifiers != 0)
			return;
		let key = (KeyCode)e.KeyCode;
		if (mDragging)
		{
			if (key == .Escape)
			{
				mDragging = false;
				Value = mDragStart; // back, and nothing to commit
				if (mOnCancelled != null)
					mOnCancelled();
				e.Handled = true;
			}
			return; // a drag's keys are its own
		}
		let vertical = mOrientation == .Vertical;
		let step = Range.KeyStep;
		let v = Range.Value;
		// A horizontal one runs from its start: Left raises it in right to left.
		let lower = Reversed ? KeyCode.Right : KeyCode.Left;
		let raise = Reversed ? KeyCode.Left : KeyCode.Right;
		if ((!vertical && (key == lower)) || (vertical && (key == .Down)))
			ChangeByUser(v - step, true);
		else if ((!vertical && (key == raise)) || (vertical && (key == .Up)))
			ChangeByUser(v + step, true);
		else if (key == .PageDown)
			ChangeByUser(v - Range.PageStep, true);
		else if (key == .PageUp)
			ChangeByUser(v + Range.PageStep, true);
		else if (key == .Home)
			ChangeByUser(Range.Min, true);
		else if (key == .End)
			ChangeByUser(Range.Upper, true);
		else
			return;
		e.Handled = true;
	}

	// The wheel steps it while it is hovered or focused; at an end, or told not to step, it goes on
	// to what holds it.
	protected override void OnMouseWheel(WheelEvent e)
	{
		let notches = (e.Delta.Y != 0.0f) ? e.Delta.Y : e.Delta.X;
		if ((notches == 0.0f) || !mStepsOnWheel)
			return;
		let before = Range.Value;
		ChangeByUser(before + Range.KeyStep * (double)notches, true);
		e.Handled = Range.Value != before;
	}

	// Its press is its own: a drag from what holds it is not offered.
	public override bool OwnsPressDrag(Float2 local) => true;

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		mDragging = true;
		mDragStart = Range.Value;
		UpdateFromEvent(e);
		e.Handled = true;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (mDragging)
			UpdateFromEvent(e);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (mDragging)
			Commit();
		mDragging = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		if (mDragging)
			Commit();
		mDragging = false;
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let b = ContentBounds;
		let vertical = mOrientation == .Vertical;
		let handleR = HandleRadius(b);
		// The track's thickness: the sheet's (slider::track { height }, a vertical one's width) or 4.
		let trackStyle = GetPartStyle("track");
		let sized = vertical ? trackStyle.HasWidth : trackStyle.HasHeight;
		let trackW = sized ? (vertical ? trackStyle.Width : trackStyle.Height) : 4.0f;
		let ratio = (float)Ratio;
		let lo = (vertical ? b.Y : b.X) + handleR;
		let hi = (vertical ? b.Y + b.Height : b.X + b.Width) - handleR;
		// Along the track: from its start (left, or right in right to left), or bottom to top.
		let reversed = Reversed;
		let along = (vertical || reversed) ? hi - (hi - lo) * ratio : lo + (hi - lo) * ratio;
		let mid = vertical ? b.X + b.Width * 0.5f : b.Y + b.Height * 0.5f;
		let handle = vertical ? Float2(mid, along) : Float2(along, mid);
		let round = CornerRadii(trackW * 0.5f);

		// Each part its own look with the sheet's over it (slider::track, ::fill, ::tick, ::thumb, ::focus).
		let track = vertical ? Rect(mid - trackW * 0.5f, b.Y, trackW, b.Height) : Rect(b.X, mid - trackW * 0.5f, b.Width, trackW);
		trackStyle.Draw(ctx, track, FilledBox(mTrackColor, round, scope NodeBox()));
		let fill = vertical ? Rect(track.X, along, trackW, b.Y + b.Height - along)
			: (reversed ? Rect(along, track.Y, b.X + b.Width - along, trackW) : Rect(b.X, track.Y, along - b.X, trackW));
		GetPartStyle("fill").Draw(ctx, fill, FilledBox(mFillColor, round, scope NodeBox()));
		if (mTicks >= 2)
		{
			let tick = GetPartStyle("tick");
			let own = FilledBox(mTrackColor, scope NodeBox());
			for (int32 i = 0; i < mTicks; ++i)
			{
				let t = (float)i / (float)(mTicks - 1);
				let at = vertical ? hi - (hi - lo) * t : lo + (hi - lo) * t;
				let mark = vertical ? Rect(mid + trackW, at - 0.5f, 4.0f, 1.0f) : Rect(at - 0.5f, mid + trackW, 1.0f, 4.0f);
				tick.Draw(ctx, mark, own);
			}
		}
		// Focused by the keyboard or a pad, the thumb (the part that moves) is marked: a ring round
		// it with a glow, not a ring around the whole track.
		if (FocusVisible)
		{
			// Its glow takes the ring's colour, the sheet's (slider::focus { border-color }) or its own.
			let focus = GetPartStyle("focus");
			let ringColor = (focus.HasBorderColor || focus.HasBorderWidth) ? focus.Box.BorderColors.Top : mFocusColor;
			let ringR = handleR + 3.0f;
			let ring = OutlinedBox(ringColor, 2.0f, CornerRadii(ringR), scope NodeBox());
			var glow = BoxShadow();
			glow.Offset = .(0.0f, 0.0f);
			glow.Blur = 6.0f;
			glow.Spread = 1.0f;
			glow.ShadowColor = .(ringColor.R, ringColor.G, ringColor.B, ringColor.A * 0.45f);
			glow.Inset = false;
			ring.Shadows.Add(glow);
			focus.Draw(ctx, .(handle.X - ringR, handle.Y - ringR, ringR * 2.0f, ringR * 2.0f), ring);
		}
		GetPartStyle("thumb").Draw(ctx, .(handle.X - handleR, handle.Y - handleR, handleR * 2.0f, handleR * 2.0f),
			FilledBox(mHandleColor, CornerRadii(handleR), scope NodeBox()));
	}

	/// A horizontal slider in right to left runs from the right.
	private bool Reversed => (mOrientation == .Horizontal) && IsRightToLeft;

	/// The thumb's radius: the sheet's size (slider::thumb { width }) across the slider, or as wide as
	/// the slider is across; never past it.
	private float HandleRadius(Rect b)
	{
		let vertical = mOrientation == .Vertical;
		let across = vertical ? b.Width : b.Height;
		let thumb = GetPartStyle("thumb");
		let sized = thumb.HasWidth ? thumb.Width : (thumb.HasHeight ? thumb.Height : across);
		return Math.Min(sized, across) * 0.5f;
	}

	private void UpdateFromEvent(MouseEvent e)
	{
		let b = ContentBounds;
		let vertical = mOrientation == .Vertical;
		let handleR = HandleRadius(b);
		let local = ConvertToNodeSpace(e.Position);
		let lo = (vertical ? b.Y : b.X) + handleR;
		let hi = (vertical ? b.Y + b.Height : b.X + b.Width) - handleR;
		let at = vertical ? local.Y : local.X;
		float ratio = (hi > lo) ? (at - lo) / (hi - lo) : 0.0f;
		if (vertical || Reversed)
			ratio = 1.0f - ratio;
		ChangeByUser(Range.FromRatio((double)ratio), false);
	}
}
