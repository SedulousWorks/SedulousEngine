using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The strip along the bottom of an editor window: a stretching default message on the left and
/// fixed sections after it.
///
/// The default label is created on FIRST use rather than in the constructor, so a status bar
/// that only ever carries sections does not reserve a stretching empty slot ahead of them.
class StatusBar : FlexLayout
{
	/// BORROWED: the child list owns the label.
	private Label mDefaultLabel = null;

	public this()
	{
		Direction = .Horizontal;
		Spacing = 12.0f;
		Padding = .(4.0f);
	}

	/// The default status text. Its label is inserted FIRST so it stays leftmost however many
	/// sections were added before the first call.
	public void SetText(StringView text)
	{
		if (mDefaultLabel == null)
		{
			mDefaultLabel = new Label();
			mDefaultLabel.FontSize.Value = 12.0f;

			LayoutStyle style = .();
			style.Width = SizeSpec.Match();
			style.Height = SizeSpec.Match();
			style.FlexGrow = 1.0f;
			InsertView(mDefaultLabel, 0, style);
		}

		mDefaultLabel.SetText(text);
	}

	/// Adds a section at the right. The label comes back BORROWED, for a caller that wants to
	/// restyle it; the bar owns it.
	public Label AddSection(StringView text)
	{
		let label = new Label();
		label.FontSize.Value = 12.0f;
		label.SetText(text);

		LayoutStyle style = .();
		style.Height = SizeSpec.Match();
		AddView(label, style);
		return label;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color.Rgb(30, 32, 40));

		// The top border, which is what separates the bar from the content above it.
		let borderColor = ResolveStyleColor(.BorderColor, Color.Rgb(65, 70, 85));
		ctx.VG.FillRect(Rectangle(0, 0, Width, 1.0f), borderColor);

		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		base.OnMeasure(constraints);

		// A floor, so an empty bar is still a bar rather than a hairline.
		if (MeasuredSize.Y < 24.0f)
			MeasuredSize = .(MeasuredSize.X, 24.0f);
	}
}
