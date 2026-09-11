using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Toolkit;

/// A small window floating over the editor: a title strip you can drag it by, a chevron that
/// collapses it to that strip, a close cross, and a resize grip in the bottom right.
///
/// It positions itself through its own LayoutStyle Left and Top, so it MUST be hosted in an
/// absolute layout. That layout places a child at exactly those coordinates at its measured
/// size, which is what makes Bounds equal them and keeps every later hit test coordinate exact.
/// A margin or a render transform would do neither.
///
/// SIZE FLOWS ONE WAY. The panel's own width and height are authoritative, clamped to the
/// minimum and to the room the parent has, and the content is measured as a CONSEQUENCE of
/// that. Letting the content feed back into the size makes a resize oscillate.
class FloatingPanel : ViewGroup
{
	private const float HeaderHeight = 24.0f;
	private const float ContentInset = 6.0f;
	/// The bottom right grab square. Larger than the edge bands, following the convention for a
	/// window's resize grip, and safe because the corner of a scrollable area is dead space.
	private const float ResizeCorner = 12.0f;
	private const float ChevronBoxWidth = 22.0f;
	private const float ChevronX = 8.0f;
	private const float ChevronSize = 8.0f;
	private const float CloseBoxWidth = 24.0f;
	/// Wide enough for a small tool row and a property field beside its label.
	private const float MinWidth = 240.0f;
	private const float MinHeight = HeaderHeight + 60.0f;

	/// Fired by the close cross. The consumer decides what closing MEANS, which is usually
	/// deactivating a tool rather than destroying the panel.
	public Event<delegate void()> OnClose ~ _.Dispose();

	private String mTitle = new .() ~ delete _;
	/// OWNED reference; also a child.
	private View mContent = null;

	private bool mCollapsed = false;
	private bool mCloseHover = false;
	private float mUserWidth = 240.0f;
	private float mUserHeight = HeaderHeight + 170.0f;

	private bool mDragging = false;
	private bool mResizing = false;
	private bool mResizeRight = false;
	private bool mResizeBottom = false;
	/// Where in the panel a drag was grabbed, in panel local coordinates.
	private float mGrabLocalX = 0.0f;
	private float mGrabLocalY = 0.0f;
	/// A resize's offset from the grabbed point to the corner.
	private float mGrabOffsetX = 0.0f;
	private float mGrabOffsetY = 0.0f;

	public this(StringView title)
	{
		mTitle.Set(title);
	}

	public StringView Title => mTitle;

	public void SetTitle(StringView title)
	{
		mTitle.Set(title);
		Invalidate();
	}

	/// BORROWED.
	public View Content => mContent;

	/// Replaces the body. CONSUMES the caller's reference; null clears.
	public void SetContent(View content)
	{
		if (mContent != null)
			RemoveView(mContent);

		mContent = content;
		if (mContent != null)
		{
			AddView(mContent);
			mContent.Visibility = mCollapsed ? .Gone : .Visible;
		}

		Invalidate();
	}

	/// The size expressed as the CONTENT the panel should hold; the header and insets are added
	/// on. A later resize overrides it.
	public void SetPreferredContentSize(float width, float height)
	{
		mUserWidth = Max(MinWidth, width + (2.0f * ContentInset));
		mUserHeight = Max(MinHeight, HeaderHeight + height + ContentInset);
		Invalidate();
	}

	public bool IsCollapsed => mCollapsed;

	public void SetCollapsed(bool collapsed)
	{
		if (mCollapsed == collapsed)
			return;

		mCollapsed = collapsed;
		if (mContent != null)
			mContent.Visibility = collapsed ? .Gone : .Visible;

		Invalidate();
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let width = constraints.ConstrainWidth(Max(MinWidth, mUserWidth));
		let height = mCollapsed ? constraints.ConstrainHeight(HeaderHeight)
			: constraints.ConstrainHeight(Max(MinHeight, mUserHeight));

		if ((mContent != null) && !mCollapsed)
			mContent.Measure(BoxConstraints.Tight(Max(0.0f, width - (2.0f * ContentInset)),
				Max(0.0f, height - HeaderHeight - ContentInset)));

		MeasuredSize = .(width, height);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Re-clamped EVERY layout, because the parent's size is only known here. A viewport
		// that shrank, the bottom dock expanding upward say, must pull the panel back inside
		// rather than leave it sliding out of sight behind the new chrome.
		ClampToParent();

		if ((mContent != null) && !mCollapsed)
			mContent.Layout(ContentInset, HeaderHeight,
				Max(0.0f, width - (2.0f * ContentInset)),
				Max(0.0f, height - HeaderHeight - ContentInset));
	}

	/// Keeps the WHOLE panel inside its parent.
	///
	/// Clamped against the INTENDED size rather than the laid out one, which lags a frame, and
	/// run unconditionally because an absolute layout does not clamp an overflowing child, so
	/// this is the only guard there is.
	private void ClampToParent()
	{
		if (Parent == null)
			return;

		let intendedWidth = Max(MinWidth, mUserWidth);
		let intendedHeight = mCollapsed ? HeaderHeight : Max(MinHeight, mUserHeight);

		var placement = Layout;
		placement.Left = Clamp(placement.Left.Value, 0.0f,
			Max(0.0f, Parent.Bounds.Width - intendedWidth));
		placement.Top = Clamp(placement.Top.Value, 0.0f,
			Max(0.0f, Parent.Bounds.Height - intendedHeight));
		SetLayout(placement);
	}

	private float MaxWidthInParent() => (Parent == null) ? Max(MinWidth, mUserWidth)
		: Max(MinWidth, Parent.Bounds.Width - Bounds.X);

	private float MaxHeightInParent() => (Parent == null) ? Max(MinHeight, mUserHeight)
		: Max(MinHeight, Parent.Bounds.Height - Bounds.Y);
}
