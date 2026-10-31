using Sedulous.Core;

namespace Sedulous.UI;

/// The tooltip's frame: a themed background around one piece of content.
///
/// Reused rather than rebuilt, since a tooltip appears and disappears constantly and the
/// manager keeps exactly one.
class TooltipView : ViewGroup
{
	/// BORROWED: held as a child, so the group's own reference is the owning one.
	private View mContent = null;

	public this()
	{
		Padding = .(8, 4);
	}

	/// Replaces the content. CONSUMES the caller's reference.
	public void SetContent(View content)
	{
		ClearContent();

		mContent = content;
		if (content != null)
			AddView(content);
	}

	/// Drops the content, which is what happens before the view is shown again for something
	/// else.
	public void ClearContent()
	{
		if (mContent == null)
			return;

		RemoveView(mContent);
		mContent = null;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
		{
			background.Draw(ctx, bounds);
		}
		else
		{
			// A built in look, so a tooltip is legible before any theme is loaded.
			ctx.VG.FillRoundedRect(bounds, 4.0f,
				Color(40 / 255.0f, 42 / 255.0f, 50 / 255.0f, 230 / 255.0f));
			ctx.VG.StrokeRoundedRect(bounds, 4.0f,
				Color(70 / 255.0f, 75 / 255.0f, 85 / 255.0f, 1.0f), 1.0f);
		}

		base.OnDraw(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let inner = constraints.Deflate(Padding);
		var contentWidth = 0.0f;
		var contentHeight = 0.0f;

		if (mContent != null)
		{
			mContent.Measure(inner);
			contentWidth = mContent.MeasuredSize.X;
			contentHeight = mContent.MeasuredSize.Y;
		}

		MeasuredSize = .(constraints.ConstrainWidth(contentWidth + Padding.TotalHorizontal),
			constraints.ConstrainHeight(contentHeight + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent == null)
			return;

		mContent.Layout(Padding.Left, Padding.Top, width - Padding.TotalHorizontal,
			height - Padding.TotalVertical);
	}
}
