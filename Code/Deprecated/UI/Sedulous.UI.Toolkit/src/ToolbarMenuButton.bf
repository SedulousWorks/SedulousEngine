using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A toolbar button that opens a popup, drawn with a caret after its text.
///
/// It carries a checked state like a toggle, meaning "the mode this dropdown holds is
/// active", but clicking it raises OnClick rather than flipping that state: the caller shows
/// a ContextMenu under it and sets IsChecked from whatever the menu did.
class ToolbarMenuButton : ToolbarButton
{
	/// The strip reserved at the right for the caret.
	public const float CaretWidth = 12.0f;

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

		base.OnDraw(ctx);

		// A small down pointing triangle in the reserved strip.
		let caretColor = ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235));
		let cx = Width - (CaretWidth * 0.5f) - 2.0f;
		let cy = Height * 0.5f;
		Float2[3] points = .(.(cx - 4.0f, cy - 2.0f), .(cx + 4.0f, cy - 2.0f), .(cx, cy + 3.0f));
		ctx.VG.FillPolygon(.(&points[0], points.Count), caretColor);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		base.OnMeasure(constraints);
		MeasuredSize.X = constraints.ConstrainWidth(MeasuredSize.X + CaretWidth);
	}
}
