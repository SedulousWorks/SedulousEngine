using Sedulous.Core;

namespace Sedulous.UI;

/// A button whose face is an arbitrary view: an icon, an icon beside text, any custom layout.
///
/// The content is NOT a child. That is deliberate and it is behaviour, not an implementation
/// detail: the button is the whole click target, so nothing inside it is hit tested or focused
/// separately. It is measured, laid out and drawn by hand instead.
///
/// It is OWNED. SetContent consumes the caller's reference and releases the one held before.
class ContentButton : ButtonBase
{
	private View mContent = null;

	public this() {}

	public this(View content)
	{
		mContent = content;
	}

	public ~this()
	{
		ReleaseContent();
	}

	/// Borrowed; may be null.
	public View Content => mContent;

	/// CONSUMES the caller's reference, and releases the one held before.
	public void SetContent(View content)
	{
		if (mContent == content)
		{
			content?.ReleaseRef();
			return;
		}

		ReleaseContent();
		mContent = content;
		Invalidate();
	}

	/// The content is attached to the context by hand, so it has to be detached by hand: a
	/// view released while still registered leaves the context holding a dangling pointer.
	private void ReleaseContent()
	{
		if (mContent == null)
			return;

		if (mContent.Context != null)
			mContent.Context.DetachView(mContent);
		mContent.ReleaseRef();
		mContent = null;
	}

	protected override Thickness DefaultStylePadding() => .(12, 8);

	/// CONTENT only: the base handles the chrome.
	protected override Float2 OnMeasureContent(BoxConstraints contentConstraints)
	{
		if (mContent == null)
			return .Zero;

		// Attached here rather than on assignment, because a button is commonly built before
		// it is added to a tree and the content needs the context to resolve fonts.
		if ((mContent.Context == null) && (Context != null))
			Context.AttachView(mContent);

		mContent.Measure(contentConstraints.Loosen());
		return mContent.MeasuredSize;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent == null)
			return;

		let chrome = ResolveBoxMetrics().Chrome;
		let contentWidth = width - chrome.TotalHorizontal;
		let contentHeight = height - chrome.TotalVertical;
		let size = mContent.MeasuredSize;

		// Centred in the content box at its MEASURED size, so content smaller than the button
		// sits in the middle instead of being stretched.
		mContent.Layout(chrome.Left + (contentWidth - size.X) * 0.5f,
			chrome.Top + (contentHeight - size.Y) * 0.5f, size.X, size.Y);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		DrawButtonBackground(ctx, bounds, GetControlState());

		if (mContent == null)
			return;

		// Drawn by hand, since the content is not a child and DrawChildren will not find it.
		ctx.VG.PushState();
		ctx.VG.Translate(mContent.Bounds.X, mContent.Bounds.Y);
		mContent.OnDraw(ctx);
		ctx.VG.PopState();
	}
}
