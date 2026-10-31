using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A toolbar button that stays down: on and off, with the toolbar's selection colour behind it
/// while it is on.
class ToolbarToggle : ToolbarButton
{
	public Event<delegate void(ToolbarToggle, bool)> OnCheckedChanged ~ _.Dispose();

	private bool mIsChecked = false;

	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked == value)
				return;

			mIsChecked = value;
			Invalidate();
			OnCheckedChanged(this, value);
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIsChecked)
		{
			let bounds = Rectangle(0, 0, Width, Height);
			let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);

			var onColor = Color.Rgb(40, 80, 160);
			if (let toolbar = Parent as Toolbar)
				onColor = toolbar.ResolveStyleColor(.SelectionColor, onColor);

			if (cornerRadius > 0.0f)
				ctx.VG.FillRoundedRect(bounds, cornerRadius, onColor);
			else
				ctx.VG.FillRect(bounds, onColor);
		}

		// The base draws the hover fill over this, so an active toggle still responds to the
		// pointer instead of looking frozen.
		base.OnDraw(ctx);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		IsChecked = !mIsChecked;
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if ((e.Key == .Space) || (e.Key == .Return))
		{
			IsChecked = !mIsChecked;
			e.Handled = true;
		}
	}
}
