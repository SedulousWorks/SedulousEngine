namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Tooltip container with themed background. Content is any View — defaults
/// to a Label for simple text tooltips, but custom views can be set.
public class TooltipView : ViewGroup
{
	private View mContent; // owned by mChildren via AddView — no ~ delete

	public this()
	{
		Padding = .(8, 4);
	}

	/// Set a simple text tooltip.
	public void SetText(StringView text)
	{
		if (let label = mContent as Label)
		{
			label.SetText(text);
		}
		else
		{
			if (mContent != null)
			{
				RemoveView(mContent, true);
				mContent = null;
			}
			let label = new Label();
			label.SetText(text);
			label.FontSize = 13;
			mContent = label;
			AddView(label, new LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
		}
	}

	/// Set a custom view as tooltip content.
	public void SetContent(View content)
	{
		if (mContent != null)
			RemoveView(mContent, true);
		mContent = content;
		if (content != null)
			AddView(content, new LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float contentW = 0, contentH = 0;
		if (mContent != null)
		{
			mContent.Measure(.AtMost(wSpec.Size - Padding.TotalHorizontal), .AtMost(hSpec.Size - Padding.TotalVertical));
			contentW = mContent.MeasuredSize.X;
			contentH = mContent.MeasuredSize.Y;
		}
		MeasuredSize = .(wSpec.Resolve(contentW + Padding.TotalHorizontal),
						 hSpec.Resolve(contentH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (mContent != null)
			mContent.Layout(Padding.Left, Padding.Top,
				(right - left) - Padding.TotalHorizontal,
				(bottom - top) - Padding.TotalVertical);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		if (!ctx.TryDrawDrawable("Tooltip.Background", bounds, GetControlState()))
		{
			let bgColor = ctx.Theme?.GetColor("Tooltip.Background", .(40, 42, 50, 230)) ?? .(40, 42, 50, 230);
			let borderColor = ctx.Theme?.GetColor("Tooltip.Border", .(70, 75, 85, 255)) ?? .(70, 75, 85, 255);

			ctx.VG.FillRoundedRect(bounds, 4, bgColor);
			ctx.VG.StrokeRoundedRect(bounds, 4, borderColor, 1);
		}

		DrawChildren(ctx);
	}
}
