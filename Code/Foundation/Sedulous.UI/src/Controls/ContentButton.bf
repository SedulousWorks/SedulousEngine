namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Button with arbitrary View content - for icons, icon+text combos,
/// or any custom content layout.
public class ContentButton : ButtonBase
{
	/// The content view (owned by this button).
	private View mContent ~ delete _;

	public View Content
	{
		get => mContent;
		set
		{
			if (mContent != null)
				delete mContent;
			mContent = value;
			Invalidate();
		}
	}

	/// Content button with a view.
	public this(View content) : base()
	{
		mContent = content;
	}

	/// Empty content button - set Content manually.
	public this() : base() { }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = ResolveStyleThickness(.Padding, .(12, 8));
		let inner = constraints.Deflate(pad).Loosen();

		float contentW = 0, contentH = 0;
		if (mContent != null)
		{
			// Pass font context down to content for measurement
			if (mContent.Context == null && Context != null)
				Context.AttachView(mContent);
			mContent.Measure(inner);
			contentW = mContent.MeasuredSize.X;
			contentH = mContent.MeasuredSize.Y;
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(contentW + pad.TotalHorizontal),
			constraints.ConstrainHeight(contentH + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent == null) return;

		let pad = ResolveStyleThickness(.Padding, .(12, 8));
		let contentW = width - pad.TotalHorizontal;
		let contentH = height - pad.TotalVertical;

		// Center content within padding
		let cw = mContent.MeasuredSize.X;
		let ch = mContent.MeasuredSize.Y;
		let cx = pad.Left + (contentW - cw) * 0.5f;
		let cy = pad.Top + (contentH - ch) * 0.5f;
		mContent.Layout(cx, cy, cw, ch);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();

		DrawButtonBackground(ctx, bounds, state);

		// Draw content
		if (mContent != null)
		{
			ctx.VG.PushState();
			ctx.VG.Translate(mContent.Bounds.X, mContent.Bounds.Y);
			mContent.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}
}
