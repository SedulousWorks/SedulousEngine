using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// ScrollBar: a draggable scroll position over a range: a RangeWidget whose value is the offset and
// whose page is the visible part, so the value goes no further than the maximum less the page and
// the thumb's length is the page's share of the range. Modeled on eepp's UIScrollBar (role, not a
// line-for-line port). Horizontal or vertical. A drag of the thumb keeps its grab point under the
// pointer and reports `input` as it goes and `change` on release; a press on the track pages
// toward it.

[GuiReflect(true)]
class ScrollBar : RangeWidget
{
	private const float cMinThumb = 16.0f;

	private Sedulous.GUI.Orientation mOrientation = .Vertical;
	private bool mDragging = false;
	private float mGrabOffset = 0.0f;
	private Color mTrackColor = .(0.18f, 0.19f, 0.23f, 1.0f);
	private Color mThumbColor = .(0.42f, 0.45f, 0.52f, 1.0f);

	public this()
	{
		Tag = "scrollbar";
		AccessRoleName = "scrollbar"; // what a screen reader takes it for
		SetPageShown(true); // its page is the visible part
		// The track is the node background so the theme's background-color styles it.
		SetBox(FilledBox(mTrackColor, scope NodeBox())); // its own track, which a sheet's (a theme's) replaces
	}

	public Sedulous.GUI.Orientation Orientation
	{
		get => mOrientation;
		set
		{
			mOrientation = value;
			Invalidate();
		}
	}

	/// "horizontal" or "vertical" (markup's `orientation`).
	[GuiProperty("orientation")]
	public StringView OrientationName
	{
		get => (mOrientation == .Vertical) ? "vertical" : "horizontal";
		set => Orientation = (ParseUtil.Trim(value) == "vertical") ? .Vertical : .Horizontal;
	}

	/// The visible part: the thumb's share of the range, and a track press's step.
	[GuiProperty("page")]
	public double Page
	{
		get => PageSize;
		set => PageSize = value;
	}

	/// The thumb's share of the track: the page over the range.
	public float ThumbProportion
	{
		get
		{
			let span = Range.Max - Range.Min;
			return (span > 0.0) ? (float)Math.Min(1.0, Range.Page / span) : 1.0f;
		}
	}

	public Color TrackColor
	{
		get => mTrackColor;
		set
		{
			mTrackColor = value;
			SetBox(FilledBox(value, scope NodeBox()));
		}
	}

	public Color ThumbColor
	{
		get => mThumbColor;
		set
		{
			mThumbColor = value;
			Invalidate();
		}
	}

	// Theming: track = background-color (node background); thumb = scrollbar::thumb part.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("thumb");
	}

	/// A bar's thickness and length when nothing sizes it.
	public override Float2 MeasureContent(Float2 available)
	{
		return (mOrientation == .Vertical) ? Float2(12.0f, 120.0f) : Float2(120.0f, 12.0f);
	}

	// Press on the thumb starts a grab-drag (the thumb keeps its offset under the cursor, so it
	// doesn't jump); press on the track above/below the thumb pages toward the click by one
	// visible proportion (eepp-style), no drag.
	// Its press is its own: a drag from what holds it is not offered.
	public override bool OwnsPressDrag(Float2 local) => true;

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return; // only the left button drags/pages
		e.Handled = true;
		let b = ContentBounds;
		let track = TrackLength(b);
		let thumbLen = ThumbLength(track);
		let travel = Math.Max(0.0f, track - thumbLen);
		let thumbStart = travel * (float)Ratio;
		let along = AlongAxis(e, b);

		if ((along >= thumbStart) && (along <= thumbStart + thumbLen))
		{
			mDragging = true;
			mGrabOffset = along - thumbStart; // keep the grab point fixed under the cursor
		}
		else
		{
			let page = Range.PageStep;
			ChangeByUser(Range.Value + ((along < thumbStart) ? -page : page), true);
		}
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mDragging)
			return;
		let b = ContentBounds;
		let track = TrackLength(b);
		let thumbLen = ThumbLength(track);
		let travel = Math.Max(0.0f, track - thumbLen);
		if (travel <= 0.0f)
			return;
		ChangeByUser(Range.FromRatio((double)((AlongAxis(e, b) - mGrabOffset) / travel)), false);
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
		let track = TrackLength(b);
		let thumbLen = ThumbLength(track);
		let travel = Math.Max(0.0f, track - thumbLen);
		let pos = travel * (float)Ratio;

		// The track is painted by the node background (themable via background-color); we draw
		// only the thumb here.
		// Across, its start is the inline start: the right in right to left.
		let thumb = (mOrientation == .Vertical)
			? Rect(b.X, b.Y + pos, b.Width, thumbLen)
			: Rect.MirroredIn(.(b.X + pos, b.Y, thumbLen, b.Height), b, IsRightToLeft);
		GetPartStyle("thumb").Draw(ctx, thumb, FilledBox(mThumbColor, Radii(thumb), scope NodeBox()));
	}

	private float TrackLength(Rect b) => (mOrientation == .Vertical) ? b.Height : b.Width;

	private float ThumbLength(float track) => Math.Min(track, Math.Max(cMinThumb, track * ThumbProportion));

	private static CornerRadii Radii(Rect r) => CornerRadii(Math.Min(r.Width, r.Height) * 0.5f);

	// Cursor position along the bar's axis, relative to the track start (the inline start across).
	private float AlongAxis(MouseEvent e, Rect b)
	{
		let local = ConvertToNodeSpace(e.Position);
		if (mOrientation == .Vertical)
			return local.Y - b.Y;
		return IsRightToLeft ? b.Right - local.X : local.X - b.X;
	}
}
