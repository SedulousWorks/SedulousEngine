namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Bottom status strip with text sections.
public class StatusBar : LinearLayout
{
	private Label mDefaultLabel;

	public this()
	{
		Orientation = .Horizontal;
		Spacing = 12;
		Padding = .(4);
	}

	/// Set the default status text (creates label on first call).
	public void SetText(StringView text)
	{
		if (mDefaultLabel == null)
		{
			mDefaultLabel = new Label();
			mDefaultLabel.FontSize = 12;
			InsertView(mDefaultLabel, 0, new LinearLayout.LayoutParams() {
				Width = Sedulous.UI.LayoutParams.MatchParent,
				Height = Sedulous.UI.LayoutParams.MatchParent,
				Weight = 1
			});
		}
		mDefaultLabel.SetText(text);
	}

	/// Add a named section label. Returns the Label for customization.
	public Label AddSection(StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.FontSize = 12;
		AddView(label, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
		return label;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Background.
		if (!ctx.TryDrawDrawable("StatusBar.Background", .(0, 0, Width, Height), .Normal))
		{
			let bgColor = ctx.Theme?.GetColor("StatusBar.Background", .(30, 32, 40, 255)) ?? .(30, 32, 40, 255);
			ctx.VG.FillRect(.(0, 0, Width, Height), bgColor);
		}

		// Top border.
		let borderColor = ctx.Theme?.GetColor("StatusBar.Border", .(65, 70, 85, 255)) ?? .(65, 70, 85, 255);
		ctx.VG.FillRect(.(0, 0, Width, 1), borderColor);

		DrawChildren(ctx);
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		base.OnMeasure(wSpec, hSpec);
		// Ensure minimum height.
		if (MeasuredSize.Y < 24)
			MeasuredSize = .(MeasuredSize.X, hSpec.Resolve(24));
	}
}
