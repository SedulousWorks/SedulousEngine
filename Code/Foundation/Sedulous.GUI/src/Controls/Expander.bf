namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Collapsible container with a clickable header and expandable body content.
public class Expander : ViewGroup
{
	private String mHeaderText ~ delete _;
	private View mContent;
	private bool mIsExpanded = true;

	/// Header height in pixels.
	public Property<float> HeaderHeight = new .(28) ~ delete _;

	/// Spacing between header and content.
	public Property<float> ContentSpacing = new .(4) ~ delete _;

	/// Whether the content is expanded (visible).
	public bool IsExpanded
	{
		get => mIsExpanded;
		set
		{
			if (mIsExpanded == value) return;
			mIsExpanded = value;
			if (mContent != null)
				mContent.Visibility = mIsExpanded ? .Visible : .Gone;
			Invalidate();
			OnExpandedChanged(this, mIsExpanded);
		}
	}

	public Event<delegate void(Expander, bool)> OnExpandedChanged ~ _.Dispose();

	public this() { IsFocusable = true; Cursor = .Hand; HeaderHeight.SetOwner(this); ContentSpacing.SetOwner(this); }
	public this(StringView headerText) : this() { mHeaderText = new String(headerText); }

	/// Set the expandable body content.
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

	/// Toggle expansion.
	public void Toggle() { IsExpanded = !mIsExpanded; }

	/// Expand the content.
	public void Expand() { IsExpanded = true; }

	/// Collapse the content.
	public void Collapse() { IsExpanded = false; }

	/// Set the header text.
	public void SetHeaderText(StringView text)
	{
		if (mHeaderText == null) mHeaderText = new String(text);
		else mHeaderText.Set(text);
		Invalidate();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float contentH = 0;
		if (mContent != null && mContent.Visibility != .Gone)
		{
			let inner = constraints.Deflate(Padding).Loosen();
			let margin = mContent.LayoutParams?.Margin ?? Thickness();
			mContent.Measure(inner.Deflate(margin));
			contentH = ContentSpacing.Value + mContent.MeasuredSize.Y + margin.TotalVertical;
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(HeaderHeight.Value + contentH));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mContent != null && mContent.Visibility != .Gone)
		{
			let margin = mContent.LayoutParams?.Margin ?? Thickness();
			let contentTop = HeaderHeight.Value + ContentSpacing.Value;
			mContent.Layout(
				margin.Left,
				contentTop + margin.Top,
				Math.Max(0, width - margin.TotalHorizontal),
				Math.Max(0, height - contentTop - margin.TotalVertical));
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 16);
		let headerRect = RectangleF(0, 0, Width, HeaderHeight.Value);

		// Header background via pseudo-element with hover state
		var headerState = GetControlState();
		let headerDrawable = ResolvePartDrawable("header", .Background, headerState);
		if (headerDrawable != null)
			headerDrawable.Draw(ctx, headerRect, headerState);
		else
			ctx.VG.FillRect(headerRect, .(50, 55, 68, 255)); // fallback

		// Chevron indicator via pseudo-element (expanded=Checked state)
		let arrowSize = 8.0f;
		let arrowX = 8.0f;
		let arrowCY = HeaderHeight.Value * 0.5f;
		var chevronState = headerState;
		if (mIsExpanded) chevronState |= .Checked;
		let chevronIcon = ResolvePartDrawable("chevron", .Background, chevronState);
		let arrowColor = ResolvePartColor("chevron", .TextColor, chevronState, .(180, 185, 200, 255));

		if (chevronIcon != null)
		{
			let iconRect = RectangleF(arrowX, arrowCY - arrowSize * 0.5f, arrowSize, arrowSize);
			chevronIcon.Draw(ctx, iconRect);
		}
		else
		{
			// VG fallback
			ctx.VG.BeginPath();
			if (mIsExpanded)
			{
				ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.25f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.5f, arrowCY + arrowSize * 0.25f);
				ctx.VG.LineTo(arrowX + arrowSize, arrowCY - arrowSize * 0.25f);
			}
			else
			{
				ctx.VG.MoveTo(arrowX + arrowSize * 0.25f, arrowCY - arrowSize * 0.5f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.75f, arrowCY);
				ctx.VG.LineTo(arrowX + arrowSize * 0.25f, arrowCY + arrowSize * 0.5f);
			}
			ctx.VG.Stroke(arrowColor, 2);
		}

		// Header text
		if (mHeaderText != null && !mHeaderText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(fontSize);
			if (font != null)
			{
				let textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				let textX = arrowX + arrowSize + 8;
				ctx.VG.DrawText(mHeaderText, font, .(textX, 0, Width - textX - 4, HeaderHeight.Value), .Left, .Middle, textColor);
			}
		}

		// Draw children (content below header)
		DrawChildren(ctx);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Handled || e.Button != .Left) return;

		// Get mouse position in our local space via InputManager screen coords.
		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));

		if (local.Y >= 0 && local.Y <= HeaderHeight.Value)
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
		case .Space, .Return: Toggle(); e.Handled = true;
		case .Right: if (!mIsExpanded) { IsExpanded = true; e.Handled = true; }
		case .Left: if (mIsExpanded) { IsExpanded = false; e.Handled = true; }
		default:
		}
	}

	public override void OnActivate()
	{
		Toggle();
	}
}
