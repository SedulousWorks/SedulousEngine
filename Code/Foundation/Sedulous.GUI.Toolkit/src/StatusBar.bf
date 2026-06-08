namespace Sedulous.GUI.Toolkit;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Bottom status strip with text sections.
public class StatusBar : FlexLayout
{
	private Label mDefaultLabel;

	public this()
	{
		Direction = .Horizontal;
		Spacing = 12;
		Padding = .(4);
	}

	/// Set the default status text (creates label on first call).
	public void SetText(StringView text)
	{
		if (mDefaultLabel == null)
		{
			mDefaultLabel = new Label();
			mDefaultLabel.FontSize.Value = 12;
			InsertView(mDefaultLabel, 0, new FlexLayout.LayoutParams() {
				Width = .Match,
				Height = .Match,
				Grow = 1
			});
		}
		mDefaultLabel.SetText(text);
	}

	/// Add a named section label. Returns the Label for customization.
	public Label AddSection(StringView text)
	{
		let label = new Label();
		label.FontSize.Value = 12;
		label.SetText(text);
		AddView(label, new FlexLayout.LayoutParams() { Height = .Match });
		return label;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Background.
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, .(0, 0, Width, Height));
		else
			ctx.VG.FillRect(.(0, 0, Width, Height), .(30, 32, 40, 255));

		// Top border.
		let borderColor = ResolveStyleColor(.BorderColor, .(65, 70, 85, 255));
		ctx.VG.FillRect(.(0, 0, Width, 1), borderColor);

		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		base.OnMeasure(constraints);
		// Ensure minimum height of 24px.
		if (MeasuredSize.Y < 24)
			MeasuredSize = .(MeasuredSize.X, 24);
	}
}
