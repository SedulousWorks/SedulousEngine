namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Collapsible content panel with a clickable header.
/// Click the header or press Space/Return to toggle expansion.
public class Expander : ViewGroup
{
	private String mHeaderText ~ delete _;
	private View mContent; // not owned separately - in mChildren via AddView
	private bool mIsExpanded = true;

	private Color? mHeaderColor;
	private float? mFontSize;

	public float HeaderHeight = 28;

	public Event<delegate void(Expander, bool)> OnExpandedChanged ~ _.Dispose();

	public bool IsExpanded
	{
		get => mIsExpanded;
		set
		{
			if (mIsExpanded != value)
			{
				mIsExpanded = value;
				if (mContent != null)
					mContent.Visibility = value ? .Visible : .Gone;
				InvalidateLayout();
				OnExpandedChanged(this, value);
			}
		}
	}

	public Color HeaderColor
	{
		get => mHeaderColor ?? Context?.Theme?.GetColor("Expander.Header") ?? .(60, 65, 80, 255);
		set => mHeaderColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("Expander.FontSize", 14) ?? 14;
		set { mFontSize = value; InvalidateLayout(); }
	}

	public this()
	{
		IsFocusable = true;
		Cursor = .Hand;
	}

	public void SetHeaderText(StringView text)
	{
		if (mHeaderText == null) mHeaderText = new String(text);
		else mHeaderText.Set(text);
		InvalidateLayout();
	}

	/// Set the expandable content view. Replaces any existing content.
	public void SetContent(View content, LayoutParams lp = null)
	{
		if (mContent != null)
			RemoveView(mContent, true);

		mContent = content;
		if (content != null)
		{
			content.Visibility = mIsExpanded ? .Visible : .Gone;
			AddView(content, lp);
		}
	}

	public void Toggle() { IsExpanded = !mIsExpanded; }
	public void Expand() { IsExpanded = true; }
	public void Collapse() { IsExpanded = false; }

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float contentH = 0;
		if (mContent != null && mContent.Visibility != .Gone)
		{
			let contentWSpec = MakeChildMeasureSpec(wSpec, 0, mContent.LayoutParams?.Width ?? Sedulous.UI.LayoutParams.MatchParent);
			let contentHSpec = MeasureSpec.Unspecified();
			mContent.Measure(contentWSpec, contentHSpec);
			contentH = mContent.MeasuredSize.Y;
		}

		MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(HeaderHeight + contentH));
	}

	// === Layout ===

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let w = right - left;

		if (mContent != null && mContent.Visibility != .Gone)
		{
			let margin = mContent.LayoutParams?.Margin ?? Thickness();
			mContent.Layout(margin.Left, HeaderHeight + margin.Top,
				w - margin.TotalHorizontal,
				mContent.MeasuredSize.Y);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;

		// Header background.
		let headerBounds = RectangleF(0, 0, w, HeaderHeight);
		if (!ctx.TryDrawDrawable("Expander.Header", headerBounds, GetControlState()))
		{
			var headerBg = HeaderColor;
			if (IsHovered) headerBg = Palette.ComputeHover(headerBg);
			ctx.VG.FillRect(headerBounds, headerBg);
		}

		// Expand/collapse arrow - separate keys for expanded vs collapsed.
		let arrowSize = 8.0f;
		let arrowX = 10.0f;
		let arrowCY = HeaderHeight * 0.5f;
		let arrowKey = mIsExpanded ? "Expander.ArrowExpanded" : "Expander.ArrowCollapsed";
		let arrowRect = RectangleF(arrowX - 2, arrowCY - arrowSize * 0.5f, arrowSize + 4, arrowSize);

		if (!ctx.TryDrawDrawable(arrowKey, arrowRect, .Normal))
		{
			let arrowColor = ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
			ctx.VG.BeginPath();
			if (mIsExpanded)
			{
				ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.3f);
				ctx.VG.LineTo(arrowX + arrowSize, arrowCY - arrowSize * 0.3f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.5f, arrowCY + arrowSize * 0.4f);
			}
			else
			{
				ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.4f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.6f, arrowCY);
				ctx.VG.LineTo(arrowX, arrowCY + arrowSize * 0.4f);
			}
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}

		// Header text.
		if (mHeaderText != null && mHeaderText.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let textColor = ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
				ctx.VG.DrawText(mHeaderText, font,
					.(arrowX + arrowSize + 8, 0, w - arrowX - arrowSize - 16, HeaderHeight),
					.Left, .Middle, textColor);
			}
		}

		// Focus ring on header.
		if (IsFocused)
			ctx.DrawFocusRing(.(0, 0, w, HeaderHeight));

		// Draw content children.
		DrawChildren(ctx);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		// Only toggle if clicking the header area.
		if (e.Y <= HeaderHeight)
		{
			Toggle();
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		switch (e.Key)
		{
		case .Space, .Return:
			Toggle();
			e.Handled = true;
		case .Right:
			if (!mIsExpanded) { Expand(); e.Handled = true; }
		case .Left:
			if (mIsExpanded) { Collapse(); e.Handled = true; }
		default:
		}
	}
}
