namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Tooltip container with themed background. Content is any View - defaults
/// to a simple text label, but custom views can be set.
public class TooltipView : ViewGroup
{
	private View mContent;

	public this()
	{
		Padding = .(8, 4);
		StyleId = new String("tooltip");
	}

	/// Set custom view as tooltip content.
	public void SetContent(View content)
	{
		if (mContent != null)
			RemoveView(mContent, true);
		mContent = content;
		if (content != null)
			AddView(content);
	}

	/// Clear content (called before reuse).
	public void ClearContent()
	{
		if (mContent != null)
		{
			RemoveView(mContent, true);
			mContent = null;
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let inner = constraints.Deflate(Padding);
		float contentW = 0, contentH = 0;
		if (mContent != null)
		{
			mContent.Measure(inner);
			contentW = mContent.MeasuredSize.X;
			contentH = mContent.MeasuredSize.Y;
		}
		MeasuredSize = .(
			constraints.ConstrainWidth(contentW + Padding.TotalHorizontal),
			constraints.ConstrainHeight(contentH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent != null)
			mContent.Layout(Padding.Left, Padding.Top,
				width - Padding.TotalHorizontal,
				height - Padding.TotalVertical);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);

		// Background from theme.
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
			bg.Draw(ctx, bounds);
		else
		{
			ctx.VG.FillRoundedRect(bounds, 4, .(40, 42, 50, 230));
			ctx.VG.StrokeRoundedRect(bounds, 4, .(70, 75, 85, 255), 1);
		}

		// Draw content.
		base.OnDraw(ctx);
	}
}
